module.exports = {
  rootDir: './',
  collectCoverage: true,
  collectCoverageFrom: ['./src/**/*.{js,jsx}'],
  coverageDirectory: '<rootDir>/test/coverage',
  coverageReporters: ['json', 'lcov', 'text'],
  moduleFileExtensions: ['js', 'json'],
  moduleNameMapper: {
    '^~(.*)$': '<rootDir>/src/$1',
  },
  testURL: 'http://localhost',
  transform: {
    '^.+.js$': 'babel-jest',
  },
  verbose: false,
}
