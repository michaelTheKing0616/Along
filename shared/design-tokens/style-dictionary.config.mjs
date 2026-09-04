/** @type {import('style-dictionary').Config} */
export default {
  source: ['tokens.json'],
  platforms: {
    dart: {
      buildPath: 'build/dart/',
      files: [{ destination: 'along_tokens.dart', format: 'along/flutter-dart' }],
    },
    css: {
      buildPath: 'build/css/',
      files: [{ destination: 'tokens.css', format: 'along/css-variables' }],
    },
    tailwind: {
      buildPath: 'build/tailwind/',
      files: [{ destination: 'preset.cjs', format: 'along/tailwind-preset' }],
    },
  },
};
