// ============================================================
// web_recovery_js_test.js — اختبار window.__azalHardReload
// ============================================================
//
// الدالة تعيش في web/index.html وتُنفَّذ من Dart عند فشل تهيئة Firebase
// (زر «مسح الكاش وإعادة التحميل» أو المحاولة التلقائية).
//
// نختبرها هنا بلا متصفح: نستخرج السكربت المضمّن ونشغّله في سياق vm
// مع نوافذ وهمية (sessionStorage / caches / serviceWorker / location).
//
// التشغيل:
//   node --test test/web_recovery_js_test.js
// ============================================================

const assert = require("node:assert");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");
const { test } = require("node:test");

const html = fs.readFileSync(
  path.join(__dirname, "..", "web", "index.html"),
  "utf8"
);

function recoveryScript() {
  const scripts = [...html.matchAll(/<script(?![^>]*\bsrc=)[^>]*>([\s\S]*?)<\/script>/g)];

  const found = scripts
    .map((match) => match[1])
    .find((code) => code.includes("__azalHardReload"));

  assert.ok(found, "web/index.html must define window.__azalHardReload");

  return found;
}

/// يشغّل السكربت في سياق متحكم به ويعيد عناصر التحكم.
function run() {
  const state = {
    storage: new Map(),
    cacheKeys: ["flutter-app-cache", "other"],
    deletedCaches: [],
    unregistered: 0,
    reloads: 0,
  };

  const sessionStorage = {
    getItem: (key) => (state.storage.has(key) ? state.storage.get(key) : null),
    setItem: (key, value) => state.storage.set(key, String(value)),
    removeItem: (key) => state.storage.delete(key),
  };

  const context = {
    console: { warn() {}, log() {}, debug() {} },
    setTimeout: (fn) => {
      fn();
    },
    Promise,
    sessionStorage,
    caches: {
      keys: async () => state.cacheKeys,
      delete: async (key) => {
        state.deletedCaches.push(key);
        return true;
      },
    },
    navigator: {
      serviceWorker: {
        getRegistrations: async () => [
          { unregister: async () => { state.unregistered += 1; return true; } },
        ],
      },
    },
    location: { reload: () => { state.reloads += 1; } },
  };

  context.window = context;

  vm.createContext(context);
  vm.runInContext(recoveryScript(), context, {
    filename: "web/index.html<hard-reload>",
  });

  return { context, state };
}

test("first call clears caches, unregisters the worker and reloads", async () => {
  const { context, state } = run();

  assert.strictEqual(context.__azalHardReload(), true);

  // العمل جارٍ داخل async IIFE — ننتظر دورة مهام واحدة.
  await new Promise((resolve) => setImmediate(resolve));

  assert.deepStrictEqual(state.deletedCaches, ["flutter-app-cache", "other"]);
  assert.strictEqual(state.unregistered, 1);
  assert.strictEqual(state.reloads, 1);
  assert.strictEqual(state.storage.get("azal.hardReload"), "1");
});

test("second call is refused so the page cannot reload in a loop", async () => {
  const { context, state } = run();

  assert.strictEqual(context.__azalHardReload(), true);

  await new Promise((resolve) => setImmediate(resolve));

  assert.strictEqual(context.__azalHardReload(), false);
  assert.strictEqual(state.reloads, 1);
});

test("reloading the page resets the guard once the app draws a frame", async () => {
  const { context, state } = run();

  context.__azalHardReload();

  await new Promise((resolve) => setImmediate(resolve));

  // ما يفعله web/index.html عند اول إطار مرسوم.
  context.sessionStorage.removeItem("azal.hardReload");

  assert.strictEqual(context.__azalHardReload(), true);

  await new Promise((resolve) => setImmediate(resolve));

  assert.strictEqual(state.reloads, 2);
});

test("blocked storage still allows a single attempt", async () => {
  const { context, state } = run();

  context.sessionStorage.getItem = () => {
    throw new Error("storage disabled");
  };
  context.sessionStorage.setItem = () => {
    throw new Error("storage disabled");
  };

  assert.strictEqual(context.__azalHardReload(), true);

  await new Promise((resolve) => setImmediate(resolve));

  assert.strictEqual(state.reloads, 1);
});

test("the guard flag is cleared on the first Flutter frame", () => {
  assert.match(
    html,
    /sessionStorage\.removeItem\("azal\.hardReload"\)/,
    "hideGuard must clear the guard flag when the app renders"
  );
});
