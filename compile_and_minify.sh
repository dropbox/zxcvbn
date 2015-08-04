#!/bin/bash
set -e

printf 'compiling and bundling...'
browserify --standalone zxcvbn -t coffeeify --extension='.coffee' main.coffee >| bundle.js
printf 'done\n'

# closure's simple optimizations ended up being about 200k better than whitespace-only.
# mostly from removing spaces and double quotes from the frequency lists, heh.
# advanced is only about 1k better than simple and adds complixity. skip it.
printf 'minifying...'
java -jar tools/closure.jar --compilation_level SIMPLE_OPTIMIZATIONS --js bundle.js --js_output_file zxcvbn.js
printf 'done\n'
rm -f bundle.js
