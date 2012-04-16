
empty = (obj) -> (k for k of obj).length == 0
extend = (lst, lst2) -> lst.push.apply lst, lst2
translate = (string, chr_map) -> (chr_map[chr] or chr for chr in string.split('')).join('')

# ------------------------------------------------------------------------------
# omnimatch -- combine everything ----------------------------------------------
# ------------------------------------------------------------------------------

omnimatch = (password) ->
  matches = []
  for matcher in MATCHERS
    extend matches, matcher(password)
  matches.sort (match1, match2) ->
    (match1.i - match2.i) or (match1.j - match2.j)

#-------------------------------------------------------------------------------
# dictionary match (common passwords, english, last names, etc) ----------------
#-------------------------------------------------------------------------------

dictionary_match = (password, ranked_dict) ->
  result = []
  len = password.length
  password_lower = password.toLowerCase()
  for i in [0...len]
    for j in [i...len]
      if password_lower[i..j] of ranked_dict
        word = password_lower[i..j]
        rank = ranked_dict[word]
        result.push(
          pattern: 'dictionary'
          i: i
          j: j
          token: password[i..j]
          matched_word: word
          rank: rank
        )
  result

build_ranked_dict = (unranked_list) ->
  result = {}
  i = 1 # rank starts at 1, not 0
  for word in unranked_list
    result[word] = i
    i += 1
  result

build_dict_matcher = (dict_name, ranked_dict) ->
  (password) ->
    matches = dictionary_match(password, ranked_dict)
    match.dictionary_name = dict_name for match in matches
    matches

#-------------------------------------------------------------------------------
# dictionary match with common l33t substitutions ------------------------------
#-------------------------------------------------------------------------------

l33t_table =
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

# makes a pruned copy of l33t_table that only includes password's possible substitutions
relevent_l33t_subtable = (password) ->
  password_chars = {}
  for chr in password.split('')
    password_chars[chr] = true
  filtered = {}
  for letter, subs of l33t_table
    relevent_subs = (sub for sub in subs when sub of password_chars)
    if relevent_subs.length > 0
      filtered[letter] = relevent_subs
  filtered

# returns the list of possible 1337 replacement dictionaries for a given password
enumerate_l33t_subs = (table) ->
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

l33t_match = (password) ->
  matches = []
  for sub in enumerate_l33t_subs relevent_l33t_subtable password
    break if empty sub # corner case: password has no relevent subs.
    for matcher in DICTIONARY_MATCHERS
      subbed_password = translate password, sub
      for match in matcher(subbed_password)
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
  matches

# ------------------------------------------------------------------------------
# spatial match (qwerty/dvorak/keypad) -----------------------------------------
# ------------------------------------------------------------------------------

spatial_match = (password) ->
  matches = []
  for graph_name, graph of GRAPHS
    extend matches, spatial_match_helper(password, graph, graph_name)
  matches

spatial_match_helper = (password, graph, graph_name) ->
  result = []
  i = 0
  while i < password.length - 1
    j = i + 1
    last_direction = null
    turns = 0
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
              # index 1 in the adjacency means the key is shifted, 0 means unshifted: A vs a, % vs 5, etc.
              # for example, 'q' is adjacent to the entry '2@'. @ is shifted w/ index 1, 2 is unshifted.
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
          result.push
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
  result

#-------------------------------------------------------------------------------
# repeats (aaa) and sequences (abcdef) -----------------------------------------
#-------------------------------------------------------------------------------

repeat_match = (password) ->
  result = []
  i = 0
  while i < password.length
    j = i + 1
    loop
      [prev_char, cur_char] = password[j-1..j]
      if password.charAt(j-1) == password.charAt(j)
        j += 1
      else
        if j - i > 2 # don't consider length 1 or 2 chains.
          result.push
            pattern: 'repeat'
            i: i
            j: j-1
            token: password[i...j]
            repeated_char: password.charAt(i)
        break
    i = j
  result

SEQUENCES =
  lower: 'abcdefghijklmnopqrstuvwxyz'
  upper: 'ABCDEFGHIJKLMNOPQRSTUVWXYZ'
  digits: '01234567890'

sequence_match = (password) ->
  result = []
  i = 0
  while i < password.length
    j = i + 1
    seq = null # either lower, upper, or digits
    seq_name = null
    seq_direction = null # 1 for ascending seq abcd, -1 for dcba
    for seq_candidate_name, seq_candidate of SEQUENCES
      [i_n, j_n] = (seq_candidate.indexOf(chr) for chr in [password.charAt(i), password.charAt(j)])
      if i_n > -1 and j_n > -1
        direction = j_n - i_n
        if direction in [1, -1]
          seq = seq_candidate
          seq_name = seq_candidate_name
          seq_direction = direction
          break
    if seq
      loop
        [prev_char, cur_char] = password[j-1..j]
        [prev_n, cur_n] = (seq_candidate.indexOf(chr) for chr in [prev_char, cur_char])
        if cur_n - prev_n == seq_direction
          j += 1
        else
          if j - i > 2 # don't consider length 1 or 2 chains.
            result.push
              pattern: 'sequence'
              i: i
              j: j-1
              token: password[i...j]
              sequence_name: seq_name
              sequence_space: seq.length
              ascending: seq_direction  == 1
          break
    i = j
  result

#-------------------------------------------------------------------------------
# digits, years, dates ---------------------------------------------------------
#-------------------------------------------------------------------------------

repeat = (chr, n) -> (chr for i in [1..n]).join('')

findall = (password, rx) ->
  matches = []
  loop
    match = password.match rx
    break if not match
    match.i = match.index
    match.j = match.index + match[0].length - 1
    matches.push match
    password = password.replace match[0], repeat(' ', match[0].length)
  matches

digits_rx = /\d{3,}/
digits_match = (password) ->
  for match in findall password, digits_rx
    [i, j] = [match.i, match.j]
    pattern: 'digits'
    i: i
    j: j
    token: password[i..j]

# 4-digit years only. 2-digit years have the same entropy as 2-digit brute force.
year_rx = /19\d\d|200\d|201\d/
year_match = (password) ->
  for match in findall password, year_rx
    [i, j] = [match.i, match.j]
    pattern: 'year'
    i: i
    j: j
    token: password[i..j]

date_match = (password) ->
  # match dates with separators 1/1/1911 and dates without 111997
  date_without_sep_match(password).concat date_sep_match(password)

date_without_sep_match = (password) ->
  date_matches = []
  for digit_match in findall password, /\d{4,8}/ # 1197 is length-4, 01011997 is length 8
    [i, j] = [digit_match.i, digit_match.j]
    token = password[i..j]
    end = token.length
    candidates_round_1 = [] # parse year alternatives
    if token.length <= 6
      candidates_round_1.push # 2-digit year prefix
        daymonth: token[2..]
        year: token[0..1]
        i: i
        j: j
      candidates_round_1.push # 2-digit year suffix
        daymonth: token[0...end-2]
        year: token[end-2..]
        i: i
        j: j
    if token.length >= 6
      candidates_round_1.push # 4-digit year prefix
        daymonth: token[4..]
        year: token[0..3]
        i: i
        j: j
      candidates_round_1.push # 4-digit year suffix
        daymonth: token[0...end-4]
        year: token[end-4..]
        i: i
        j: j
    candidates_round_2 = [] # parse day/month alternatives
    for candidate in candidates_round_1
      switch candidate.daymonth.length
        when 2 # ex. 1 1 97
          candidates_round_2.push
            day: candidate.daymonth[0]
            month: candidate.daymonth[1]
            year: candidate.year
            i: candidate.i
            j: candidate.j
        when 3 # ex. 11 1 97 or 1 11 97
          candidates_round_2.push
            day: candidate.daymonth[0..1]
            month: candidate.daymonth[2]
            year: candidate.year
            i: candidate.i
            j: candidate.j
          candidates_round_2.push
            day: candidate.daymonth[0]
            month: candidate.daymonth[1..2]
            year: candidate.year
            i: candidate.i
            j: candidate.j
        when 4 # ex. 11 11 97
          candidates_round_2.push
            day: candidate.daymonth[0..1]
            month: candidate.daymonth[2..3]
            year: candidate.year
            i: candidate.i
            j: candidate.j
    # final loop: reject invalid dates
    for candidate in candidates_round_2
      day = parseInt(candidate.day)
      month = parseInt(candidate.month)
      year = parseInt(candidate.year)
      [valid, [day, month, year]] = check_date(day, month, year)
      continue unless valid
      date_matches.push
        pattern: 'date'
        i: candidate.i
        j: candidate.j
        token: password[i..j]
        separator: ''
        day: day
        month: month
        year: year
  date_matches

date_rx_year_suffix = ///
  ( \d{1,2} )                         # day or month
  ( \s | - | / | \\ | _ | \. )        # separator
  ( \d{1,2} )                         # month or day
  \2                                  # same separator
  ( 19\d{2} | 200\d | 201\d | \d{2} ) # year
///
date_rx_year_prefix = ///
  ( 19\d{2} | 200\d | 201\d | \d{2} ) # year
  ( \s | - | / | \\ | _ | \. )        # separator
  ( \d{1,2} )                         # day or month
  \2                                  # same separator
  ( \d{1,2} )                         # month or day
///
date_sep_match = (password) ->
  matches = []
  for match in findall password, date_rx_year_suffix
    [match.day, match.month, match.year] = (parseInt(match[k]) for k in [1,3,4])
    match.sep = match[2]
    matches.push match
  for match in findall password, date_rx_year_prefix
    [match.day, match.month, match.year] = (parseInt(match[k]) for k in [4,3,1])
    match.sep = match[2]
    matches.push match
  for match in matches
    [valid, [day, month, year]] = check_date(match.day, match.month, match.year)
    continue unless valid
    pattern: 'date'
    i: match.i
    j: match.j
    token: password[match.i..match.j]
    separator: match.sep
    day: day
    month: month
    year: year

check_date = (day, month, year) ->
  if 12 <= month <= 31 and day <= 12 # tolerate both day-month and month-day order
    [day, month] = [month, day]
  if day > 31 or month > 12
    return [false, []]
  unless 1900 <= year <= 2019
    return [false, []]
  [true, [day, month, year]]
