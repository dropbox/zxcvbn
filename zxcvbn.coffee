time = -> (new Date()).getTime()

zxcvbn = (password) ->
  start = time()
  matches = omnimatch password
  best_match_data = minimum_entropy_match_sequence password, matches
  best_match_data.calc_time = time() - start
  best_match_data

window?.zxcvbn = zxcvbn
