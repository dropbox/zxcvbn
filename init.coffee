Init = do ->

  # on qwerty, 'g' has degree 6, being adjacent to 'ftyhbv'. '\' has degree 1.
  # this calculates the average over all keys.
  # TODO move this outside of init code.
  calc_average_degree = (graph) ->
    average = 0
    for key, neighbors of graph
      average += (n for n in neighbors when n).length
    average /= (k for k,v of graph).length
    average

  time = -> (new Date()).getTime()

  zxcvbn = (password, user_inputs = []) ->
    start = time()

    # add the user inputs matcher on a per-request basis to keep things stateless
    sanitized_inputs = []
    for arg in user_inputs
      if typeof arg in ["string", "number", "boolean"]
        sanitized_inputs.push arg.toString().toLowerCase()
    ranked_dict = Matching.build_ranked_dict sanitized_inputs
    user_inputs_matcher = Matching.build_dict_matcher 'user_inputs', ranked_dict

    matches = Matching.omnimatch password, Init.MATCHERS.concat(user_inputs_matcher)

    result = Scoring.minimum_entropy_match_sequence password, matches
    result.calc_time = time() - start
    result

  dictionary_matchers = [
    Matching.build_dict_matcher('passwords', Matching.build_ranked_dict(FrequencyLists.passwords)),
    Matching.build_dict_matcher('english',   Matching.build_ranked_dict(FrequencyLists.english)),
    Matching.build_dict_matcher('surnames',  Matching.build_ranked_dict(FrequencyLists.surnames))
    Matching.build_dict_matcher('male_names',
      Matching.build_ranked_dict(FrequencyLists.male_names)),
    Matching.build_dict_matcher('female_names',
      Matching.build_ranked_dict(FrequencyLists.female_names)),
  ]

  # ------------------------------------------------------------------------------
  # universal module definition based on: ----------------------------------------
  # https://github.com/umdjs/umd/blob/master/returnExports.js --------------------
  # ------------------------------------------------------------------------------

  umd = (root, factory) ->
    if typeof define == 'function' and define.amd?
      # AMD. Register as an anonymous module
      define [], factory
    else if typeof module == 'object' and module.exports?
      # works with CommonJS environments that support module.exports, like node
      module.exports = factory()
    else
      # Add browser global
      root.zxcvbn = factory()
    root.zxcvbn_load_hook?() # DEPRICATED run load hook from user, if defined. TODO remove

  # do module export
  umd this, -> zxcvbn

  # ------------------------------------------------------------------------------
  # return value: graphs and matchers --------------------------------------------
  # ------------------------------------------------------------------------------

  DICTIONARY_MATCHERS: dictionary_matchers

  MATCHERS: dictionary_matchers.concat [
    Matching.l33t_match,
    Matching.digits_match,
    Matching.year_match,
    Matching.date_match,
    Matching.repeat_match,
    Matching.sequence_match,
    Matching.spatial_match
  ]

  GRAPHS:
    'qwerty':     AdjacencyGraphs.qwerty
    'dvorak':     AdjacencyGraphs.dvorak
    'keypad':     AdjacencyGraphs.keypad
    'mac_keypad': AdjacencyGraphs.mac_keypad

  KEYBOARD_AVERAGE_DEGREE: calc_average_degree(AdjacencyGraphs.qwerty)
  KEYPAD_AVERAGE_DEGREE:   calc_average_degree(AdjacencyGraphs.keypad) # slightly different for keypad/mac keypad, but close enough

  KEYBOARD_STARTING_POSITIONS: (k for k,v of AdjacencyGraphs.qwerty).length
  KEYPAD_STARTING_POSITIONS:   (k for k,v of AdjacencyGraphs.keypad).length
