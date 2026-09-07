import PDFDocument from 'pdfkit';
import QRCode from 'qrcode';
import type { StickerBatchDriver } from './types';

const PREVIEW_BANNER = 'STAGING — not for production vehicles';

function buildPayUrl(driverCode: string, origin: string): string {
  const base = origin.replace(/\/$/, '');
  return `${base}/p/${driverCode}`;
}

export async function renderStickerBatchPdf(
  drivers: StickerBatchDriver[],
  origin: string
): Promise<Buffer> {
  const doc = new PDFDocument({ size: 'A4', margin: 36 });
  const chunks: Buffer[] = [];

  const finished = new Promise<Buffer>((resolve, reject) => {
    doc.on('data', (chunk: Buffer) => chunks.push(chunk));
    doc.on('end', () => resolve(Buffer.concat(chunks)));
    doc.on('error', reject);
  });

  doc.fontSize(10).fillColor('#B91C1C').text(PREVIEW_BANNER, { align: 'center' });
  doc.moveDown(0.5);
  doc.fontSize(8).fillColor('#666').text('Ops preview only — do not affix to vehicles.', {
    align: 'center',
  });
  doc.moveDown(1);

  const cols = 2;
  const labelWidth = 252;
  const labelHeight = 180;
  const gapX = 24;
  const gapY = 24;
  let col = 0;
  let rowY = doc.y;

  for (let i = 0; i < drivers.length; i++) {
    const driver = drivers[i];
    const x = 36 + col * (labelWidth + gapX);
    const y = rowY;

    const payUrl = buildPayUrl(driver.driver_code, origin);
    const qrDataUrl = await QRCode.toDataURL(payUrl, {
      errorCorrectionLevel: 'H',
      margin: 1,
      width: 120,
      color: { dark: '#0A0A0A', light: '#FFFFFF' },
    });
    const qrBase64 = qrDataUrl.replace(/^data:image\/png;base64,/, '');
    const qrBuffer = Buffer.from(qrBase64, 'base64');

    doc.rect(x, y, labelWidth, labelHeight).stroke('#0A0A0A');
    doc.image(qrBuffer, x + 16, y + 16, { width: 96, height: 96 });
    doc
      .fontSize(14)
      .fillColor('#0A0A0A')
      .text(driver.plate ?? '—', x + 120, y + 24, { width: 120 });
    doc.fontSize(10).text(driver.driver_code, x + 120, y + 48, { width: 120 });
    doc.fontSize(7).fillColor('#666').text(PREVIEW_BANNER, x + 120, y + 68, { width: 120 });

    col += 1;
    if (col >= cols) {
      col = 0;
      rowY += labelHeight + gapY;
      if (rowY + labelHeight > doc.page.height - 36 && i < drivers.length - 1) {
        doc.addPage();
        doc.fontSize(10).fillColor('#B91C1C').text(PREVIEW_BANNER, { align: 'center' });
        doc.moveDown(1);
        rowY = doc.y;
      }
    }
  }

  doc.end();
  return finished;
}
