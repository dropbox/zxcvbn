const path = require('path')

module.exports = {
  resolve: {
    extensions: ['.js'],
    mainFiles: ['index'],
    alias: {
      '~': path.join(__dirname, '/src'),
    },
  },
}
