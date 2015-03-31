# initialize matcher lists
DICTIONARY_MATCHERS = [
  build_dict_matcher('passwords',    build_ranked_dict(passwords)),
  build_dict_matcher('english',      build_ranked_dict(english)),
  build_dict_matcher('male_names',   build_ranked_dict(male_names)),
  build_dict_matcher('female_names', build_ranked_dict(female_names)),
  build_dict_matcher('surnames',     build_ranked_dict(surnames))
]

MATCHERS = DICTIONARY_MATCHERS.concat [
  l33t_match,
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
  matches = omnimatch password, MATCHERS.concat [
    build_dict_matcher('user_inputs',  build_ranked_dict(user_inputs.map (_) -> _.toLowerCase()))
  ]

  result = minimum_entropy_match_sequence password, matches
  result.calc_time = time() - start
  result

# make zxcvbn function globally available
# via window or exports object, depending on the environment
if window?
  window.zxcvbn = zxcvbn
  window.zxcvbn_load_hook?() # run load hook from user, if defined
else if exports?
  exports.zxcvbn = zxcvbn
