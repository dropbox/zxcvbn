```
_________________________________________________/\/\___________________
_/\/\/\/\/\__/\/\__/\/\____/\/\/\/\__/\/\__/\/\__/\/\________/\/\/\/\___
_____/\/\______/\/\/\____/\/\________/\/\__/\/\__/\/\/\/\____/\/\__/\/\_
___/\/\________/\/\/\____/\/\__________/\/\/\____/\/\__/\/\__/\/\__/\/\_
_/\/\/\/\/\__/\/\__/\/\____/\/\/\/\______/\______/\/\/\/\____/\/\__/\/\_
________________________________________________________________________
```

`zxcvbn`, named after a crappy password, is a JavaScript password strength estimation library. Use it to implement a custom strength bar on a signup form near you!

`zxcvbn` attempts to give sound password advice through pattern matching and conservative entropy calculations. It finds 10k common passwords, common names and surnames according to US census data, common English words, and common patterns like dates, repeats (aaa), sequences (abcd), and QWERTY patterns.

For full motivation, see:

http://tech.dropbox.com/?p=165

# Installation

`zxcvbn` automatically detects and supports CommonJS (node, browserify) and AMD (RequireJS). In the absence of those, it adds a single function `zxcvbn` to the global namespace.

## Bower

Install [`node`](https://nodejs.org/download/) and [`bower`](http://bower.io/) if you haven't already. This won't make your codebase dependent on node.

Get `zxcvbn`:

``` shell
cd /path/to/project/root # your index.html lives here
bower install zxcvbn
```

Add this script to your index.html:

``` html
<script type="text/javascript" src="bower_components/zxcvbn/zxcvbn-async-bower.js">
</script>
```

That's it! To make sure it loaded properly, open index.html in a browser and type `zxcvbn('Tr0ub4dour&3')` into the console.

To pull in updates and bug fixes:

``` shell
bower update zxcvbn
```

How loading works: `zxcvbn-async-bower.js` is a tiny script. On `window.load`,  after your page loads and renders, it'll fetch `zxcvbn.js` in the background, which is more like 680kb (320kb gzipped), most of which is a series of dictionaries.

680kb may seem large for a script, but since it loads in the background, and because passwords come later in most registration flows, we've never had an issue.

## Node / npm / browserify

zxcvbn works identically on the server.

``` shell
$ npm install zxcvbn
$ node
> var zxcvbn = require('zxcvbn');
> zxcvbn('Tr0ub4dour&3');
```

And should automatically work with browserify. The easiest browserify setup is to include `zxcvbn.js` in your main bundle. If the size of the script is an issue, consider instead adding a loading script modeled after `zxcvbn-async.js` to your main bundle, such that `zxcvbn.js` loads asynchronously in the background without blocking page load. See comments in `zxcvbn-async.js` -- you'll likely only need to change `ZXCVBN_SRC` to make it work. 

## RequireJS 

Add [zxcvbn.js](https://raw.githubusercontent.com/dropbox/zxcvbn/master/zxcvbn.js) to your project (using bower or direct download) and import as usual:

``` javascript
requirejs(["relpath/to/zxcvbn"], function (zxcvbn) {
    console.log(zxcvbn('Tr0ub4dour&3'));
});
```

Note: `zxcvbn-async.js` is for manual installations. There is no need to add it to a RequireJS setup, which already provides the same asynchronous loading support.

## Manual installation

Copy `zxcvbn.js` and `zxcvbn-async.js` into your codebase.

Add to your `index.html`:

``` html
<script type="text/javascript" src="path/to/zxcvbn-async.js">
</script>
```

Open zxcvbn-async.js and edit the `ZXCVBN_SRC` variable to point to wherever you put `zxcvbn.js`. If `zxcvbn.js` sits at the top-level directory of your project, it'll work as-is.

Note that `zxcvbn.js` can also be included directly:

``` html
<script type="text/javascript" src="zxcvbn.js">
</script>
```

But this isn't recommended, as the 680k download will block your initial page load. Note: the advantage of using `zxcvbn-async.js` over the HTML5 `async` script attribute is that it works in old browsers.

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

result.calc_time          # how long it took to calculate an answer,
                          # in milliseconds. usually only a few ms.
````

The optional `user_inputs` argument is an array of strings that `zxcvbn` will add to its internal dictionary. This can be whatever list of strings you like, but is meant for user inputs from other fields of the form, like name and email. That way a password that includes the user's personal info can be heavily penalized. This list is also good for site-specific vocabulary.

# Development

Bug reports and pull requests welcome!

`zxcvbn` is written in CoffeeScript and Python. `zxcvbn.js` is built with `compile_and_minify.sh`, which compiles CoffeeScript into JavaScript, then JavaScript into efficient, minified JavaScript.

For development, include these scripts instead of `zxcvbn.js`:

``` html
<script type="text/javascript" src="adjacency_graphs.js">
</script>
<script type="text/javascript" src="frequency_lists.js">
</script>
<script type="text/javascript" src="matching.js">
</script>
<script type="text/javascript" src="scoring.js">
</script>
<script type="text/javascript" src="init.js">
</script>
```

Data lives in the first two scripts. These are produced by:

```
scripts/build_keyboard_adjacency_graph.py
scripts/build_frequency_lists.py
```

`matching.coffee`, `scoring.coffee`, and `init.coffee` make up the rest of the library.

`init.js` needs to come last, otherwise script order doesn't matter.

I recommend setting up coffee-mode in emacs, or whatever equivalent, so that CoffeeScript compiles to js on save. Otherwise you'll need to repetitively run `compile_and_minify.js`

# Acknowledgments

Dropbox for supporting open source!

Mark Burnett for releasing his [10k top passwords list](http://xato.net/passwords/more-top-worst-passwords) and for his 2006 book, [Perfect Passwords: Selection, Protection, Authentication](http://www.amazon.com/Perfect-Passwords-Selection-Protection-Authentication/dp/1597490415).

Wiktionary contributors for building a [frequency list of English](http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists) as used in television and movies.

Researchers at Concordia University for [studying password meters rigorously](http://www.concordia.ca/cunews/main/stories/2015/03/25/does-your-password-pass-muster.html) and recommending zxcvbn. 

And [xkcd](https://xkcd.com/936/) for the inspiration <3
