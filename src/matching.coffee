frequency_lists = require('./frequency_lists')
adjacency_graphs = require('./adjacency_graphs')
scoring = require('./scoring')

build_ranked_dict = (ordered_list) ->
  result = {}
  i = 1 # rank starts at 1, not 0
  for word in ordered_list
    result[word] = i
    i += 1
  result

RANKED_DICTIONARIES = {}
for name, lst of frequency_lists
  RANKED_DICTIONARIES[name] = build_ranked_dict lst

GRAPHS =
  qwerty:     adjacency_graphs.qwerty
  dvorak:     adjacency_graphs.dvorak
  keypad:     adjacency_graphs.keypad
  mac_keypad: adjacency_graphs.mac_keypad

L33T_TABLE =
  a: ['4', '@']
  b: ['8']
  c: ['(', '{', '[', '<']
  e: ['3']
  g: ['6', '9']
  i: ['1', '!', '|']
  l: ['1', '|', '7']
  o: ['0']
  s: ['$', '5']
  t: ['+', '7']
  x: ['%']
  z: ['2']

REGEXEN =
  recent_year:  /19\d\d|200\d|201\d/g

DATE_MAX_YEAR = 2050
DATE_MIN_YEAR = 1000
DATE_SPLITS =
  4:[      # for length-4 strings, eg 1191 or 9111, two ways to split:
    [1, 2] # 1 1 91 (2nd split starts at index 1, 3rd at index 2)
    [2, 3] # 91 1 1
    ]
  5:[
    [1, 3] # 1 11 91
    [2, 3] # 11 1 91
    ]
  6:[
    [1, 2] # 1 1 1991
    [2, 4] # 11 11 91
    [4, 5] # 1991 1 1
    ]
  7:[
    [1, 3] # 1 11 1991
    [2, 3] # 11 1 1991
    [4, 5] # 1991 1 11
    [4, 6] # 1991 11 1
    ]
  8:[
    [2, 4] # 11 11 1991
    [4, 6] # 1991 11 11
    ]

matching =
  empty: (obj) -> (k for k of obj).length == 0
  extend: (lst, lst2) -> lst.push.apply lst, lst2
  translate: (string, chr_map) -> (chr_map[chr] or chr for chr in string.split('')).join('')
  mod: (n, m) -> ((n % m) + m) % m # mod impl that works for negative numbers
  sorted: (matches) ->
    # sort on i primary, j secondary
    matches.sort (m1, m2) ->
      (m1.i - m2.i) or (m1.j - m2.j)

  # ------------------------------------------------------------------------------
  # omnimatch -- combine everything ----------------------------------------------
  # ------------------------------------------------------------------------------

  omnimatch: (password) ->
    matches = []
    matchers = [
      @dictionary_match
      @reverse_dictionary_match
      @l33t_match
      @spatial_match
      @repeat_match
      @sequence_match
      @regex_match
      @date_match
    ]
    for matcher in matchers
      @extend matches, matcher.call(this, password)
    @sorted matches

  #-------------------------------------------------------------------------------
  # dictionary match (common passwords, english, last names, etc) ----------------
  #-------------------------------------------------------------------------------

  dictionary_match: (password, _ranked_dictionaries = RANKED_DICTIONARIES) ->
    # _ranked_dictionaries variable is for unit testing purposes
    matches = []
    len = password.length
    password_lower = password.toLowerCase()
    for dictionary_name, ranked_dict of _ranked_dictionaries
      for i in [0...len]
        for j in [i...len]
          if password_lower[i..j] of ranked_dict
            word = password_lower[i..j]
            rank = ranked_dict[word]
            matches.push
              pattern: 'dictionary'
              i: i
              j: j
              token: password[i..j]
              matched_word: word
              rank: rank
              dictionary_name: dictionary_name
              reversed: false
              l33t: false
    @sorted matches

  reverse_dictionary_match: (password, _ranked_dictionaries = RANKED_DICTIONARIES) ->
    reversed_password = password.split('').reverse().join('')
    matches = @dictionary_match reversed_password, _ranked_dictionaries
    for match in matches
      match.token = match.token.split('').reverse().join('') # reverse back
      match.reversed = true
      # map coordinates back to original string
      [match.i, match.j] = [
        password.length - 1 - match.j
        password.length - 1 - match.i
      ]
    @sorted matches

  set_user_input_dictionary: (ordered_list) ->
    RANKED_DICTIONARIES['user_inputs'] = build_ranked_dict ordered_list.slice()

  #-------------------------------------------------------------------------------
  # dictionary match with common l33t substitutions ------------------------------
  #-------------------------------------------------------------------------------

  # makes a pruned copy of l33t_table that only includes password's possible substitutions
  relevant_l33t_subtable: (password, table) ->
    password_chars = {}
    for chr in password.split('')
      password_chars[chr] = true
    subtable = {}
    for letter, subs of table
      relevant_subs = (sub for sub in subs when sub of password_chars)
      if relevant_subs.length > 0
        subtable[letter] = relevant_subs
    subtable

  # returns the list of possible 1337 replacement dictionaries for a given password
  enumerate_l33t_subs: (table) ->
    keys = (k for k of table)
    subs = [[]]

    dedup = (subs) ->
      deduped = []
      members = {}
      for sub in subs
        assoc = ([k,v] for k,v in sub)
        assoc.sort()
        label = (k+','+v for k,v in assoc).join('-')
        unless label of members
          members[label] = true
          deduped.push sub
      deduped

    helper = (keys) ->
      return if not keys.length
      first_key = keys[0]
      rest_keys = keys[1..]
      next_subs = []
      for l33t_chr in table[first_key]
        for sub in subs
          dup_l33t_index = -1
          for i in [0...sub.length]
            if sub[i][0] == l33t_chr
              dup_l33t_index = i
              break
          if dup_l33t_index == -1
            sub_extension = sub.concat [[l33t_chr, first_key]]
            next_subs.push sub_extension
          else
            sub_alternative = sub.slice(0)
            sub_alternative.splice(dup_l33t_index, 1)
            sub_alternative.push [l33t_chr, first_key]
            next_subs.push sub
            next_subs.push sub_alternative
      subs = dedup next_subs
      helper(rest_keys)

    helper(keys)
    sub_dicts = [] # convert from assoc lists to dicts
    for sub in subs
      sub_dict = {}
      for [l33t_chr, chr] in sub
        sub_dict[l33t_chr] = chr
      sub_dicts.push sub_dict
    sub_dicts

  l33t_match: (password, _ranked_dictionaries = RANKED_DICTIONARIES, _l33t_table = L33T_TABLE) ->
    matches = []
    for sub in @enumerate_l33t_subs @relevant_l33t_subtable(password, _l33t_table)
      break if @empty sub # corner case: password has no relevant subs.
      subbed_password = @translate password, sub
      for match in @dictionary_match(subbed_password, _ranked_dictionaries)
        token = password[match.i..match.j]
        if token.toLowerCase() == match.matched_word
          continue # only return the matches that contain an actual substitution
        match_sub = {} # subset of mappings in sub that are in use for this match
        for subbed_chr, chr of sub when token.indexOf(subbed_chr) != -1
          match_sub[subbed_chr] = chr
        match.l33t = true
        match.token = token
        match.sub = match_sub
        match.sub_display = ("#{k} -> #{v}" for k,v of match_sub).join(', ')
        matches.push match
    @sorted matches.filter (match) ->
      # filter single-character l33t matches to reduce noise.
      # otherwise '1' matches 'i', '4' matches 'a', both very common English words
      # with low dictionary rank.
      match.token.length > 1

  # ------------------------------------------------------------------------------
  # spatial match (qwerty/dvorak/keypad) -----------------------------------------
  # ------------------------------------------------------------------------------

  spatial_match: (password, _graphs = GRAPHS) ->
    matches = []
    for graph_name, graph of _graphs
      @extend matches, @spatial_match_helper(password, graph, graph_name)
    @sorted matches

  SHIFTED_RX: /[~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?]/
  spatial_match_helper: (password, graph, graph_name) ->
    matches = []
    i = 0
    while i < password.length - 1
      j = i + 1
      last_direction = null
      turns = 0
      if graph_name in ['qwerty', 'dvorak'] and @SHIFTED_RX.exec(password.charAt(i))
        # initial character is shifted
        shifted_count = 1
      else
        shifted_count = 0
      loop
        prev_char = password.charAt(j-1)
        found = false
        found_direction = -1
        cur_direction = -1
        adjacents = graph[prev_char] or []
        # consider growing pattern by one character if j hasn't gone over the edge.
        if j < password.length
          cur_char = password.charAt(j)
          for adj in adjacents
            cur_direction += 1
            if adj and adj.indexOf(cur_char) != -1
              found = true
              found_direction = cur_direction
              if adj.indexOf(cur_char) == 1
                # index 1 in the adjacency means the key is shifted,
                # 0 means unshifted: A vs a, % vs 5, etc.
                # for example, 'q' is adjacent to the entry '2@'.
                # @ is shifted w/ index 1, 2 is unshifted.
                shifted_count += 1
              if last_direction != found_direction
                # adding a turn is correct even in the initial case when last_direction is null:
                # every spatial pattern starts with a turn.
                turns += 1
                last_direction = found_direction
              break
        # if the current pattern continued, extend j and try to grow again
        if found
          j += 1
        # otherwise push the pattern discovered so far, if any...
        else
          if j - i > 2 # don't consider length 1 or 2 chains.
            matches.push
              pattern: 'spatial'
              i: i
              j: j-1
              token: password[i...j]
              graph: graph_name
              turns: turns
              shifted_count: shifted_count
          # ...and then start a new search for the rest of the password.
          i = j
          break
    matches

  #-------------------------------------------------------------------------------
  # repeats (aaa, abcabcabc) and sequences (abcdef) ------------------------------
  #-------------------------------------------------------------------------------

  repeat_match: (password) ->
    matches = []
    greedy = /(.+)\1+/g
    lazy = /(.+?)\1+/g
    lazy_anchored = /^(.+?)\1+$/
    lastIndex = 0
    while lastIndex < password.length
      greedy.lastIndex = lazy.lastIndex = lastIndex
      greedy_match = greedy.exec password
      lazy_match = lazy.exec password
      break unless greedy_match?
      if greedy_match[0].length > lazy_match[0].length
        # greedy beats lazy for 'aabaab'
        #   greedy: [aabaab, aab]
        #   lazy:   [aa,     a]
        match = greedy_match
        # greedy's repeated string might itself be repeated, eg.
        # aabaab in aabaabaabaab.
        # run an anchored lazy match on greedy's repeated string
        # to find the shortest repeated string
        base_token = lazy_anchored.exec(match[0])[1]
      else
        # lazy beats greedy for 'aaaaa'
        #   greedy: [aaaa,  aa]
        #   lazy:   [aaaaa, a]
        match = lazy_match
        base_token = match[1]
      [i, j] = [match.index, match.index + match[0].length - 1]
      # recursively match and score the base string
      base_analysis = scoring.most_guessable_match_sequence(
        base_token
        @omnimatch base_token
      )
      base_matches = base_analysis.sequence
      base_guesses = base_analysis.guesses
      matches.push
        pattern: 'repeat'
        i: i
        j: j
        token: match[0]
        base_token: base_token
        base_guesses: base_guesses
        base_matches: base_matches
        repeat_count: match[0].length / base_token.length
      lastIndex = j + 1
    matches

  MAX_DELTA: 5
  sequence_match: (password) ->
    # Identifies sequences by looking for repeated differences in unicode codepoint.
    # this allows skipping, such as 9753, and also matches some extended unicode sequences
    # such as Greek and Cyrillic alphabets.
    #
    # for example, consider the input 'abcdb975zy'
    #
    # password: a   b   c   d   b    9   7   5   z   y
    # index:    0   1   2   3   4    5   6   7   8   9
    # delta:      1   1   1  -2  -41  -2  -2  69   1
    #
    # expected result:
    # [(i, j, delta), ...] = [(0, 3, 1), (5, 7, -2), (8, 9, 1)]

    return [] if password.length == 1

    update = (i, j, delta) =>
      if j - i > 1 or Math.abs(delta) == 1
        if 0 < Math.abs(delta) <= @MAX_DELTA
          token = password[i..j]
          if /^[a-z]+$/.test(token)
            sequence_name = 'lower'
            sequence_space = 26
          else if /^[A-Z]+$/.test(token)
            sequence_name = 'upper'
            sequence_space = 26
          else if /^\d+$/.test(token)
            sequence_name = 'digits'
            sequence_space = 10
          else
            # conservatively stick with roman alphabet size.
            # (this could be improved)
            sequence_name = 'unicode'
            sequence_space = 26
          result.push
            pattern: 'sequence'
            i: i
            j: j
            token: password[i..j]
            sequence_name: sequence_name
            sequence_space: sequence_space
            ascending: delta > 0

    result = []
    i = 0
    last_delta = null

    for k in [1...password.length]
      delta = password.charCodeAt(k) - password.charCodeAt(k - 1)
      unless last_delta?
        last_delta = delta
      continue if delta == last_delta
      j = k - 1
      update(i, j, last_delta)
      i = j
      last_delta = delta
    update(i, password.length - 1, last_delta)
    result

  #-------------------------------------------------------------------------------
  # regex matching ---------------------------------------------------------------
  #-------------------------------------------------------------------------------

  regex_match: (password, _regexen = REGEXEN) ->
    matches = []
    for name, regex of _regexen
      regex.lastIndex = 0 # keeps regex_match stateless
      while rx_match = regex.exec password
        token = rx_match[0]
        matches.push
          pattern: 'regex'
          token: token
          i: rx_match.index
          j: rx_match.index + rx_match[0].length - 1
          regex_name: name
          regex_match: rx_match
    @sorted matches

  #-------------------------------------------------------------------------------
  # date matching ----------------------------------------------------------------
  #-------------------------------------------------------------------------------

  date_match: (password) ->
    # a "date" is recognized as:
    #   any 3-tuple that starts or ends with a 2- or 4-digit year,
    #   with 2 or 0 separator chars (1.1.91 or 1191),
    #   maybe zero-padded (01-01-91 vs 1-1-91),
    #   a month between 1 and 12,
    #   a day between 1 and 31.
    #
    # note: this isn't true date parsing in that "feb 31st" is allowed,
    # this doesn't check for leap years, etc.
    #
    # recipe:
    # start with regex to find maybe-dates, then attempt to map the integers
    # onto month-day-year to filter the maybe-dates into dates.
    # finally, remove matches that are substrings of other matches to reduce noise.
    #
    # note: instead of using a lazy or greedy regex to find many dates over the full string,
    # this uses a ^...$ regex against every substring of the password -- less performant but leads
    # to every possible date match.
    matches = []
    maybe_date_no_separator = /^\d{4,8}$/
    maybe_date_with_separator = ///
      ^
      ( \d{1,4} )    # day, month, year
      ( [\s/\\_.-] ) # separator
      ( \d{1,2} )    # day, month
      \2             # same separator
      ( \d{1,4} )    # day, month, year
      $
    ///

    # dates without separators are between length 4 '1191' and 8 '11111991'
    for i in [0..password.length - 4]
      for j in [i + 3..i + 7]
        break if j >= password.length
        token = password[i..j]
        continue unless maybe_date_no_separator.exec token
        candidates = []
        for [k,l] in DATE_SPLITS[token.length]
          dmy = @map_ints_to_dmy [
            parseInt token[0...k]
            parseInt token[k...l]
            parseInt token[l...]
          ]
          candidates.push dmy if dmy?
        continue unless candidates.length > 0
        # at this point: different possible dmy mappings for the same i,j substring.
        # match the candidate date that likely takes the fewest guesses: a year closest to 2000.
        # (scoring.REFERENCE_YEAR).
        #
        # ie, considering '111504', prefer 11-15-04 to 1-1-1504
        # (interpreting '04' as 2004)
        best_candidate = candidates[0]
        metric = (candidate) -> Math.abs candidate.year - scoring.REFERENCE_YEAR
        min_distance = metric candidates[0]
        for candidate in candidates[1..]
          distance = metric candidate
          if distance < min_distance
            [best_candidate, min_distance] = [candidate, distance]
        matches.push
          pattern: 'date'
          token: token
          i: i
          j: j
          separator: ''
          year: best_candidate.year
          month: best_candidate.month
          day: best_candidate.day

    # dates with separators are between length 6 '1/1/91' and 10 '11/11/1991'
    for i in [0..password.length - 6]
      for j in [i + 5..i + 9]
        break if j >= password.length
        token = password[i..j]
        rx_match = maybe_date_with_separator.exec token
        continue unless rx_match?
        dmy = @map_ints_to_dmy [
          parseInt rx_match[1]
          parseInt rx_match[3]
          parseInt rx_match[4]
        ]
        continue unless dmy?
        matches.push
          pattern: 'date'
          token: token
          i: i
          j: j
          separator: rx_match[2]
          year: dmy.year
          month: dmy.month
          day: dmy.day

    # matches now contains all valid date strings in a way that is tricky to capture
    # with regexes only. while thorough, it will contain some unintuitive noise:
    #
    # '2015_06_04', in addition to matching 2015_06_04, will also contain
    # 5(!) other date matches: 15_06_04, 5_06_04, ..., even 2015 (matched as 5/1/2020)
    #
    # to reduce noise, remove date matches that are strict substrings of others
    @sorted matches.filter (match) ->
      is_submatch = false
      for other_match in matches
        continue if match is other_match
        if other_match.i <= match.i and other_match.j >= match.j
          is_submatch = true
          break
      not is_submatch

  map_ints_to_dmy: (ints) ->
    # given a 3-tuple, discard if:
    #   middle int is over 31 (for all dmy formats, years are never allowed in the middle)
    #   middle int is zero
    #   any int is over the max allowable year
    #   any int is over two digits but under the min allowable year
    #   2 ints are over 31, the max allowable day
    #   2 ints are zero
    #   all ints are over 12, the max allowable month
    return if ints[1] > 31 or ints[1] <= 0
    over_12 = 0
    over_31 = 0
    under_1 = 0
    for int in ints
      return if 99 < int < DATE_MIN_YEAR or int > DATE_MAX_YEAR
      over_31 += 1 if int > 31
      over_12 += 1 if int > 12
      under_1 += 1 if int <= 0
    return if over_31 >= 2 or over_12 == 3 or under_1 >= 2

    # first look for a four digit year: yyyy + daymonth or daymonth + yyyy
    possible_year_splits = [
      [ints[2], ints[0..1]] # year last
      [ints[0], ints[1..2]] # year first
    ]
    for [y, rest] in possible_year_splits
      if DATE_MIN_YEAR <= y <= DATE_MAX_YEAR
        dm = @map_ints_to_dm rest
        if dm?
          return {
            year: y
            month: dm.month
            day: dm.day
          }
        else
          # for a candidate that includes a four-digit year,
          # when the remaining ints don't match to a day and month,
          # it is not a date.
          return

    # given no four-digit year, two digit years are the most flexible int to match, so
    # try to parse a day-month out of ints[0..1] or ints[1..0]
    for [y, rest] in possible_year_splits
      dm = @map_ints_to_dm rest
      if dm?
        y = @two_to_four_digit_year y
        return {
          year: y
          month: dm.month
          day: dm.day
        }

  map_ints_to_dm: (ints) ->
    for [d, m] in [ints, ints.slice().reverse()]
      if 1 <= d <= 31 and 1 <= m <= 12
        return {
          day: d
          month: m
        }

  two_to_four_digit_year: (year) ->
    if year > 99
      year
    else if year > 50
      # 87 -> 1987
      year + 1900
    else
      # 15 -> 2015
      year + 2000

module.exports = matching
