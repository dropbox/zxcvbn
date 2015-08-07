```
_________________________________________________/\/\___________________
_/\/\/\/\/\__/\/\__/\/\____/\/\/\/\__/\/\__/\/\__/\/\________/\/\/\/\___
_____/\/\______/\/\/\____/\/\________/\/\__/\/\__/\/\/\/\____/\/\__/\/\_
___/\/\________/\/\/\____/\/\__________/\/\/\____/\/\__/\/\__/\/\__/\/\_
_/\/\/\/\/\__/\/\__/\/\____/\/\/\/\______/\______/\/\/\/\____/\/\__/\/\_
________________________________________________________________________
```

`zxcvbn`, named after a crappy password, is a password strength estimator. `zxcvbn` is different from other estimators in that it evaluates passwords the way modern crackers crack them. Through search, pattern matching, and conservative entropy calculations, it finds 10k common passwords, common names and surnames according to US census data, common English words, and other common patterns like dates, repeats (aaa), sequences (abcd), QWERTY patterns, and l33t speak.

`zxcvbn` is an algorithm that can be used in place of a password policy -- it is more secure, more flexible, and less frustrating when sites require a minimal score instead of the dreaded "passwords must contain three of {lower, upper, numbers, symbols}". Passwords can be strong and weak for so many reasons that are hard to capture with policy rules, whereas `zxcvbn` allows many styles so long as it detects sufficient complexity. Passphrases are rated highly given enough uncommon words, for example. Keyboard patterns are either terrible or great depending on length and number of shifts and turns. Capitalization adds complexity, but only if it's unpredictable. Neither crackers nor `zxcvbn` are fooled by '@' for 'a' or '0' for 'o'.

At Dropbox we use `zxcvbn` to give people instantaneous feedback when they create a new account or change/reset a password. `zxcvbn` is designed for node and the browser, but we use our [python port](https://github.com/dropbox/python-zxcvbn) inside the Dropbox desktop client, [Objective C port](https://github.com/dropbox/zxcvbn-ios) on iOS, and Java port (not yet open sourced) on Android.

For more motivation, see:

http://tech.dropbox.com/?p=165

# Installation

`zxcvbn` automatically detects and supports CommonJS (node, browserify) and AMD (RequireJS). In the absence of those, it adds a single function `zxcvbn` to the global namespace.

## Bower

Install [`node`](https://nodejs.org/download/) and [`bower`](http://bower.io/) if you haven't already. This won't make your codebase dependent on node or bower.

Get `zxcvbn`:

``` shell
cd /path/to/project/root # your index.html lives here
bower install zxcvbn
```

Add this script to your index.html:

``` html
<script type="text/javascript" src="bower_components/zxcvbn/zxcvbn.js">
</script>
```

To make sure it loaded properly, open index.html in a browser and type `zxcvbn('Tr0ub4dour&3')` into the console.

To pull in updates and bug fixes:

``` shell
bower update zxcvbn
```

## Node / npm / browserify

zxcvbn works identically on the server.

``` shell
$ npm install zxcvbn
$ node
> var zxcvbn = require('zxcvbn');
> zxcvbn('Tr0ub4dour&3');
```

And should automatically work with browserify. The easiest browserify setup is to include `zxcvbn.js` in your main bundle. If script size is an issue, see the [performance](#perf) section below for ways to reduce latency. 

## RequireJS 

Add [zxcvbn.js](https://raw.githubusercontent.com/dropbox/zxcvbn/master/lib/zxcvbn.js) to your project (using bower, npm or direct download) and import as usual:

``` javascript
requirejs(["relpath/to/zxcvbn"], function (zxcvbn) {
    console.log(zxcvbn('Tr0ub4dour&3'));
});
```

## Manual installation

Download [zxcvbn.js](https://raw.githubusercontent.com/dropbox/zxcvbn/master/lib/zxcvbn.js).

Add to your .html:

``` html
<script type="text/javascript" src="path/to/zxcvbn.js">
</script>
```

# Usage

``` javascript
zxcvbn(password, user_inputs)
```

It takes one required argument, a password, and returns a result object. The result includes a few properties:

``` coffeescript
result.entropy            # bits

result.crack_time         # estimation of actual crack time, in seconds.

result.crack_time_display # same crack time, as a friendlier string:
                          # "instant", "6 minutes", "centuries", etc.

result.score              # [0,1,2,3,4] if crack time is less than
                          # [10**2, 10**4, 10**6, 10**8, Infinity].
                          # (useful for implementing a strength bar.)

result.match_sequence     # the list of patterns that zxcvbn based the
                          # entropy calculation on.

result.calc_time          # how long it took zxcvbn to calculate an answer,
                          # in milliseconds.
````

The optional `user_inputs` argument is an array of strings that `zxcvbn` will add to its internal dictionary. This can be whatever list of strings you like, but is meant for user inputs from other fields of the form, like name and email. That way a password that includes the user's personal info can be heavily penalized. This list is also good for site-specific vocabulary -- Acme Brick Co. might want to include ['acme', 'brick', 'acmebrick', etc]. 

# Performance

## runtime latency

`zxcvbn` usually operates below human perception of delay: ~5-20ms for typical passwords on modern browsers/CPUs, ~100ms for passwords around 100 characters. To bound runtime latency for really long passwords, consider sending `zxcvbn` only the first 100 characters or so of user input.

## script load latency

`zxcvbn` bundled and minified is about 870kb uncompressed, 350kb gzipped, most of which is dictionaries. Consider these tips if you're noticing page load latency on your site. 

* Make sure your server is configured to compress static assets for browsers that support it. ([Intro + apache/IIS tutorials](http://betterexplained.com/articles/how-to-optimize-your-site-with-gzip-compression/), [nginx tutorial](https://rtcamp.com/tutorials/nginx/enable-gzip/).)

Then try one of these alternatives: 

1. Put your `<script src="zxcvbn.js">` tag at the end of your html, just before the closing </body> tag. This insures your page loads and renders before the browser fetches and loads `zxcvbn`. The downside with this approach is `zxcvbn` becomes available later than had it been included in `<head>` -- not an issue on most signup pages where users are filling in other fields first.

2. If you're using requirejs, try keeping `zxcvbn` outside of your main bundle and loading separately. Something to watch out for: if `zxcvbn` is required only inside a keyboard handler waiting for user input, the entire script may be loaded only after the user presses their first key leading to nasty latency. Avoid this by calling your handler once upon page load, independent of user input, such that `zxcvbn` starts downloading in the background earlier.

3. Use the HTML5 [`async` script attribute](http://www.w3schools.com/tags/att_script_async.asp). Downside: [doesn't work](http://caniuse.com/#feat=script-async) in IE7-9 or Opera Mini. 

4. Include an inline `<script>` in `<head>` that asynchronously loads zxcvbn in the background. Despite the extra code I prefer this over (3) because it works in older browsers.

``` javascript
// cross-browser asynchronous script loading for zxcvbn.
// adapted from http://friendlybit.com/js/lazy-loading-asyncronous-javascript/

(function() {
  // eg. for a standard bower setup, 'bower_components/zxcvbn/zxcvbn.js' 
  var ZXCVBN_SRC = 'path/to/zxcvbn.js';

  var async_load = function() {
    var first, s;
    s = document.createElement('script');
    s.src = ZXCVBN_SRC;
    s.type = 'text/javascript';
    s.async = true;
    first = document.getElementsByTagName('script')[0];
    return first.parentNode.insertBefore(s, first);
  };

  if (window.attachEvent != null) {
    window.attachEvent('onload', async_load);
  } else {
    window.addEventListener('load', async_load, false);
  }

}).call(this);
```

# Development

Bug reports and pull requests welcome!

`zxcvbn` is built with CoffeeScript, browserify, and uglifyjs. CoffeeScript source lives in `src`, which gets compiled, bundled and minified into `lib/zxcvbn.js`. 

``` shell
npm run build    # builds lib/zxcvbn.js
npm run watch    # same, but quickly rebuilds as changes are made in src. 
```

Two source files, `adjacency_graphs.coffee` and `frequency_lists.coffee`, are generated by python scripts in `data-scripts` that read raw data from the `data` directory.

# Acknowledgments

Dropbox for supporting open source!

Leah Culver and Ryan Pearl for porting zxcvbn to [Objective C](https://github.com/dropbox/zxcvbn-ios) and [python](https://github.com/dropbox/python-zxcvbn).

Mark Burnett for releasing his [10k top passwords list](http://xato.net/passwords/more-top-worst-passwords) and for his 2006 book, [Perfect Passwords: Selection, Protection, Authentication](http://www.amazon.com/Perfect-Passwords-Selection-Protection-Authentication/dp/1597490415).

Wiktionary contributors for building a [frequency list of English](http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists) as used in television and movies.

Researchers at Concordia University for [studying password meters rigorously](http://www.concordia.ca/cunews/main/stories/2015/03/25/does-your-password-pass-muster.html) and recommending zxcvbn. 

And [xkcd](https://xkcd.com/936/) for the inspiration <3
