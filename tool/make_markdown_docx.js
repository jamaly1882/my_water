#!/usr/bin/env node
/* ============================================================
   make_markdown_docx.js
   ============================================================

   يحوّل ملف Markdown إلى مستند Word (.docx).

   التشغيل مرة واحدة لتثبيت المكتبة:
     npm install docx

   ثم:
     node tool/make_markdown_docx.js docs/project_summary_en.md docs/project_summary_en.docx
     node tool/make_markdown_docx.js docs/project_summary_ar.md docs/project_summary_ar.docx --rtl

   يدعم ما تستخدمه مستندات المشروع فعلًا:
     عناوين # ## ###  ·  جداول  ·  قوائم نقطية ورقمية
     كتل شيفرة  ·  اقتباس  ·  خط فاصل  ·  نص عريض ومائل ورمز

   ============================================================ */

'use strict';

const fs = require('fs');
const path = require('path');

const {
  AlignmentType,
  BorderStyle,
  Document,
  HeadingLevel,
  LevelFormat,
  Packer,
  Paragraph,
  ShadingType,
  Table,
  TableCell,
  TableRow,
  TextRun,
  WidthType,
} = require('docx');

const args = process.argv.slice(2);

const input = args[0];
const output = args[1];
const rtl = args.includes('--rtl');

if (!input || !output) {
  console.error(
    'الاستخدام: node tool/make_markdown_docx.js <input.md> <output.docx> [--rtl]'
  );
  process.exit(1);
}

const source = fs.readFileSync(input, 'utf8').replace(/\r\n/g, '\n');
const lines = source.split('\n');

/* ============================================================
   أدوات نصية
   ============================================================ */

const FONT = rtl ? 'Arial' : 'Calibri';

function run(text, extra = {}) {
  return new TextRun({
    text,
    font: FONT,
    rightToLeft: rtl ? true : undefined,
    ...extra,
  });
}

/**
 * يحوّل سطرًا فيه **عريض** و*مائل* و`رمز` إلى مصفوفة TextRun.
 */
function inline(text, base = {}) {
  const out = [];
  const pattern = /(\*\*[^*]+\*\*|\*[^*]+\*|`[^`]+`)/g;

  let last = 0;
  let match;

  while ((match = pattern.exec(text)) !== null) {
    if (match.index > last) {
      out.push(run(text.slice(last, match.index), base));
    }

    const token = match[0];

    if (token.startsWith('**')) {
      out.push(run(token.slice(2, -2), { ...base, bold: true }));
    } else if (token.startsWith('`')) {
      out.push(
        run(token.slice(1, -1), {
          ...base,
          font: 'Consolas',
          shading: {
            type: ShadingType.CLEAR,
            fill: 'F1F3F5',
            color: 'auto',
          },
        })
      );
    } else {
      out.push(run(token.slice(1, -1), { ...base, italics: true }));
    }

    last = match.index + token.length;
  }

  if (last < text.length) {
    out.push(run(text.slice(last), base));
  }

  return out.length ? out : [run('', base)];
}

function para(children, options = {}) {
  return new Paragraph({
    children,
    alignment: rtl ? AlignmentType.RIGHT : AlignmentType.LEFT,
    bidirectional: rtl ? true : undefined,
    ...options,
  });
}

function heading(text, level) {
  const map = {
    1: HeadingLevel.HEADING_1,
    2: HeadingLevel.HEADING_2,
    3: HeadingLevel.HEADING_3,
  };

  return new Paragraph({
    children: inline(text),
    heading: map[level] || HeadingLevel.HEADING_3,
    alignment: rtl ? AlignmentType.RIGHT : AlignmentType.LEFT,
    bidirectional: rtl ? true : undefined,
    spacing: { before: 260, after: 120 },
  });
}

function codeBlock(text) {
  return new Paragraph({
    children: [
      new TextRun({
        text,
        font: 'Consolas',
        size: 18,
        rightToLeft: undefined,
        color: '1F2933',
      }),
    ],
    alignment: AlignmentType.LEFT,
    bidirectional: false,
    shading: { type: ShadingType.CLEAR, fill: 'F5F7FA', color: 'auto' },
    border: {
      top: { style: BorderStyle.SINGLE, size: 2, color: 'DDE3EA' },
      bottom: { style: BorderStyle.SINGLE, size: 2, color: 'DDE3EA' },
      left: { style: BorderStyle.SINGLE, size: 2, color: 'DDE3EA' },
      right: { style: BorderStyle.SINGLE, size: 2, color: 'DDE3EA' },
    },
    spacing: { before: 100, after: 160 },
    indent: { left: 120, right: 120 },
  });
}

/* ============================================================
   الجداول
   ============================================================ */

function buildTable(rows) {
  const header = rows[0];
  const body = rows.slice(1);

  const columns = header.length;
  const usable = rtl ? 8600 : 9000;
  const width = Math.floor(usable / columns);

  const makeCell = (text, isHeader) =>
    new TableCell({
      width: { size: width, type: WidthType.DXA },
      shading: isHeader
        ? { type: ShadingType.CLEAR, fill: 'E8F0FA', color: 'auto' }
        : undefined,
      margins: { top: 60, bottom: 60, left: 90, right: 90 },
      children: [
        para(inline(text || '', isHeader ? { bold: true } : {}), {
          spacing: { before: 0, after: 0 },
        }),
      ],
    });

  return new Table({
    width: { size: usable, type: WidthType.DXA },
    columnWidths: new Array(columns).fill(width),
    rows: [
      new TableRow({
        tableHeader: true,
        children: header.map((cell) => makeCell(cell, true)),
      }),
      ...body.map(
        (cells) => new TableRow({ children: cells.map((cell) => makeCell(cell, false)) })
      ),
    ],
  });
}

function splitRow(line) {
  return line
    .replace(/^\s*\|/, '')
    .replace(/\|\s*$/, '')
    .split('|')
    .map((cell) => cell.trim());
}

/* ============================================================
   التحويل
   ============================================================ */

const children = [];

let i = 0;

while (i < lines.length) {
  const line = lines[i];
  const trimmed = line.trim();

  if (trimmed === '') {
    i += 1;
    continue;
  }

  /* كتلة شيفرة */
  if (trimmed.startsWith('```')) {
    const buffer = [];
    i += 1;

    while (i < lines.length && !lines[i].trim().startsWith('```')) {
      buffer.push(lines[i]);
      i += 1;
    }

    i += 1;

    children.push(codeBlock(buffer.join('\n')));
    continue;
  }

  /* جدول */
  if (trimmed.startsWith('|') && trimmed.endsWith('|')) {
    const rows = [];

    while (
      i < lines.length &&
      lines[i].trim().startsWith('|') &&
      lines[i].trim().endsWith('|')
    ) {
      const cells = splitRow(lines[i]);

      const isSeparator = cells.every((cell) => /^:?-{2,}:?$/.test(cell));

      if (!isSeparator) rows.push(cells);

      i += 1;
    }

    if (rows.length) {
      children.push(buildTable(rows));
      children.push(para([run('')], { spacing: { before: 0, after: 120 } }));
    }

    continue;
  }

  /* خط فاصل */
  if (/^(-{3,}|\*{3,}|_{3,})$/.test(trimmed)) {
    children.push(
      para([run('')], {
        spacing: { before: 120, after: 120 },
        border: {
          bottom: { style: BorderStyle.SINGLE, size: 6, color: 'D5DEE8' },
        },
      })
    );

    i += 1;
    continue;
  }

  /* عناوين */
  const headingMatch = /^(#{1,3})\s+(.*)$/.exec(trimmed);

  if (headingMatch) {
    children.push(heading(headingMatch[2], headingMatch[1].length));
    i += 1;
    continue;
  }

  /* اقتباس */
  if (trimmed.startsWith('> ')) {
    children.push(
      para(inline(trimmed.slice(2)), {
        indent: { left: rtl ? 0 : 240, right: rtl ? 240 : 0 },
        border: {
          [rtl ? 'right' : 'left']: {
            style: BorderStyle.SINGLE,
            size: 12,
            color: 'B0BEC5',
          },
        },
        spacing: { before: 80, after: 80 },
      })
    );

    i += 1;
    continue;
  }

  /* قائمة نقطية */
  if (/^[-*]\s+/.test(trimmed)) {
    children.push(
      para(inline(trimmed.replace(/^[-*]\s+/, '')), {
        bullet: { level: 0 },
        spacing: { before: 20, after: 20 },
      })
    );

    i += 1;
    continue;
  }

  /* قائمة رقمية */
  const numbered = /^(\d+)\.\s+(.*)$/.exec(trimmed);

  if (numbered) {
    children.push(
      para(inline(numbered[2]), {
        numbering: { reference: 'ordered-list', level: 0 },
        spacing: { before: 20, after: 20 },
      })
    );

    i += 1;
    continue;
  }

  /* فقرة عادية (تُدمج الأسطر المتتابعة) */
  const buffer = [trimmed];
  i += 1;

  while (
    i < lines.length &&
    lines[i].trim() !== '' &&
    !/^(#{1,3}\s|\||```|>|[-*]\s|\d+\.\s)/.test(lines[i].trim()) &&
    !/^(-{3,}|\*{3,}|_{3,})$/.test(lines[i].trim())
  ) {
    buffer.push(lines[i].trim());
    i += 1;
  }

  const text = buffer.join(' ');
  const allItalic = /^\*[^*].*\*$/.test(text);

  children.push(
    para(inline(text), {
      spacing: { before: 60, after: 140 },
      alignment: allItalic
        ? AlignmentType.CENTER
        : rtl
          ? AlignmentType.RIGHT
          : AlignmentType.LEFT,
    })
  );
}

/* ============================================================
   المستند
   ============================================================ */

const doc = new Document({
  styles: {
    default: {
      document: {
        run: { font: FONT, size: 22 },
        paragraph: { spacing: { line: 300 } },
      },
    },
  },
  numbering: {
    config: [
      {
        reference: 'ordered-list',
        levels: [
          {
            level: 0,
            format: LevelFormat.DECIMAL,
            text: '%1.',
            alignment: AlignmentType.START,
          },
        ],
      },
    ],
  },
  sections: [
    {
      properties: {
        page: {
          margin: { top: 1000, bottom: 1000, left: 900, right: 900 },
        },
      },
      children,
    },
  ],
});

Packer.toBuffer(doc).then((buffer) => {
  fs.writeFileSync(output, buffer);

  const kb = Math.round(buffer.length / 1024);

  console.log(`تم: ${output} (${kb} KB، ${children.length} عنصرًا)`);
}).catch((error) => {
  console.error('فشل إنشاء المستند:', error);
  process.exit(1);
});
