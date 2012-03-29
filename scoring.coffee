
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
# minimum entropy search -------------------------------------------------------
# ------------------------------------------------------------------------------
#
# takes a list of overlapping matches, returns the non-overlapping sublist with
# minimum entropy. O(nm) dp alg for length-n password with m candidate matches.
# ------------------------------------------------------------------------------

minimum_entropy_match_sequence = (password, matches) ->
  bruteforce_cardinality = calc_bruteforce_cardinality password # e.g. 26 for lowercase
  up_to_k = []      # minimum entropy up to k.
  backpointers = [] # for the optimal sequence of matches up to k, holds the final match (match.j == k). null means the sequence ends w/ a brute-force character.
  for k in [0...password.length]
    # starting scenario to try and beat: adding a brute-force character to the minimum entropy sequence at k-1.
    up_to_k[k] = (up_to_k[k-1] or 0) + log2 bruteforce_cardinality
    backpointers[k] = null
    for match in matches when match.j == k
      [i, j] = [match.i, match.j]
      candidate_entropy = (up_to_k[i-1] or 0) + calc_entropy(match)
      if candidate_entropy < up_to_k[j]
        up_to_k[j] = candidate_entropy
        backpointers[j] = match

  # walk backwards and decode the best sequence
  match_sequence = []
  k = password.length - 1
  while k > 0
    match = backpointers[k]
    if match
      match_sequence.push match
      k = match.i - 1
    else
      k -= 1
  match_sequence.reverse()

  # fill in the blanks between pattern matches with bruteforce "matches"
  # that way the match sequence fully covers the password: match1.j == match2.i - 1 for every adjacent match1,match2.
  make_bruteforce_match = (i, j) ->
    pattern: 'bruteforce'
    i: i
    j: j
    token: password[i..j]
    cardinality: bruteforce_cardinality
    display: "bruteforce-with-#{bruteforce_cardinality}-cardinality"
  k = 0
  match_sequence_copy = []
  for match in match_sequence
    [i, j] = [match.i, match.j]
    if i - k > 0
      match_sequence_copy.push make_bruteforce_match(k, i - 1)
    k = j + 1
    match_sequence_copy.push match
  if k < password.length
    match_sequence_copy.push make_bruteforce_match(k, password.length - 1)
  match_sequence = match_sequence_copy

  min_entropy = up_to_k[password.length - 1]
  crack_time = entropy_to_crack_time min_entropy

  # final result object
  entropy: Math.round min_entropy
  match_sequence: match_sequence
  crack_time: crack_time
  crack_time_display: display_time crack_time

# ------------------------------------------------------------------------------
# threat model -- stolen hash catastrophe scenario -----------------------------
# ------------------------------------------------------------------------------
#
# assumes:
# * passwords are stored as salted hashes, different random salt per user.
#   (making rainbow attacks infeasable.)
# * hashes and salts were stolen. attacker is guessing passwords at max rate.
# * attacker has several CPUs at their disposal.
# ------------------------------------------------------------------------------

# about 10 ms per guess for bcrypt/scrypt/PBKDF2 with an appropriate work factor.
# adjust accordingly if you use another hash function, possibly by
# several orders of magnitude!
SINGLE_GUESS = .010
NUM_ATTACKERS = 100 # number of cores guessing in parallel.

SECONDS_PER_GUESS = SINGLE_GUESS / NUM_ATTACKERS

entropy_to_crack_time = (entropy) -> .5 * Math.pow(2, entropy) * SECONDS_PER_GUESS # average, not total

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

spatial_entropy = (match) ->
  if match.graph in ['qwerty', 'dvorak']
    start_positions = KEYBOARD_STARTING_POSITIONS
    degree = KEYBOARD_AVERAGE_DEGREE
  else
    start_positions = KEYBOARD_STARTING_POSITIONS
    degree = KEYPAD_AVERAGE_DEGREE
  entropy = log2(start_positions * match.token.length)
  if match.turns > 0
    possible_turn_points = match.token.length - 1
    possible_turn_seqs = nCk(possible_turn_points, match.turns)
    entropy += log2(degree * possible_turn_seqs)
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

display_time = (seconds) ->
  minute = 60
  hour = minute * 60
  day = hour * 24
  month = day * 31
  year = month * 12
  century = year * 100
  if seconds < minute
    'instant'
  else if seconds < hour
    "#{1 + Math.ceil(seconds / minute)} minutes"
  else if seconds < day
    "#{1 + Math.ceil(seconds / hour)} hours"
  else if seconds < month
    "#{1 + Math.ceil(seconds / day)} days"
  else if seconds < year
    "#{1 + Math.ceil(seconds / month)} months"
  else if seconds < century
    "#{1 + Math.ceil(seconds / year)} years"
  else
    'centuries'
