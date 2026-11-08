"use strict";

// Unit tests for the browser meter-OCR helpers embedded in web/index.html.
// Run with: node --test test/meter_ocr_web_test.js

const test = require("node:test");
const assert = require("node:assert/strict");
const fs = require("node:fs");
const path = require("node:path");
const vm = require("node:vm");

function loadMeterOcrHelpers() {
  const html = fs.readFileSync(
    path.join(__dirname, "..", "web", "index.html"),
    "utf8"
  );
  const scripts = [...html.matchAll(/<script>([\s\S]*?)<\/script>/g)].map(
    (match) => match[1]
  );
  const script = scripts.find((code) => code.includes("function solveMeterDigits"));
  assert.ok(script, "meter OCR script must exist in web/index.html");

  const sandbox = {
    console,
    Promise,
    Number,
    String,
    Object,
    Array,
    Math,
    RegExp,
    JSON,
    Error,
    Float64Array,
    Int32Array,
    Uint8ClampedArray,
    setTimeout,
    clearTimeout,
    Image: class Image {},
    document: {
      addEventListener() {},
      getElementById() {
        return null;
      },
      createElement() {
        return { getContext: () => null, style: {} };
      },
      querySelectorAll() {
        return [];
      },
      head: { appendChild() {} },
      body: { append() {} },
    },
  };
  sandbox.window = sandbox;
  sandbox.globalThis = sandbox;
  vm.createContext(sandbox);
  vm.runInContext(
    script +
      "\n;globalThis.__meterOcrTestExports = {" +
      "normalizeDigits, digitsOnly, clamp, solveMeterDigits," +
      "chooseBestSolution, selectBestDirectCandidate, _ambiguousCellCount, _chooseCellResult};",
    sandbox,
    { filename: "web/index.html<meter-ocr>" }
  );
  return sandbox.__meterOcrTestExports;
}

const helpers = loadMeterOcrHelpers();

function digitCandidates(reading, confidence = 92) {
  return reading.split("").map((digit, index) => ({
    digit,
    normalizedX: (index + 0.5) / reading.length,
    confidence,
    source: "test",
  }));
}

test("normalizes Arabic and Persian digits", () => {
  assert.equal(helpers.normalizeDigits("٠٦٥٠٠٤٠"), "0650040");
  assert.equal(helpers.normalizeDigits("۰۶۵۰۰۴"), "065004");
  assert.equal(helpers.digitsOnly("0 6-5.0|0_4"), "065004");
});

test("solves a 7 digit meter without dropping the leading zero", () => {
  const result = helpers.solveMeterDigits(
    digitCandidates("0650040"),
    1400,
    7
  );
  assert.equal(result.success, true);
  assert.equal(result.reading, "0650040");
  assert.equal(result.digitCount, 7);
});

test("solves a 6 digit meter without inventing a seventh digit", () => {
  const result = helpers.solveMeterDigits(
    digitCandidates("065004"),
    1400,
    6
  );
  assert.equal(result.success, true);
  assert.equal(result.reading, "065004");
  assert.equal(result.digitCount, 6);
});

test("does not force 6 visible digits into a 7 digit solution", () => {
  const result = helpers.solveMeterDigits(
    digitCandidates("065004"),
    1400,
    7
  );
  assert.equal(result.success, false);
  assert.equal(result.reading, "");
});

test("selects the best direct 6 or 7 digit candidate", () => {
  const best = helpers.selectBestDirectCandidate([
    { digitSequence: "065004", confidence: 95 },
    { digitSequence: "0650040", confidence: 40 },
    { digitSequence: "12345678", confidence: 99 },
  ]);
  assert.equal(best.value, "065004");
});

test("chooses the stronger positional solution", () => {
  const six = helpers.solveMeterDigits(digitCandidates("065004", 95), 1400, 6);
  const seven = helpers.solveMeterDigits(digitCandidates("0650040", 55), 1400, 7);
  const best = helpers.chooseBestSolution([seven, six]);
  assert.equal(best.success, true);
  assert.equal(best.reading, "065004");
});


test("refuses ambiguous six and seven cell counts", () => {
  const best = { n: 7, complete: true, score: 87, mean: 87 };
  assert.equal(helpers._ambiguousCellCount([
    best, { n: 6, complete: true, score: 84, mean: 84 }
  ], best), true);
  assert.equal(helpers._ambiguousCellCount([
    best, { n: 6, complete: true, score: 60, mean: 60 }
  ], best), false);
  assert.equal(helpers._ambiguousCellCount([
    best, { n: 6, complete: false, score: 86, mean: 86 }
  ], best), false);
});


test("uncertain complete cell readings are suggestions, not trusted readings", () => {
  const digits = "9142037".split("").map((digit, i) => ({
    digit, confidence: [66, 90, 71, 54, 43, 53, 63][i]
  }));
  const result = helpers._chooseCellResult([
    { n: 7, cells: digits, mean: 62, score: 62, complete: true }
  ], -2.5);
  assert.equal(result.success, false);
  assert.equal(result.reading, "");
  assert.equal(result.suggestion, "9142037");
  assert.equal(result.digitConfidences.length, 7);
});

test("partial and ambiguous cell results cannot produce suggestions", () => {
  const digits = "9142037".split("").map(digit => ({ digit, confidence: 60 }));
  const partial = helpers._chooseCellResult([
    { n: 7, cells: digits.slice(0, 6), mean: 60, score: 20, complete: false }
  ], 0);
  assert.equal(partial.suggestion || "", "");
  const ambiguous = helpers._chooseCellResult([
    { n: 7, cells: digits, mean: 60, score: 60, complete: true },
    { n: 6, cells: digits.slice(0, 6), mean: 58, score: 58, complete: true }
  ], 0);
  assert.equal(ambiguous.suggestion, "");
});
