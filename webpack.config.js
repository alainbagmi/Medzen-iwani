const path = require('path');

module.exports = {
  mode: 'production',
  entry: './chime-sdk-browser-entry.js',
  output: {
    path: path.resolve(__dirname, 'web/assets'),
    filename: 'amazon-chime-sdk-medzen.min.js',
    library: {
      name: 'ChimeSDK',
      type: 'umd',
      export: 'default'
    },
    globalObject: 'this'
  },
  resolve: {
    extensions: ['.js', '.json'],
    fallback: {
      "buffer": false,
      "crypto": false,
      "stream": false,
      "util": false,
      "process": false
    }
  },
  optimization: {
    minimize: true
  },
  performance: {
    maxAssetSize: 5000000, // 5MB
    maxEntrypointSize: 5000000
  }
};
