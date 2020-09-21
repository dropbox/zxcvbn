import path from 'path'
import alias from '@rollup/plugin-alias'
import babel from '@rollup/plugin-babel'
import commonjs from '@rollup/plugin-commonjs'
import del from 'rollup-plugin-delete'
import copy from 'rollup-plugin-copy'

let generateCounter = 0
const generateConfig = (type) => {
  let babelrc = true
  const output = {
    dir: 'dist/',
    format: type,
    entryFileNames: '[name].js',
    assetFileNames: '[name].js',
    sourcemap: true,
    exports: 'auto',
  }
  if (type === 'esm') {
    output.entryFileNames = '[name].esm.js'
    output.assetFileNames = '[name].esm.js'
    babelrc = false
  }
  const pluginsOnlyOnce = []
  if (generateCounter === 0) {
    pluginsOnlyOnce.push(
      del({
        targets: 'dist/*',
      }),
      copy({
        targets: [
          {
            src: 'package.json',
            dest: 'dist/',
          },
          {
            src: 'CHANGELOG.md',
            dest: 'dist/',
          },
        ],
      }),
    )

    generateCounter += 1
  }

  return {
    input: './src/main.js',
    output,
    plugins: [
      ...pluginsOnlyOnce,
      alias({
        entries: [
          {
            find: '~',
            replacement: path.join(__dirname, '..', '/src'),
          },
        ],
      }),
      commonjs(),
      babel({
        extensions: ['.js'],
        babelHelpers: 'bundled',
        babelrc,
      }),
    ],
    preserveModules: false,
  }
}

export default [generateConfig('esm'), generateConfig('cjs')]
