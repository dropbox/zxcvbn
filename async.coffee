
ZXCVBN_SRC = 'http://dl.dropbox.com/u/209/zxcvbn/zxcvbn.js'

# adapted from http://friendlybit.com/js/lazy-loading-asyncronous-javascript/
async_load = ->
  s = document.createElement 'script'
  s.src = ZXCVBN_SRC
  s.type = 'text/javascript'
  s.async = true
  first = document.getElementsByTagName('script')[0]
  first.parentNode.insertBefore s, first

if window.attachEvent?
  window.attachEvent 'onload', async_load
else
  window.addEventListener 'load', async_load, false
