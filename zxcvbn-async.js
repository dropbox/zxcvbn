// cross-browser asynchronous script loading for zxcvbn.
// adapted from http://friendlybit.com/js/lazy-loading-asyncronous-javascript/

// Suggestion: instead of manually configuring this script,
// follow the bower setup instructions (see README) for easier installation and
// updating.

// If you do want to manually include zxcvbn, you'll likely only need to change
// ZXCVBN_SRC to point to the correct relative path from your index.html.
// (this script assumes index.html and zxcvbn.js sit next to each other.)

(function() {
  var ZXCVBN_SRC = 'zxcvbn.js';

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
