const path = require('path')

module.exports = {
  resolve: {
    extensions: ['.ts', '.js'],
    mainFiles: ['index'],
    alias: {
      '~': path.join(__dirname, '/src'),
    },
  },
}
