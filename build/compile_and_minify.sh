#!/bin/bash
set -e

# make sure we're in the project root directory
cd $(dirname $0)/../

# create temporary directory
mkdir -p ./temp
mkdir -p ./demo

# the coffee compiler adds a function wrapper by default.
# i add one myself manually because zxcvbn.js is built from a mix of .cs and .js files.
function_wrap () {
    echo '(function () {' "$(cat /dev/stdin)" '})();'
}

echo 'compiling cs -> js'
coffee --compile --bare --output ./temp/ ./src/lib/{matching,scoring,init}.coffee
cat ./src/async-loader/index.coffee | coffee --compile --stdio > ./temp/async.js

echo 'compiling js -> js'
# closure's simple optimizations ended up being about 200k better than whitespace-only.
# mostly from removing spaces and double quotes from the frequency lists, heh.
# advanced is only about 1k better than simple and adds complixity. skip it.
COMPILATION_LEVEL=SIMPLE_OPTIMIZATIONS
cp ./src/data/*.js ./temp/
cat ./temp/{matching,scoring,adjacency_graphs,frequency_lists,init}.js  | function_wrap > ./temp/compiled.js
java -jar ./build/tools/closure.jar --compilation_level $COMPILATION_LEVEL --js ./temp/compiled.js --js_output_file ./dist/zxcvbn.js
java -jar ./build/tools/closure.jar --compilation_level $COMPILATION_LEVEL --js ./temp/async.js    --js_output_file ./dist/zxcvbn-async.js
rm -f compiled.js
echo 'produced zxcvbn.js and zxcvbn-async.js'

echo 'cleaning up ./temp'
rm -Rf ./temp

echo 'done.'