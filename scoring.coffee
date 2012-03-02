
log2 = (n) -> Math.log(n) / Math.log(2)

nPk = (n, k) ->
  result = 1
  result *= m for m in [n-k+1..n]
  result

nCk = (n, k) ->
  k_fact = 1
  k_fact *= m for m in [1..k]
  nPk(n, k) / k_fact

PRINTABLE_CHARS = 95
ALPHANUM_CHARS = 62
NUM_YEARS = 119 # years match against 1900 - 2019
NUM_MONTHS = 12
NUM_DAYS = 31

KEYBOARD_BRANCHING = 6
KEYBOARD_SIZE = 47
KEYPAD_BRANCHING = 9
KEYPAD_SIZE = 15

calc_entropy = (match) ->
  switch match.pattern
    when 'repeat'     then repeat_entropy     match
    when 'sequence'   then sequence_entropy   match
    when 'digits'     then digits_entropy     match
    when 'year'       then year_entropy       match
    when 'date'       then date_entropy       match
    when 'spatial'    then spatial_entropy    match
    when 'dictionary' then dictionary_entropy match
    when 'bruteforce' then bruteforce_entropy match

repeat_entropy = (match) -> log2 (PRINTABLE_CHARS * match.token.length)

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
  if match.h4x0rd
    sub_chrs = (v for k,v of match.sub)
    h4x_chrs = (k for k,v of match.sub)
    num_possibles = (chr for chr in match.token when chr in sub_chrs.concat h4x_chrs).length
    num_h4x = (chr for chr in match.token when chr in h4x_chrs).length
    entropy += log2 nCk(num_possibles, num_h4x)
  entropy

bruteforce_entropy = (match) ->
  log2 Math.pow(match.cardinality, match.token.length)

for match in bruteforce_match 'lKajsf2-2-198877'
  console.log match, calc_entropy(match)
