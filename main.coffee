time = -> (new Date()).getTime()

zxcvbn = (password) ->
  start = time()
  matches = omnimatch password
  result = minimum_entropy_match_sequence password, matches
  result.calc_time = time() - start
  result

window?.zxcvbn = zxcvbn
