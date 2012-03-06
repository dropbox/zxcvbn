
empty = (obj) -> (k for k of obj).length == 0
extend = (lst, lst2) -> lst.push.apply lst, lst2
translate = (string, chr_map) -> (chr_map[chr] or chr for chr in string).join('')

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
    match.display = "dictionary-#{dict_name}-rank-#{match.rank}" for match in matches
    matches

ranked_english      = build_ranked_dict(english)
ranked_surnames     = build_ranked_dict(surnames)
ranked_male_names   = build_ranked_dict(male_names)
ranked_female_names = build_ranked_dict(female_names)
ranked_passwords    = build_ranked_dict(passwords)

english_match     = build_dict_matcher('words', ranked_english)
surname_match     = build_dict_matcher('surnames', ranked_surnames)
male_name_match   = build_dict_matcher('male_names', ranked_male_names)
female_name_match = build_dict_matcher('female_names', ranked_female_names)
password_match    = build_dict_matcher('passwords', ranked_passwords)

#-------------------------------------------------------------------------------
# dictionary match with common substitutions (pr0d@dmin instead of prodadmin) --
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
  for chr in password
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
    if not keys.length
      return
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
    if empty sub
      break # corner case: password has no relevent subs.
    for matcher in DICTIONARY_MATCHERS
      subbed_password = translate password, sub
      for match in matcher(subbed_password)
        token = password[match.i..match.j]
        if token.toLowerCase() == match.matched_word
          # only return the matches that contain an actual substitution
          continue
        match.l33t = true
        match.token = token
        match.sub = sub
        matches.push match
  matches

# ------------------------------------------------------------------------------
# spatial match (qwerty/dvorak/keypad) -----------------------------------------
# ------------------------------------------------------------------------------

GRAPHS =
  'qwerty': qwerty
  'dvorak': dvorak
  'keypad': keypad
  'mac_keypad': mac_keypad

spatial_match = (password) ->
  matches = []
  for graph_name, graph of GRAPHS
    extend matches, spatial_match_helper(password, graph, graph_name)
  matches

spatial_match_helper = (password, graph, graph_name) ->
  result = []
  i = 0
  while i < password.length
    j = i + 1
    last_direction = null
    turns = 0
    loop
      [prev_char, cur_char] = password[j-1..j]
      found = false
      found_direction = -1
      cur_direction = -1
      adjacents = graph[prev_char] or []
      for adj in adjacents
        cur_direction += 1
        if adj and cur_char in adj
          found = true
          found_direction = cur_direction
          if last_direction != found_direction
            # correct even in the initial case when last_dir is null:
            # every spatial pattern starts with a turn.
            turns += 1
            last_direction = found_direction
          break
      if found
        j += 1
      else
        if j - i > 2 # only consider length-3 chains and up
          result.push
            pattern: 'spatial'
            i: i
            j: j-1
            token: password[i...j]
            graph: graph_name
            turns: turns
            display: "spatial-#{graph_name}-#{turns}turns"
        break
    i = j
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
      if password[j-1] == password[j]
        j += 1
      else
        if j - i > 2 # length-3 chains and up
          result.push
            pattern: 'repeat'
            i: i
            j: j-1
            token: password[i...j]
            repeated_char: password[i]
            display: "repeat-#{password[i]}"
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
      [i_n, j_n] = (seq_candidate.indexOf(chr) for chr in [password[i], password[j]])
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
          if j - i > 2 # length-3 chains and up
            result.push
              pattern: 'sequence'
              i: i
              j: j-1
              token: password[i...j]
              sequence_name: seq_name
              sequence_space: seq.length
              ascending: seq_direction  == 1
              display: "sequence-#{seq_name}"
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
    if not match
      break
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
    display: "#{j-i+1}-digits"

year_rx = /19\d\d|200\d|201\d/ # 4-digit years only. 2-digit years have the same entropy as 2-digit brute force.
year_match = (password) ->
  for match in findall password, year_rx
    [i, j] = [match.i, match.j]
    pattern: 'year'
    i: i
    j: j
    token: password[i..j]
    display: 'year'

date_rx = /(\d{1,2})( |-|\/|\.|_)?(\d{1,2}?)\2?(19\d{2}|200\d|201\d|\d{2})/
date_match = (password) ->
  matches = []
  for match in findall password, date_rx
    if match[0].length <= 4
      continue # because brute-forcing 4-digit numbers is faster than brute-forcing dates
    [day, month, year] = (parseInt(match[k]) for k in [1,3,4])
    separator = match[2] or ''
    if 12 <= month <= 31 and day <= 12
      [day, month] = [month, day]
    if day > 31 or month > 12
      continue
    matches.push
      pattern: 'date'
      i: match.i
      j: match.j
      token: password[match.i..match.j]
      separator: separator
      day: day
      month: month
      year: year
      display: 'date'
  matches

#-------------------------------------------------------------------------------
# matcher lists ----------------------------------------------------------------
#-------------------------------------------------------------------------------

DICTIONARY_MATCHERS = [
    password_match, male_name_match, female_name_match, surname_match, english_match
]

MATCHERS = DICTIONARY_MATCHERS.concat [
    l33t_match,
    digits_match, year_match, date_match,
    repeat_match, sequence_match,
    spatial_match
]
