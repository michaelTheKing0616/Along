import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  transpilePackages: ['@along/contracts'],
  // pdfkit ships AFM font metrics beside its entry; bundling breaks server PDF export (A-13).
  serverExternalPackages: ['pdfkit'],
};

export default nextConfig;
