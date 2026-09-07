import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  transpilePackages: ['@along/contracts', 'maplibre-gl'],
  // pdfkit ships AFM font metrics beside its entry; bundling breaks server PDF export (A-13).
  serverExternalPackages: ['pdfkit'],
};

export default nextConfig;
