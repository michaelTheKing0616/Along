import { describe, expect, it } from 'vitest';
import { renderStickerBatchPdf } from './sticker-pdf';

describe('sticker batch PDF (P4-D-02)', () => {
  it('generates a PDF label with QR image object', async () => {
    const pdfBuffer = await renderStickerBatchPdf(
      [
        {
          id: 'd2000000-0000-4000-8000-000000000201',
          driver_code: 'W04TEST1',
          plate: 'W04-PLATE',
          pay_url: 'http://127.0.0.1:3000/p/W04TEST1',
        },
      ],
      'http://127.0.0.1:3000'
    );

    const raw = pdfBuffer.toString('latin1');
    expect(pdfBuffer.subarray(0, 4).toString()).toBe('%PDF');
    expect(pdfBuffer.length).toBeGreaterThan(500);
    expect(raw).toMatch(/\/XObject/);
    expect(raw).toMatch(/\/Subtype \/Image/);
  });
});
