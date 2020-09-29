module.exports = {
  rootDir: './',
  collectCoverage: true,
  collectCoverageFrom: ['./src/**/*.{js,jsx,ts}'],
  coverageDirectory: '<rootDir>/test/coverage',
  coverageReporters: ['json', 'lcov', 'text'],
  moduleFileExtensions: ['js', 'json', 'ts'],
  moduleNameMapper: {
    '^~(.*)$': '<rootDir>/src/$1',
  },
  testURL: 'http://localhost',
  transform: {
    '^.+.js$': 'babel-jest',
    '^.+.ts': 'ts-jest',
  },
  verbose: false,
}
