#!/bin/bash
set -e

# make sure we're in the project root directory
cd $(dirname $0)/../

# create demo dist directory
mkdir -p ./dist/demo

cp ./src/demo/{*.html,*.js} ./dist/demo/

coffee --compile --output ./dist/demo/ ./src/demo/demo.coffee