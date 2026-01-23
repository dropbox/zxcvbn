matching = require './matching'
scoring = require './scoring'
time_estimates = require './time_estimates'
feedback = require './feedback'

time = -> (new Date()).getTime()

zxcvbn = (password, user_inputs = []) ->
  start = time()
  
  # Input validation and sanitization
  # Validate password
  return create_error_result('Password must be a string', start) if typeof password != 'string'
  return create_error_result('Password too long', start) if password.length > 1000
  
  # Validate and sanitize user inputs
  sanitized_inputs = []
  max_user_inputs = 100
  max_input_length = 100
  
  for arg in user_inputs.slice(0, max_user_inputs) # Limit number of inputs
    if typeof arg in ["string", "number", "boolean"]
      input_str = arg.toString()
      # Limit individual input length
      if input_str.length <= max_input_length
        sanitized_inputs.push input_str.toLowerCase()
  
  matching.set_user_input_dictionary sanitized_inputs
  matches = matching.omnimatch password
  result = scoring.most_guessable_match_sequence password, matches
  result.calc_time = time() - start
  attack_times = time_estimates.estimate_attack_times result.guesses
  for prop, val of attack_times
    result[prop] = val
  result.feedback = feedback.get_feedback result.score, result.sequence
  result

# Helper function to create error results
create_error_result: (error_message, start_time) ->
  {
    password: ''
    guesses: 0
    guesses_log10: 0
    score: 0
    feedback:
      warning: error_message
      suggestions: ['Please provide a valid password']
    sequence: []
    calc_time: (new Date()).getTime() - start_time
    crack_times_seconds:
      online_throttling_100_per_hour: 0
      online_no_throttling_10_per_second: 0
      offline_slow_hashing_1e4_per_second: 0
      offline_fast_hashing_1e10_per_second: 0
    crack_times_display:
      online_throttling_100_per_hour: 'less than a second'
      online_no_throttling_10_per_second: 'less than a second'
      offline_slow_hashing_1e4_per_second: 'less than a second'
      offline_fast_hashing_1e10_per_second: 'less than a second'
  }

module.exports = zxcvbn
