
build_ranked_dict = (unranked_list) ->
  result = {}
  i = 1 # rank starts at 1, not 0
  for word in unranked_list
    result[word] = i
    i += 1
  result

ranked_words = build_ranked_dict(word_rank_lookup)
ranked_surnames = build_ranked_dict(surnames)
ranked_male_names = build_ranked_dict(male_first)
ranked_female_names = build_ranked_dict(female_first)

spatial_match = (password) ->
  best = []
  best_coverage = 0
  best_graph_name = null
  for graph_name in ['qwerty', 'dvorak', 'keypad', 'mac_keypad']
    candidate = spatial_match_helper(password, graph_name, unidirectional=false)
    candidate_coverage = 0
    candidate_coverage += match.token.length for match in candidate
    if candidate_coverage > best_coverage or (candidate_coverage == best_coverage and candidate.length < best.length)
      best = candidate
      best_coverage = candidate_coverage
      best_graph_name = graph_name
  if best.length
    unidirectional_best = spatial_match_helper(password, best_graph_name, unidirectional=true)
    best.concat unidirectional_best
  else
    []

spatial_match_helper = (password, graph_name, unidirectional) ->
  result = []
  graph = window[graph_name]
  i = 0
  while i < password.length
    j = i + 1
    match_direction = -1
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
          if match_direction == -1
            match_direction = found_direction
      if found and (not unidirectional or found_direction == match_direction)
        j += 1
      else
        if j - i > 1
          result.push
            pattern: 'spatial'
            ij: [i, j-1]
            token: password[i...j]
            graph: graph_name
            unidirectional: unidirectional
        break
    i = j
  result

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
        if j - i > 1
          result.push
            pattern: 'repeat'
            ij: [i, j-1]
            token: password[i...j]
            repeated_char: password[i]
        break
    i = j
  result

sequences =
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
    for seq_candidate_name in ['lower', 'upper', 'digits']
      seq_candidate = sequences[seq_candidate_name]
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
          if j - i > 1
            result.push
              pattern: 'sequence'
              ij: [i, j-1]
              token: password[i...j]
              sequence_name: seq_name
              sequence_space: seq.length
          break
    i = j
  result

# console.log sequence_match('abccdefg71234567')
# console.log repeat_match('aaaBBBB77773737cccc')
# console.log spatial_match('qwertgfdsazxcvbnm,lp-=]\\')

build_dict_matcher = (dict_name, ranked_dict) ->
  (password) ->
    console.log password
    matches = max_coverage_subset dictionary_match(password, ranked_dict)
    match.dictionary_name = dict_name for match in matches
    matches

word_match = build_dict_matcher('words', ranked_words)
surname_match = build_dict_matcher('surnames', ranked_surnames)
male_name_match = build_dict_matcher('male_names', ranked_male_names)
female_name_match = build_dict_matcher('female_names', ranked_female_names)

h4x0r_table =
  a: ['4', '@']
  b: ['8']
  c: ['(', '{', '[', '<']
  e: ['3']
  g: ['6', '9', '&']
  i: ['1', '!', '|']
  l: ['1', '|', '7']
  o: ['0']
  s: ['$', '5']
  t: ['+', '7']
  x: ['%']
  z: ['2']

# makes a pruned copy of h4x0r_table that only includes the substitutions that occur in password
relevent_h4x0r_subtable = (password) ->
  password_chars = {}
  for chr in password
    password_chars[chr] = true
  filtered = {}
  for letter, subs of h4x0r_table
    relevent_subs = (sub for sub in subs when sub of password_chars)
    if relevent_subs.length > 0
      filtered[letter] = relevent_subs
  filtered

# for a given password, returns a list of possible 1337 replacement dictionaries
enumerate_h4x0r_subs = (table) ->
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
    for h4x_chr in table[first_key]
      for sub in subs
        dup_h4x_index = -1
        for i in [0...sub.length]
          if sub[i][0] == h4x_chr
            dup_h4x_index = i
            break
        if dup_h4x_index == -1
          sub_extension = sub.concat [[h4x_chr, first_key]]
          next_subs.push sub_extension
        else
          sub_alternative = sub.slice(0)
          sub_alternative.splice(dup_h4x_index, 1)
          sub_alternative.push [h4x_chr, first_key]
          next_subs.push sub
          next_subs.push sub_alternative
    subs = dedup next_subs
    helper(rest_keys)
  helper(keys)
  sub_dicts = [] # convert from assoc lists to dicts
  for sub in subs
    sub_dict = {}
    for [h4x_chr, chr] in sub
      sub_dict[h4x_chr] = chr
    sub_dicts.push sub_dict
  sub_dicts

h4x0r_sub = (password, sub) -> (sub[chr] or chr for chr in password).join('')

password = 'danwheeler1990'

h4x0r_match = (password) ->
  best = []
  best_sub = null
  best_coverage = 0
  for sub in enumerate_h4x0r_subs relevent_h4x0r_subtable(password)
    candidates = (matcher h4x0r_sub(password, sub) for matcher in [word_match, surname_match, female_name_match, male_name_match])
    for candidate in candidates
      coverage = 0
      coverage += match.token.length for match in candidate
      if coverage > best_coverage or (coverage == best_coverage and candidate.length < best.length)
        best = candidate
        best_sub = sub
        best_coverage = coverage
  for match in best
    [i,j] = match.ij
    match.token = password[i..j]
    match.h4x0rd = true
    match.sub = sub
  best

year_match = (password) ->
  1

digit_match = (password) ->
  1

# date match

###
# returns a list of objects for every substring of password that is a member of dictionary.
#
# ranked_dict must be an object mapping a word to its frequency rank.
###
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
          ij: [i, j]
          token: password[i..j]
          matched_word: word
          rank: rank
        )
  result

max_coverage_subset = (matches) ->
  best_chain = []
  best_coverage = 0
  decoder = (chain, rest) ->
    min_j = Math.min.apply(null, (match.ij[1] for match in rest))
    for next in rest when next.ij[0] <= min_j
      next_chain = chain.concat [next]
      next_rest = (match for match in rest when match.ij[0] > next.ij[1])
      coverage = 0
      coverage += match.token.length for match in next_chain
      if coverage > best_coverage or (coverage == best_coverage and next_chain.length < best_chain.length)
        best_coverage = coverage
        best_chain = next_chain
      decoder(next_chain, next_rest)
  decoder([], matches)
  best_chain

# start = new Date().getTime()
# console.log word_match('correcthorsebatterystaplecorrecthorsebattery')
# console.log(new Date().getTime() - start)

start = new Date().getTime()
console.log female_name_match password
end = new Date().getTime()
console.log end - start

# subs = enumerate_h4x0r_subs(relevent_h4x0r_subtable(password))
# for sub in subs
#   console.log word_match(h4x0r_sub(password, sub))
