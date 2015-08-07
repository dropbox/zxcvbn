matching = require('./matching')
scoring = require('./scoring')

time = -> (new Date()).getTime()

zxcvbn = (password, user_inputs = []) ->
  start = time()
  # reset the user inputs matcher on a per-request basis to keep things stateless
  sanitized_inputs = []
  for arg in user_inputs
    if typeof arg in ["string", "number", "boolean"]
      sanitized_inputs.push arg.toString().toLowerCase()
  matching.set_user_input_dictionary sanitized_inputs
  matches = matching.omnimatch password
  result = scoring.minimum_entropy_match_sequence password, matches
  result.calc_time = time() - start
  result

module.exports = zxcvbn
