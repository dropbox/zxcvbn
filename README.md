```
_________________________________________________/\/\___________________
_/\/\/\/\/\__/\/\__/\/\____/\/\/\/\__/\/\__/\/\__/\/\________/\/\/\/\___
_____/\/\______/\/\/\____/\/\________/\/\__/\/\__/\/\/\/\____/\/\__/\/\_
___/\/\________/\/\/\____/\/\__________/\/\/\____/\/\__/\/\__/\/\__/\/\_
_/\/\/\/\/\__/\/\__/\/\____/\/\/\/\______/\______/\/\/\/\____/\/\__/\/\_
________________________________________________________________________
```

[![Build Status](https://travis-ci.org/dropbox/zxcvbn.svg?branch=master)](https://travis-ci.org/dropbox/zxcvbn)
[![Sauce Test Status](https://saucelabs.com/browser-matrix/dropbox-zxcvbn.svg)](https://saucelabs.com/u/dropbox-zxcvbn)

`zxcvbn` is a password strength estimator inspired by password crackers. Through pattern matching and conservative entropy calculations, it recognizes and weighs 10k common passwords, common names and surnames according to US census data, popular English words, and other common patterns like dates, repeats (`aaa`), sequences (`abcd`), keyboard patterns (`qwertyuiop`), and l33t speak.

Consider using zxcvbn as an algorithmic alternative to password policy — it is more secure, flexible, and usable when sites require a minimal complexity score in place of annoying rules like "passwords must contain three of {lower, upper, numbers, symbols}".

* __More secure__: policies often fail both ways, allowing weak passwords (`P@ssword1`) and disallowing strong passwords.
* __More flexible__: zxcvbn allows many password styles to flourish so long as it detects sufficient complexity — passphrases are rated highly given enough uncommon words, keyboard patterns are either terrible or great depending on length and number of turns, and capitalization adds more complexity when it's unpredictaBle. Neither crackers nor zxcvbn are fooled by `'@'` for `'a'` or `'0'` for `'o'`.
* __More usable__: Dumping a list of password rules onto users hurts usability. Understanding and satisfying said rules can be time-consuming and frustrating, leading to passwords that are [harder to remember](https://xkcd.com/936/). Use zxcvbn instead to build simple, rule-free interfaces that give instant feedback.

At Dropbox we use zxcvbn on our [signup page](https://www.dropbox.com/register) and change/reset password flows. zxcvbn is designed for node and the browser, but we use our [python port](https://github.com/dropbox/python-zxcvbn) inside the Dropbox desktop client, [Objective C port](https://github.com/dropbox/zxcvbn-ios) in our iOS app, and Java port (not yet open sourced) on Android.

[Release notes](https://github.com/dropbox/zxcvbn/releases)

For more motivation, see:

http://tech.dropbox.com/?p=165

# Installation

zxcvbn detects and supports CommonJS (node, browserify) and AMD (RequireJS). In the absence of those, it adds a single function `zxcvbn()` to the global namespace.

## Bower

Install [`node`](https://nodejs.org/download/) and [`bower`](http://bower.io/) if you haven't already. This won't make your codebase dependent on node or bower.

Get `zxcvbn`:

``` shell
cd /path/to/project/root
bower install zxcvbn
```

Add this script to your `index.html`:

``` html
<script type="text/javascript" src="bower_components/zxcvbn/dist/zxcvbn.js">
</script>
```

To make sure it loaded properly, open your html in a browser and type `zxcvbn('Tr0ub4dour&3')` into the console.

To pull in updates and bug fixes:

``` shell
bower update zxcvbn
```

## Node / npm

zxcvbn works identically on the server.

``` shell
$ npm install zxcvbn
$ node
> var zxcvbn = require('zxcvbn');
> zxcvbn('Tr0ub4dour&3');
```

## RequireJS

Add [`zxcvbn.js`](https://raw.githubusercontent.com/dropbox/zxcvbn/master/dist/zxcvbn.js) to your project (using bower, npm or direct download) and import as usual:

``` javascript
requirejs(["relpath/to/zxcvbn"], function (zxcvbn) {
    console.log(zxcvbn('Tr0ub4dour&3'));
});
```

## Browserify / Webpack

If you're using `npm` and have `require('zxcvbn')` somewhere in your code, browserify and webpack should just work.

``` shell
$ npm install zxcvbn
$ echo "console.log(require('zxcvbn'))" > mymodule.js
$ browserify mymodule.js > browserify_bundle.js
$ webpack mymodule.js webpack_bundle.js
```

But we recommend against bundling zxcvbn via tools like browserify and webpack, for three reasons:

* Minified and gzipped, zxcvbn is still several hundred kilobytes. (Significantly grows bundle size.)
* Most sites will only need zxcvbn on a few pages (registration, password reset).
* Most sites won't need `zxcvbn()` immediately upon page load; since `zxcvbn()` is typically called in response to user events like filling in a password, there's ample time to fetch `zxcvbn.js` after initial html/css/js loads and renders.

See the [performance](#perf) section below for tips on loading zxcvbn stand-alone.

Tangentially, if you want to build your own standalone, consider tweaking the browserify pipeline used to generate `dist/zxcvbn.js`:

``` shell
$ browserify --debug --standalone zxcvbn \
    -t coffeeify --extension='.coffee' \
    -t uglifyify \
    src/main.coffee | exorcist dist/zxcvbn.js.map >| dist/zxcvbn.js
```

* `--debug` adds an inline source map to the bundle. `exorcist` pulls it out into `dist/zxcvbn.js.map`.
* `--standalone zxcvbn` exports a global `zxcvbn` when CommonJS/AMD isn't detected.
* `-t coffeeify --extension='.coffee'` compiles `.coffee` to `.js` before bundling. This is convenient as it allows `.js` modules to import from `.coffee` modules and vice-versa. Instead of this transform, one could also compile everything to `.js` first (`npm run prepublish`) and point `browserify` to `lib` instead of `src`.
* `-t uglifyify` minifies the bundle through UglifyJS, maintaining proper source mapping.

## Manual installation

Download [zxcvbn.js](https://raw.githubusercontent.com/dropbox/zxcvbn/master/dist/zxcvbn.js).

Add to your .html:

``` html
<script type="text/javascript" src="path/to/zxcvbn.js">
</script>
```

# Usage

``` javascript
zxcvbn(password, user_inputs=[])
```

`zxcvbn()` takes one required argument, a password, and returns a result object with several properties:

``` coffee
result.guesses            # estimated guesses needed to crack password
result.guesses_log10      # order of magnitude of result.guesses

result.crack_time_seconds # dictionary of back-of-the-envelope crack time
                          # estimations, in seconds, based on a few scenarios:
{
  # online attack on a service that ratelimits password auth attempts.
  online_throttling_100_per_hour

  # online attack on a service that doesn't ratelimit,
  # or where an attacker has outsmarted ratelimiting.
  online_no_throttling_10_per_second

  # offline attack. assumes multiple attackers,
  # proper user-unique salting, and a slow hash function
  # w/ moderate work factor, such as bcrypt, scrypt, PBKDF2.
  offline_slow_hashing_1e4_per_second

  # offline attack with user-unique salting but a fast hash
  # function like SHA-1, SHA-256 or MD5. A wide range of
  # reasonable numbers anywhere from one billion - one trillion
  # guesses per second, depending on number of cores and machines.
  # ballparking at 10B/sec.
  offline_fast_hashing_1e10_per_second
}

result.crack_time_display # same keys as result.crack_time_seconds,
                          # with friendlier display string values:
                          # "subsecond", "3 hours", "centuries", etc.

result.score      # Integer from 0-4 (useful for implementing a strength bar)

  0 # too guessable: risky password. (guesses < 10^3)

  1 # very guessable: protection from throttled online attacks. (guesses < 10^6)

  2 # somewhat guessable: protection from unthrottled online attacks. (guesses < 10^8)

  3 # safely unguessable: moderate protection from offline slow-hash scenario. (guesses < 10^10)

  4 # very unguessable: strong protection from offline slow-hash scenario. (guesses >= 10^10)

result.sequence   # the list of patterns that zxcvbn based the
                  # entropy calculation on.

result.calc_time  # how long it took zxcvbn to calculate an answer,
                  # in milliseconds.
````

The optional `user_inputs` argument is an array of strings that zxcvbn will treat as an extra dictionary. This can be whatever list of strings you like, but is meant for user inputs from other fields of the form, like name and email. That way a password that includes a user's personal information can be heavily penalized. This list is also good for site-specific vocabulary — Acme Brick Co. might want to include ['acme', 'brick', 'acmebrick', etc].

# <a name="perf"></a>Performance

## runtime latency

zxcvbn operates below human perception of delay for most input: ~5-20ms for ~25 char passwords on modern browsers/CPUs, ~100ms for passwords around 100 characters. To bound runtime latency for really long passwords, consider sending `zxcvbn()` only the first 100 characters or so of user input.

## script load latency

`zxcvbn.js` bundled and minified is about 320kb gzipped or 680kb uncompressed, most of which is dictionaries. Consider these tips if you're noticing page load latency on your site.

* Make sure your server is configured to compress static assets for browsers that support it. ([nginx tutorial](https://rtcamp.com/tutorials/nginx/enable-gzip/), [apache/IIS tutorial](http://betterexplained.com/articles/how-to-optimize-your-site-with-gzip-compression/).)

Then try one of these alternatives:

1. Put your `<script src="zxcvbn.js">` tag at the end of your html, just before the closing `</body>` tag. This insures your page loads and renders before the browser fetches and loads `zxcvbn.js`. The downside with this approach is `zxcvbn()` becomes available later than had it been included in `<head>` — not an issue on most signup pages where users are filling out other fields first.

2. If you're using requirejs, try loading `zxcvbn.js` separately from your main bundle. Something to watch out for: if `zxcvbn.js` is required inside a keyboard handler waiting for user input, the entire script might be loaded only after the user presses their first key, creating nasty latency. Avoid this by calling your handler once upon page load, independent of user input, such that the `requirejs()` call runs earlier.

3. Use the HTML5 [`async`](http://www.w3schools.com/tags/att_script_async.asp) script attribute. Downside: [doesn't work](http://caniuse.com/#feat=script-async) in IE7-9 or Opera Mini.

4. Include an inline `<script>` in `<head>` that asynchronously loads `zxcvbn.js` in the background. Despite the extra code I prefer this over (3) because it works in older browsers.

``` javascript
// cross-browser asynchronous script loading for zxcvbn.
// adapted from http://friendlybit.com/js/lazy-loading-asyncronous-javascript/

(function() {
  var ZXCVBN_SRC = 'path/to/zxcvbn.js';   // eg. for a standard bower setup, 'bower_components/zxcvbn/zxcvbn.js'

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

``` shell
git clone https://github.com/dropbox/zxcvbn.git
```

zxcvbn is built with CoffeeScript, browserify, and uglify-js. CoffeeScript source lives in `src`, which gets compiled, bundled and minified into `dist/zxcvbn.js`.

``` shell
npm run build    # builds dist/zxcvbn.js
npm run watch    # same, but quickly rebuilds as changes are made in src.
```

For debugging, both `build` and `watch` output an external source map `dist/zxcvbn.js.map` that points back to the original CoffeeScript code.

Two source files, `adjacency_graphs.coffee` and `frequency_lists.coffee`, are generated by python scripts in `data-scripts` that read raw data from the `data` directory.

For node developers, in addition to `dist`, the zxcvbn `npm` module includes a `lib` directory (hidden from git) that includes one compiled `.js` and `.js.map` file for every `.coffee` in `src`. See `prepublish` in `package.json` to learn more.

# Acknowledgments

Dropbox for supporting open source!

Leah Culver and Ryan Pearl for porting zxcvbn to [Objective C](https://github.com/dropbox/zxcvbn-ios) and [python](https://github.com/dropbox/python-zxcvbn).

Mark Burnett for releasing his [10k top passwords list](http://xato.net/passwords/more-top-worst-passwords) and for his 2006 book, [Perfect Passwords: Selection, Protection, Authentication](http://www.amazon.com/Perfect-Passwords-Selection-Protection-Authentication/dp/1597490415).

Wiktionary contributors for building a [frequency list of English](http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists) as used in television and movies.

Researchers at Concordia University for [studying password estimation rigorously](http://www.concordia.ca/cunews/main/stories/2015/03/25/does-your-password-pass-muster.html) and recommending zxcvbn.

And [xkcd](https://xkcd.com/936/) for the inspiration :+1::horse::battery::heart:
