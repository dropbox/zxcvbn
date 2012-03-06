
nPk = (n, k) ->
  result = 1
  result *= m for m in [n-k+1..n]
  result

nCk = (n, k) ->
  k_fact = 1
  k_fact *= m for m in [1..k]
  nPk(n, k) / k_fact

log2 = (n) -> Math.log(n) / Math.log(2)

# ------------------------------------------------------------------------------
# minimum entropy search: takes a big list of overlapping matches, returns the
# non-overlapping sublist with minimum entropy. O(N^2) dp alg.
# ------------------------------------------------------------------------------

GUESS_RATE_PER_SECOND = 1000

minimum_entropy_match_sequence = (password, matches) ->
  bruteforce_cardinality = calc_bruteforce_cardinality password
  up_to_k = []
  backpointers = []
  k = 0
  while k < password.length
    prev_entropy = up_to_k[k-1] or 0
    up_to_k[k] = prev_entropy + log2 bruteforce_cardinality # worst-case scenario to beat
    backpointers[k] = null
    for match in matches
      [i, j] = [match.i, match.j]
      if i > k
        break
      if j > k
        continue
      candidate_entropy = (up_to_k[i-1] or 0) + calc_entropy(match)
      if candidate_entropy < up_to_k[j]
        up_to_k[j] = candidate_entropy
        backpointers[j] = match
    k += 1

  # walk backwards and decode
  k = password.length - 1
  min_match = []
  min_entropy = up_to_k[k]
  while k > 0
    match = backpointers[k]
    if match
      min_match.push match
      k = match.i - 1
    else
      k -= 1
  min_match.reverse()

  # fill in the blanks between matches with bruteforce matches
  start_i = 0
  augmented = []
  for match in min_match
    [i, j] = [match.i, match.j]
    if i - start_i > 0
      augmented.push
        pattern: 'bruteforce'
        i: start_i # the start of the gap.
        j: i - 1   # ends one before the start of the following match.
        token: password[start_i...i]
        cardinality: bruteforce_cardinality
    start_i = j + 1
    augmented.push match

  if start_i < password.length
    augmented.push
      pattern: 'bruteforce'
      i: start_i
      j: password.length - 1
      token: password[start_i...password.length]
      cardinality: bruteforce_cardinality

  min_match = augmented

  password: password
  crack_time: display_info(Math.pow(2, min_entropy) * (1 / GUESS_RATE_PER_SECOND))
  min_entropy: Math.round(min_entropy)
  min_match: min_match

# ------------------------------------------------------------------------------
# entropy calcs -- one function per match pattern ------------------------------
# ------------------------------------------------------------------------------

calc_entropy = (match) ->
  return match.entropy if match.entropy?
  match.entropy = switch match.pattern
    when 'repeat'     then repeat_entropy     match
    when 'sequence'   then sequence_entropy   match
    when 'digits'     then digits_entropy     match
    when 'year'       then year_entropy       match
    when 'date'       then date_entropy       match
    when 'spatial'    then spatial_entropy    match
    when 'dictionary' then dictionary_entropy match

repeat_entropy = (match) ->
  cardinality = calc_bruteforce_cardinality match.token
  log2 (cardinality * match.token.length)

sequence_entropy = (match) ->
  first_chr = match.token[0]
  if first_chr in ['a' or '1']
    base_entropy = 1
  else
    if first_chr.match /\d/
      base_entropy = log2(10) # digits
    else if first_chr.match /[a-z]/
      base_entropy = log2(26) # lower
    else
      base_entropy = log2(26) + 1 # extra bit for uppercase
  if not match.ascending
    base_entropy += 1 # extra bit for descending instead of ascending
  base_entropy + log2 match.token.length

digits_entropy = (match) -> log2 Math.pow(10, match.token.length)

NUM_YEARS = 119 # years match against 1900 - 2019
NUM_MONTHS = 12
NUM_DAYS = 31

year_entropy = (match) -> log2 NUM_YEARS

date_entropy = (match) ->
  if match.year < 100
    entropy = log2(NUM_DAYS * NUM_MONTHS * 100) # two-digit year
  else
    entropy = log2(NUM_DAYS * NUM_MONTHS * NUM_YEARS) # four-digit year
  if match.separator
    entropy += 2 # add two bits for separator selection [/,-,.,etc]
  entropy

KEYBOARD_BRANCHING = 6
KEYBOARD_SIZE = 47
KEYPAD_BRANCHING = 9
KEYPAD_SIZE = 15

spatial_entropy = (match) ->
  if match.graph in ['qwerty', 'dvorak']
    start_choices = KEYBOARD_SIZE
    branching = KEYBOARD_BRANCHING
  else
    start_choices = KEYPAD_SIZE
    branching = KEYPAD_BRANCHING
  entropy = log2(start_choices * match.token.length)
  if match.turns > 0
    possible_turn_points = match.token.length - 1
    possible_turn_seqs = nCk(possible_turn_points, match.turns)
    entropy += log2(branching * possible_turn_seqs)
  entropy

dictionary_entropy = (match) ->
  entropy = log2 match.rank
  if match.token.match /^[A-Z][^A-Z]+$/
    entropy += 1 # capitalized word is most common capitalization scheme
  else if match.token.match /^[^A-Z]+[A-Z]$/
    entropy += 2 # then end-capitalized
  else if match.token.match /^[^a-z]+$/
    entropy += 2 # or all-caps
  else if match.token.match /^[^a-z]+[^A-Z]+[^a-z]$/
    entropy += 2 # or capitalized + end-capitalized
  else if not match.token.match /^[^A-Z]+$/
    num_alpha = (chr for chr in match.token when chr.match /[A-Za-z]/).length
    num_upper = (chr for chr in match.token when chr.match /[A-Z]/).length
    entropy += log2 nCk(num_alpha, num_upper)
  if match.l33t
    sub_chrs = (v for k,v of match.sub)
    l33t_chrs = (k for k,v of match.sub)
    num_possibles = (chr for chr in match.token when chr in sub_chrs.concat l33t_chrs).length
    num_l33t = (chr for chr in match.token when chr in l33t_chrs).length
    entropy += log2 nCk(num_possibles, num_l33t)
  entropy

bruteforce_entropy = (match) ->
  log2 Math.pow(match.cardinality, match.token.length)

# utilities --------------------------------------------------------------------

calc_bruteforce_cardinality = (password) ->
  [lower, upper, digits, symbols] = [false, false, false, false]
  for chr in password
    ord = chr.charCodeAt(0)
    if 0x30 <= ord <= 0x39
      digits = true
    else if 0x41 <= ord <= 0x5a
      upper = true
    else if 0x61 <= ord <= 0x7a
      lower = true
    else
      symbols = true
  cardinality = 0
  if digits
    cardinality += 10
  if upper
    cardinality += 26
  if lower
    cardinality += 26
  if symbols
    cardinality += 33
  cardinality

display_info = (seconds) ->
  minute = 60
  hour = minute * 60
  day = hour * 24
  month = day * 31
  year = month * 12
  century = year * 100
  if seconds < minute
    quality: 0
    display: 'instant'
  else if seconds < hour
    quality: 1
    display: "#{1 + Math.ceil(seconds / minute)} minutes"
  else if seconds < day
    quality: 1 # no quality change
    display: "#{1 + Math.ceil(seconds / hour)} hours"
  else if seconds < month
    quality: 2
    display: "#{1 + Math.ceil(seconds / day)} days"
  else if seconds < year
    quality: 3
    display: "#{1 + Math.ceil(seconds / month)} months"
  else if seconds < century
    quality: 4
    display: "#{1 + Math.ceil(seconds / year)} years"
  else
    quality: 5
    display: 'centuries'
