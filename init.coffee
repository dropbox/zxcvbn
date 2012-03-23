
# initialize matcher lists
DICTIONARY_MATCHERS = [
  build_dict_matcher('passwords', build_ranked_dict(passwords)),
  build_dict_matcher('male_names', build_ranked_dict(male_names)),
  build_dict_matcher('female_names', build_ranked_dict(female_names)),
  build_dict_matcher('surnames', build_ranked_dict(surnames)),
  build_dict_matcher('words', build_ranked_dict(english))
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

time = -> (new Date()).getTime()

# now that frequency lists are loaded, replace zxcvbn stub function.
window.zxcvbn = (password) ->
  console.log 'bam'
  start = time()
  matches = omnimatch password
  result = minimum_entropy_match_sequence password, matches
  result.calc_time = time() - start
  result

#console.log(start);
#document.getElementsByTagName('h1')[0].innerHTML = time() - start;

zxcvbn_load_hook?() # run load hook from user, if defined
