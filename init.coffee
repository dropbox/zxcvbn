# initialize matcher lists
DICTIONARY_MATCHERS = [
  build_dict_matcher('passwords',    build_ranked_dict(passwords)),
  build_dict_matcher('english',      build_ranked_dict(english)),
  build_dict_matcher('male_names',   build_ranked_dict(male_names)),
  build_dict_matcher('female_names', build_ranked_dict(female_names)),
  build_dict_matcher('surnames',     build_ranked_dict(surnames))
]

MATCHERS = DICTIONARY_MATCHERS.concat [
  caesar_match, l33t_match,
  digits_match, year_match, date_match,
  repeat_match, sequence_match,
  spatial_match
]

GRAPHS =
  'qwerty': qwerty
  'dvorak': dvorak
  'keypad': keypad
  'mac_keypad': mac_keypad

# on qwerty, 'g' has degree 6, being adjacent to 'ftyhbv'. '\' has degree 1.
# this calculates the average over all keys.
calc_average_degree = (graph) ->
  average = 0
  for key, neighbors of graph
    average += (n for n in neighbors when n).length
  average /= (k for k,v of graph).length
  average

KEYBOARD_AVERAGE_DEGREE     = calc_average_degree(qwerty)
KEYPAD_AVERAGE_DEGREE       = calc_average_degree(keypad) # slightly different for keypad/mac keypad, but close enough

KEYBOARD_STARTING_POSITIONS = (k for k,v of qwerty).length
KEYPAD_STARTING_POSITIONS   = (k for k,v of keypad).length

time = -> (new Date()).getTime()

# now that frequency lists are loaded, replace zxcvbn stub function.
zxcvbn = (password, user_inputs = []) ->
  start = time()

  # add the user inputs matcher on a per-request basis to keep things stateless
  sanitized_inputs = []
  for arg in user_inputs
    if arg?
      sanitized_inputs.push arg.toString().toLowerCase()
  user_inputs_matcher = build_dict_matcher 'user_inputs', build_ranked_dict(sanitized_inputs)

  matches = omnimatch password, MATCHERS.concat(user_inputs_matcher)

  result = minimum_entropy_match_sequence password, matches
  result.calc_time = time() - start
  result

# universal module definition based on:
# https://github.com/umdjs/umd/blob/master/commonjsStrict.js
loader = (root, factory) ->
  if typeof define == 'function' and define.amd?
    # AMD. Register as an anonymous module
    define ['exports'], factory
  else if typeof exports == 'object'
    # CommonJS (including node support)
    factory exports
  else
    # Add browser global
    root.zxcvbn = zxcvbn
  root.zxcvbn_load_hook?() # run load hook from user, if defined

loader this, (exports) ->
  exports.zxcvbn = zxcvbn
