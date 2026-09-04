/**
 * Minimal XLSX writer (OOXML SpreadsheetML, no external deps).
 * Produces valid .xlsx for ODK/Kobo XLSForm import (survey, choices, settings sheets).
 */

import { execSync } from 'node:child_process';
import { mkdirSync, mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

export type SheetRow = Record<string, string | number | boolean | undefined>;

function escapeXml(value: string): string {
  return value
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

function colName(index: number): string {
  let n = index;
  let name = '';
  while (n >= 0) {
    name = String.fromCharCode((n % 26) + 65) + name;
    n = Math.floor(n / 26) - 1;
  }
  return name;
}

function sheetXml(headers: string[], rows: SheetRow[]): string {
  const headerCells = headers
    .map((h, i) => `<c r="${colName(i)}1" t="inlineStr"><is><t>${escapeXml(h)}</t></is></c>`)
    .join('');

  const dataRows = rows
    .map((row, rowIdx) => {
      const r = rowIdx + 2;
      const cells = headers
        .map((h, colIdx) => {
          const raw = row[h];
          if (raw === undefined || raw === '') return '';
          const ref = `${colName(colIdx)}${r}`;
          if (typeof raw === 'number') {
            return `<c r="${ref}"><v>${raw}</v></c>`;
          }
          return `<c r="${ref}" t="inlineStr"><is><t>${escapeXml(String(raw))}</t></is></c>`;
        })
        .filter(Boolean)
        .join('');
      return `<row r="${r}">${cells}</row>`;
    })
    .join('');

  return `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<worksheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <sheetData>
    <row r="1">${headerCells}</row>
    ${dataRows}
  </sheetData>
</worksheet>`;
}

const CONTENT_TYPES = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Types xmlns="http://schemas.openxmlformats.org/package/2006/content-types">
  <Default Extension="rels" ContentType="application/vnd.openxmlformats-package.relationships+xml"/>
  <Default Extension="xml" ContentType="application/xml"/>
  <Override PartName="/xl/workbook.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet.main+xml"/>
  <Override PartName="/xl/worksheets/sheet1.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet2.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/worksheets/sheet3.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.worksheet+xml"/>
  <Override PartName="/xl/styles.xml" ContentType="application/vnd.openxmlformats-officedocument.spreadsheetml.styles+xml"/>
</Types>`;

const ROOT_RELS = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/officeDocument" Target="xl/workbook.xml"/>
</Relationships>`;

const WORKBOOK_RELS = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<Relationships xmlns="http://schemas.openxmlformats.org/package/2006/relationships">
  <Relationship Id="rId1" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet1.xml"/>
  <Relationship Id="rId2" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet2.xml"/>
  <Relationship Id="rId3" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/worksheet" Target="worksheets/sheet3.xml"/>
  <Relationship Id="rId4" Type="http://schemas.openxmlformats.org/officeDocument/2006/relationships/styles" Target="styles.xml"/>
</Relationships>`;

const STYLES = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<styleSheet xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main">
  <fonts count="1"><font><sz val="11"/><name val="Calibri"/></font></fonts>
  <fills count="1"><fill><patternFill patternType="none"/></fill></fills>
  <borders count="1"><border/></borders>
  <cellStyleXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0"/></cellStyleXfs>
  <cellXfs count="1"><xf numFmtId="0" fontId="0" fillId="0" borderId="0" xfId="0"/></cellXfs>
</styleSheet>`;

export interface XlsxFormSheets {
  survey: SheetRow[];
  choices: SheetRow[];
  settings: SheetRow[];
}

export function writeXlsxForm(outputPath: string, sheets: XlsxFormSheets): void {
  const surveyHeaders = ['type', 'name', 'label', 'required', 'appearance', 'choice_filter', 'constraint', 'hint', 'default'];
  const choiceHeaders = ['list_name', 'name', 'label'];
  const settingsHeaders = ['form_title', 'form_id', 'version', 'default_language', 'style'];

  const workbook = `<?xml version="1.0" encoding="UTF-8" standalone="yes"?>
<workbook xmlns="http://schemas.openxmlformats.org/spreadsheetml/2006/main"
  xmlns:r="http://schemas.openxmlformats.org/officeDocument/2006/relationships">
  <sheets>
    <sheet name="survey" sheetId="1" r:id="rId1"/>
    <sheet name="choices" sheetId="2" r:id="rId2"/>
    <sheet name="settings" sheetId="3" r:id="rId3"/>
  </sheets>
</workbook>`;

  const dir = mkdtempSync(join(tmpdir(), 'along-xlsx-'));
  try {
    mkdirSync(join(dir, '_rels'), { recursive: true });
    mkdirSync(join(dir, 'xl', 'worksheets'), { recursive: true });
    mkdirSync(join(dir, 'xl', '_rels'), { recursive: true });

    writeFileSync(join(dir, '[Content_Types].xml'), CONTENT_TYPES);
    writeFileSync(join(dir, '_rels', '.rels'), ROOT_RELS);
    writeFileSync(join(dir, 'xl', 'workbook.xml'), workbook);
    writeFileSync(join(dir, 'xl', '_rels', 'workbook.xml.rels'), WORKBOOK_RELS);
    writeFileSync(join(dir, 'xl', 'styles.xml'), STYLES);
    writeFileSync(join(dir, 'xl', 'worksheets', 'sheet1.xml'), sheetXml(surveyHeaders, sheets.survey));
    writeFileSync(join(dir, 'xl', 'worksheets', 'sheet2.xml'), sheetXml(choiceHeaders, sheets.choices));
    writeFileSync(join(dir, 'xl', 'worksheets', 'sheet3.xml'), sheetXml(settingsHeaders, sheets.settings));

    execSync(`zip -qr "${outputPath}" .`, { cwd: dir, stdio: 'pipe' });
  } finally {
    rmSync(dir, { recursive: true, force: true });
  }
}
