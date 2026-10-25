import type { NextConfig } from 'next';

const nextConfig: NextConfig = {
  transpilePackages: ['@along/contracts', 'maplibre-gl'],
  // pdfkit ships AFM font metrics beside its entry; bundling breaks server PDF export (A-13).
  serverExternalPackages: ['pdfkit'],
  webpack: (config) => {
    // @along/contracts is NodeNext TypeScript: its imports name `./x.js` for `./x.ts`.
    config.resolve.extensionAlias = {
      ...config.resolve.extensionAlias,
      '.js': ['.ts', '.tsx', '.js'],
    };
    return config;
  },
};

export default nextConfig;
