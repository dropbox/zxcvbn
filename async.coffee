
# ZXCVBN_SRC = '/zxcvbn/zxcvbn.js'
scripts = document.getElementsByTagName("script")
index = scripts.length - 1
ZXCVBN_SRC = scripts[index].src + "/../zxcvbn.js"

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
