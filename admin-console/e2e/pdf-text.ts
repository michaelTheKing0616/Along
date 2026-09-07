import { inflateSync } from 'node:zlib';

/** Extract visible strings from pdfkit output (pdf-parse cannot read pdfkit 0.17 PDFs). */
export function extractPdfKitText(pdfBuffer: Buffer): string {
  const raw = pdfBuffer.toString('latin1');
  const streamRe = /stream\r?\n([\s\S]*?)\r?\nendstream/g;
  const parts: string[] = [];
  let match: RegExpExecArray | null;

  while ((match = streamRe.exec(raw)) !== null) {
    try {
      parts.push(inflateSync(Buffer.from(match[1], 'binary')).toString('latin1'));
    } catch {
      parts.push(match[1]);
    }
  }

  const content = parts.join('\n');
  let text = '';

  const hexRe = /<([0-9A-Fa-f]+)>/g;
  let hexMatch: RegExpExecArray | null;
  while ((hexMatch = hexRe.exec(content)) !== null) {
    const hex = hexMatch[1];
    for (let i = 0; i < hex.length; i += 2) {
      text += String.fromCharCode(parseInt(hex.slice(i, i + 2), 16));
    }
  }

  const literalRe = /\(([^)\\]*(?:\\.[^)\\]*)*)\)/g;
  let literalMatch: RegExpExecArray | null;
  while ((literalMatch = literalRe.exec(content)) !== null) {
    text += literalMatch[1].replace(/\\(.)/g, '$1');
  }

  return text;
}
