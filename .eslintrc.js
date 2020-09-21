const prettierConfig = require('./prettier.js')

module.exports = {
  root: true,
  parser: '@typescript-eslint/parser',
  extends: [
    'airbnb-base',
    'plugin:compat/recommended',
    'prettier',
    'prettier/@typescript-eslint',
    'prettier/babel',
    'prettier/vue',
    'plugin:jest/recommended',
    'plugin:@typescript-eslint/eslint-recommended',
  ],
  plugins: ['import', 'prettier', 'jest', '@typescript-eslint'],
  settings: {
    'import/resolver': {
      webpack: {
        config: 'eslint-webpack-resolver.config.js',
      },
    },
  },
  env: {
    browser: true,
  },
  rules: {
    'prettier/prettier': ['warn', prettierConfig],
    'import/no-extraneous-dependencies': 'off',
    'no-restricted-imports': [
      'error',
      {
        paths: [
          {
            name: 'date-fns',
            message:
              'Please import functions from files for smaller bundle size.',
          },
        ],
      },
    ],
    'semi': ['error', 'never'],
    'no-console': ['error', { allow: ['info', 'warn', 'error'] }],
    'complexity': ['error', 20],
    'max-lines-per-function': [
      'warn',
      {
        max: 100,
        skipComments: true,
        skipBlankLines: true,
      },
    ],
    'import/extensions': [
      'error',
      'always',
      {
        js: 'never',
        ts: 'never',
      },
    ],

    // Disabling eslint rule and enabling typescript specific to support TS features
    'no-unused-vars': 'off',
    '@typescript-eslint/no-unused-vars': [
      'error',
      {
        argsIgnorePattern: '^_',
      },
    ],
    'no-useless-constructor': 'off',
    '@typescript-eslint/no-useless-constructor': 'error',
    'no-empty-function': 'off',
    '@typescript-eslint/no-empty-function': 'error',
    'class-methods-use-this': 0,

    'prefer-destructuring': [
      'error',
      {
        array: false,
        object: true,
      },
    ],
  },
}
