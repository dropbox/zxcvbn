```
_________________________________________________/\/\___________________
_/\/\/\/\/\__/\/\__/\/\____/\/\/\/\__/\/\__/\/\__/\/\________/\/\/\/\___
_____/\/\______/\/\/\____/\/\________/\/\__/\/\__/\/\/\/\____/\/\__/\/\_
___/\/\________/\/\/\____/\/\__________/\/\/\____/\/\__/\/\__/\/\__/\/\_
_/\/\/\/\/\__/\/\__/\/\____/\/\/\/\______/\______/\/\/\/\____/\/\__/\/\_
________________________________________________________________________
```

`zxcvbn`, named after a crappy password, is a JavaScript password strength
estimation library. Use it to implement a custom strength bar on a
signup form near you!

`zxcvbn` attempts to give sound password advice through pattern matching
and conservative entropy calculations. It finds 10k common passwords,
common American names and surnames, common English words, and common
patterns like dates, repeats (aaa), sequences (abcd), and QWERTY
patterns.

For full motivation, see:

http://tech.dropbox.com/?p=165

# Installation

``` html
<script type="text/javascript" src="zxcvbn-async.js">
</script>
```

is the best way to add `zxcvbn` to your site. Host `zxcvbn.js` and
`zxcvbn-async.js` somewhere on your web server, and make the hardcoded
path inside `zxcvbn-async.js` point to `zxcvbn.js`. A relative path works
well.

`zxcvbn-async.js` is a tiny 350 bytes. On `window.load`, after your page
loads and renders, it'll fetch `zxcvbn.js`, which is more like 700k (330k
gzipped), most of which is a series of dictionaries.

I haven't found 700k to be too large -- especially because a password
isn't the first thing a user typically enters on a registration form.

`zxcvbn.js` can also be included directly:

``` html
<script type="text/javascript" src="zxcvbn.js">
</script>
```

But this isn't recommended, as the 700k download will block your
initial page load.

`zxcvbn` adds a single function to the global namespace:

``` javascript
zxcvbn(password, user_inputs)
```

It takes one required argument, a password, and returns a result object.
The result includes a few properties:

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

result.calculation_time   # how long it took to calculate an answer,
                          # in milliseconds. usually only a few ms.
````

The optional `user_inputs` argument is an array of strings that `zxcvbn`
will add to its internal dictionary. This can be whatever list of
strings you like, but is meant for user inputs from other fields of the
form, like name and email. That way a password that includes the user's
personal info can be heavily penalized. This list is also good for
site-specific vocabulary.

When `zxcvbn` loads (after the async script fetch is complete), it'll
check if a function named `zxcvbn_load_hook` is defined, and run it with
no arguments if so. Most sites shouldn't need this.

# Development

Bug reports and pull requests welcome!

`zxcvbn` is written in CoffeeScript and Python. `zxcvbn.js` is built with
`compile_and_minify.sh`, which compiles CoffeeScript into JavaScript,
then JavaScript into efficient, minified JavaScript.

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

Data lives in the first two scripts. These get produced by:

```
scripts/build_keyboard_adjacency_graph.py
scripts/build_frequency_lists.py
```

`matching.coffee`, `scoring.coffee`, and `init.coffee` make up the rest of the
library.

`init.js` needs to come last, otherwise script order doesn't matter.

I recommend setting up coffee-mode in emacs, or whatever equivalent, so
that CoffeeScript compiles to js on save. Otherwise you'll need to
repetitively run `compile_and_minify.js`


# Acknowledgments

Dropbox, thank you in so many ways, but in particular, for supporting
independent projects both inside and outside of hackweek.

Many thanks to Mark Burnett for releasing his 10k top passwords list:

http://xato.net/passwords/more-top-worst-passwords

and for his 2006 book,
"Perfect Passwords: Selection, Protection, Authentication"

Huge thanks to Wiktionary contributors for building a frequency list
of English as used in television and movies:
http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists

Last but not least, big thanks to xkcd :)
https://xkcd.com/936/
