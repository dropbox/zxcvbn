# Fill this in if guessScriptPath isn't working for your configuration
# Dropbox version ("http://dl.dropbox.com/u/209/zxcvbn/zxcvbn.js")
# Should be autodetected if you are using the async script from
# http://dl.dropbox.com/u/209/zxcvbn/zxcvbn-async.js
ZXCVBN_SRC = null

guessScriptPath = ->
  scripts = document.getElementsByTagName 'SCRIPT'
  path = ''
  if scripts && scripts.length>0
    for script in scripts
      if script.src && script.src.match(/zxcvbn-async\.js(\?.*)?$/)
        path = script.src.replace(/(.*)zxcvbn-async\.js(\?.*)?$/, '$1')
  return path + "zxcvbn.js"


# adapted from http://friendlybit.com/js/lazy-loading-asyncronous-javascript/
async_load = ->
  s = document.createElement 'script'
  if(ZXCVBN_SRC != null)
    s.src = ZXCVBN_SRC
  else
    s.src = guessScriptPath()
  s.type = 'text/javascript'
  s.async = true
  first = document.getElementsByTagName('script')[0]
  first.parentNode.insertBefore s, first

if window.attachEvent?
  window.attachEvent 'onload', async_load
else
  window.addEventListener 'load', async_load, false
