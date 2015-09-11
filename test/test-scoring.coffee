test = require 'tape'
scoring = require '../src/scoring'
matching = require '../src/matching'

lg = scoring.lg
nCk = scoring.nCk
EPSILON = 1e-10 # truncate to 10th decimal place
truncate_float = (float) -> Math.round(float / EPSILON) * EPSILON
approx_equal = (t, actual, expected, msg) ->
  t.equal truncate_float(actual), truncate_float(expected), msg

test 'nCk', (t) ->
  for [n, k, result] in [
    [ 0,  0, 1 ]
    [ 1,  0, 1 ]
    [ 5,  0, 1 ]
    [ 0,  1, 0 ]
    [ 0,  5, 0 ]
    [ 2,  1, 2 ]
    [ 4,  2, 6 ]
    [ 33, 7, 4272048 ]
    ]
    t.equal nCk(n, k), result, "nCk(#{n}, #{k}) == #{result}"
  n = 49
  k = 12
  t.equal nCk(n, k), nCk(n, n-k), "mirror identity"
  t.equal nCk(n, k), nCk(n-1, k-1) + nCk(n-1, k), "pascal's triangle identity"
  t.end()

test 'lg', (t) ->
  for [n, result] in [
    [ 1,  0 ]
    [ 2,  1 ]
    [ 4,  2 ]
    [ 32, 5 ]
    ]
    t.equal lg(n), result, "lg(#{n}) == #{result}"
  n = 17
  p = 4
  approx_equal t, lg(n * p), lg(n) + lg(p), "product rule"
  approx_equal t, lg(n / p), lg(n) - lg(p), "quotient rule"
  approx_equal t, lg(Math.E), 1 / Math.log(2), "base switch rule"
  approx_equal t, lg(Math.pow(n, p)), p * lg(n), "power rule"
  approx_equal t, lg(n), Math.log(n) / Math.log(2), "base change rule"
  t.end()

test 'entropy to crack time', (t) ->
  times = [e0, e1, e2, e3] = (scoring.entropy_to_crack_time(n) for n in [0,1,7,60])
  t.ok e0 < e1 < e2 < e3, "monotonically increasing"
  t.ok e > 0, "always positive" for e in times
  t.end()

test 'crack time to score', (t) ->
  for [seconds, score] in [
    [0,  0]
    [10, 0]
    [Math.pow(10, 9), 4]
    ]
    msg = "crack time of #{seconds} seconds has score of #{score}"
    t.equal scoring.crack_time_to_score(seconds), score, msg
  t.end()

test 'bruteforce cardinality', (t) ->
  for [str, cardinality] in [
    # beginning / middle / end of lowers range
    [ 'a', 26 ]
    [ 'h', 26 ]
    [ 'z', 26 ]
    # sample from each other character group
    [ 'Q', 26 ]
    [ '0', 10 ]
    [ '9', 10 ]
    [ '$', 33 ]
    [ '£', 64 ]
    [ 'å', 64 ]
    # unicode
    [ 'α', 40 ]
    [ 'αβ', 40 ]
    [ 'Ϫα', 58 ]
    [ '好', 40 ]
    [ '信息论', 100 ]
    # combinations
    [ 'a$', 59 ]
    [ 'aQ£', 116 ]
    [ '9Z9Z', 36 ]
    [ '«信息论»', 164 ]
    ]
    msg = "cardinality of #{str} is #{cardinality}"
    t.equal scoring.calc_bruteforce_cardinality(str), cardinality, msg
  t.end()

test 'display time', (t) ->
  for [seconds, display] in [
    [ 0, '0 seconds' ]
    [ 1, '1 second' ]
    [ 32, '32 seconds' ]
    [ 60, '1 minute' ]
    [ 121, '2 minutes' ]
    [ 3600, '1 hour' ]
    [ 2  * 3600 * 24 + 5, '2 days' ]
    [ 1  * 3600 * 24 * 31 + 4000, '1 month' ]
    [ 99 * 3600 * 24 * 31 * 12, '99 years' ]
    [ Math.pow(10, 10), 'centuries' ]
    ]
    msg = "#{seconds} seconds has a display time of #{display}"
    t.equal scoring.display_time(seconds), display, msg
  t.end()

test 'minimum entropy search', (t) ->
  m = (i, j, entropy) ->
    i: i
    j: j
    entropy: entropy
  password = '0123456789'
  cardinality = 10 # |digits| == 10

  msg = (s) -> "returns one bruteforce match given an empty match sequence: #{s}"
  result = scoring.minimum_entropy_match_sequence password, []
  t.equal result.match_sequence.length, 1, msg("result.length == 1")
  m0 = result.match_sequence[0]
  t.equal m0.pattern, 'bruteforce', msg("match.pattern == 'bruteforce'")
  t.equal m0.token, password, msg("match.token == #{password}")
  t.equal m0.cardinality, cardinality, msg("match.cardinality == #{cardinality}")
  expected = Math.round lg(Math.pow(cardinality, password.length))
  t.equal Math.round(result.entropy), expected, msg("total entropy == #{expected}")
  t.equal Math.round(m0.entropy), expected, msg("match entropy == #{expected}")
  t.deepEqual [m0.i, m0.j], [0, 9], msg("[i, j] == [#{m0.i}, #{m0.j}]")

  msg = (s) -> "returns match + bruteforce when match covers a prefix of password: #{s}"
  matches = [m0] = [m(0, 5, 1)]
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.match_sequence.length, 2, msg("result.match.sequence.length == 2")
  t.equal result.match_sequence[0], m0, msg("first match is the provided match object")
  m1 = result.match_sequence[1]
  t.equal m1.pattern, 'bruteforce', msg("second match is bruteforce")
  t.deepEqual [m1.i, m1.j], [6, 9], msg("second match covers full suffix after first match")

  msg = (s) -> "returns bruteforce + match when match covers a suffix: #{s}"
  matches = [m1] = [m(3, 9, 1)]
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.match_sequence.length, 2, msg("result.match.sequence.length == 2")
  m0 = result.match_sequence[0]
  t.equal m0.pattern, 'bruteforce', msg("first match is bruteforce")
  t.deepEqual [m0.i, m0.j], [0, 2], msg("first match covers full prefix before second match")
  t.equal result.match_sequence[1], m1, msg("second match is the provided match object")

  msg = (s) -> "returns bruteforce + match + bruteforce when match covers an infix: #{s}"
  matches = [m1] = [m(1, 8, 1)]
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.match_sequence.length, 3, msg("result.length == 3")
  t.equal result.match_sequence[1], m1, msg("middle match is the provided match object")
  m0 = result.match_sequence[0]
  m2 = result.match_sequence[2]
  t.equal m0.pattern, 'bruteforce', msg("first match is bruteforce")
  t.equal m2.pattern, 'bruteforce', msg("third match is bruteforce")
  t.deepEqual [m0.i, m0.j], [0, 0], msg("first match covers full prefix before second match")
  t.deepEqual [m2.i, m2.j], [9, 9], msg("third match covers full suffix after second match")

  msg = (s) -> "chooses lower-entropy match given two matches of the same span: #{s}"
  matches = [m0, m1] = [m(0, 9, 1), m(0, 9, 2)]
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.match_sequence.length, 1, msg("result.length == 1")
  t.equal result.match_sequence[0], m0, msg("result.match_sequence[0] == m0")
  # make sure ordering doesn't matter
  m0.entropy = 3
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.match_sequence.length, 1, msg("result.length == 1")
  t.equal result.match_sequence[0], m1, msg("result.match_sequence[0] == m1")

  msg = (s) -> "when m0 covers m1 and m2, choose [m0] when m0 < m1 + m2: #{s}"
  matches = [m0, m1, m2] = [m(0, 9, 1), m(0, 3, 1), m(4, 9, 1)]
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.entropy, 1, msg("total entropy == 1")
  t.deepEqual result.match_sequence, [m0], msg("match_sequence is [m0]")

  msg = (s) -> "when m0 covers m1 and m2, choose [m1, m2] when m0 > m1 + m2: #{s}"
  m0.entropy = 3
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.entropy, 2, msg("total entropy == 2")
  t.deepEqual result.match_sequence, [m1, m2], msg("match_sequence is [m1, m2]")
  t.end()

test 'calc_entropy', (t) ->
  match =
    entropy: 1
  t.equal scoring.calc_entropy(match), 1, "calc_entropy returns cached entropy when available"
  match =
    pattern: 'date'
    year: 1977
    month: 7
    day: 14
  msg = "calc_entropy delegates based on pattern"
  t.equal scoring.calc_entropy(match), scoring.date_entropy(match), msg
  t.end()

test 'repeat entropy', (t) ->
  for [token, entropy] in [
    [ 'aa',   lg(26 * 2) ]
    [ '999',  lg(10 * 3) ]
    [ '$$$$', lg(33 * 4) ]
    ]
    match = token: token
    msg = "the repeat pattern '#{token}' has entropy of #{entropy}"
    t.equal scoring.repeat_entropy(match), entropy, msg
  t.end()

test 'sequence entropy', (t) ->
  for [token, ascending, entropy] in [
    [ 'ab',   true,  2 + lg(2) ]
    [ 'XYZ',  true,  lg(26) + 1 + lg(3) ]
    [ '4567', true,  lg(10) + lg(4) ]
    [ '7654', false, lg(10) + lg(4) + 1 ]
    [ 'ZYX',  false, 2 + lg(3) + 1 ]
    ]
    match =
      token: token
      ascending: ascending
    msg = "the sequence pattern '#{token}' has entropy of #{entropy}"
    t.equal scoring.sequence_entropy(match), entropy, msg
  t.end()

test 'regex entropy', (t) ->
  match =
    token: 'aizocdk'
    regex_name: 'alpha_lower'
    regex_match: ['aizocdk']
  msg = "entropy of lg(26**7) for 7-char lowercase regex"
  t.equal scoring.regex_entropy(match), lg(Math.pow(26, 7)), msg

  match =
    token: 'ag7C8'
    regex_name: 'alphanumeric'
    regex_match: ['ag7C8']
  msg = "entropy of lg(62**5) for 5-char alphanumeric regex"
  t.equal scoring.regex_entropy(match), lg(Math.pow(2 * 26 + 10, 5)), msg

  match =
    token: '1972'
    regex_name: 'recent_year'
    regex_match: ['1972']
  msg = "entropy of |year - REFERENCE_YEAR| for distant year matches"
  t.equal scoring.regex_entropy(match), lg(scoring.REFERENCE_YEAR - 1972), msg

  match =
    token: '1992'
    regex_name: 'recent_year'
    regex_match: ['1992']
  msg = "entropy of lg(MIN_YEAR_SPACE) for a year close to REFERENCE_YEAR"
  t.equal scoring.regex_entropy(match), lg(scoring.MIN_YEAR_SPACE), msg
  t.end()

test 'date entropy', (t) ->
  match =
    token: '1123'
    separator: ''
    has_full_year: false
    year: 1923
    month: 1
    day: 1
  msg = "entropy for #{match.token} is lg days * months * distance_from_ref_year"
  t.equal scoring.date_entropy(match), lg(12 * 31 * (scoring.REFERENCE_YEAR - match.year)), msg

  match =
    token: '1/1/2010'
    separator: '/'
    has_full_year: true
    year: 2010
    month: 1
    day: 1
  msg = "recent years assume MIN_YEAR_SPACE."
  msg += " extra entropy is added for separators and a 4-digit year."
  t.equal scoring.date_entropy(match), lg(12 * 31 * scoring.MIN_YEAR_SPACE) + 2 + 1, msg
  t.end()

test 'spatial entropy', (t) ->
  match =
    token: 'zxcvbn'
    graph: 'qwerty'
    turns: 1
    shifted_count: 0
  base_entropy = lg(
    scoring.KEYBOARD_STARTING_POSITIONS *
    scoring.KEYBOARD_AVERAGE_DEGREE *
    # - 1 term because: not counting spatial patterns of length 1
    # eg for length==6, multiplier is 5 for needing to try len2,len3,..,len6
    (match.token.length - 1)
    )
  msg = "with no turns or shifts, entropy is lg(starts * degree * (len-1))"
  t.equal scoring.spatial_entropy(match), base_entropy, msg

  match.entropy = null
  match.token = 'ZxCvbn'
  match.shifted_count = 2
  shifted_entropy = base_entropy + lg(nCk(6, 2) + nCk(6, 1))
  msg = "entropy is added for shifted keys, similar to capitals in dictionary matching"
  t.equal scoring.spatial_entropy(match), shifted_entropy, msg

  match.entropy = null
  match.token = 'ZXCVBN'
  match.shifted_count = 6
  shifted_entropy = base_entropy + 1
  msg = "when everything is shifted, only 1 bit is added"
  t.equal scoring.spatial_entropy(match), shifted_entropy, msg

  match =
    token: 'zxcft6yh'
    graph: 'qwerty'
    turns: 3
    shifted_count: 0
  possibilities = 0
  L = match.token.length
  s = scoring.KEYBOARD_STARTING_POSITIONS
  d = scoring.KEYBOARD_AVERAGE_DEGREE
  for i in [2..L]
    for j in [1..Math.min(match.turns, i-1)]
      possibilities += nCk(i-1, j-1) * s * Math.pow(d, j)
  entropy = lg possibilities
  msg = "spatial entropy accounts for turn positions, directions and starting keys"
  t.equal scoring.spatial_entropy(match), entropy, msg
  t.end()

test 'dictionary_entropy', (t) ->
  match =
    token: 'aaaaa'
    rank: 32
  msg = "base entropy is the lg of the rank"
  t.equal scoring.dictionary_entropy(match), lg(32), msg

  match =
    token: 'AAAaaa'
    rank: 32
  msg = "extra entropy is added for capitalization"
  t.equal scoring.dictionary_entropy(match), lg(32) + scoring.extra_uppercase_entropy(match), msg

  match =
    token: 'aaa@@@'
    rank: 32
    l33t: true
    sub: {'@': 'a'}
  msg = "extra entropy is added for common l33t substitutions"
  t.equal scoring.dictionary_entropy(match), lg(32) + scoring.extra_l33t_entropy(match), msg

  match =
    token: 'AaA@@@'
    rank: 32
    l33t: true
    sub: {'@': 'a'}
  msg = "extra entropy is added for both capitalization and common l33t substitutions"
  expected = lg(32) + scoring.extra_l33t_entropy(match) + scoring.extra_uppercase_entropy(match)
  t.equal scoring.dictionary_entropy(match), expected, msg
  t.end()

test 'extra uppercase entropy', (t) ->
  for [word, extra_entropy] in [
    [ '', 0 ]
    [ 'a', 0 ]
    [ 'A', 1 ]
    [ 'abcdef', 0 ]
    [ 'Abcdef', 1 ]
    [ 'abcdeF', 1 ]
    [ 'ABCDEF', 1 ]
    [ 'aBcdef', lg(nCk(6,1)) ]
    [ 'aBcDef', lg(nCk(6,1) + nCk(6,2)) ]
    [ 'ABCDEf', lg(nCk(6,1)) ]
    [ 'aBCDEf', lg(nCk(6,1) + nCk(6,2)) ]
    [ 'ABCdef', lg(nCk(6,1) + nCk(6,2) + nCk(6,3)) ]
    ]
    msg = "extra uppercase entropy of #{word} is #{extra_entropy}"
    t.equal scoring.extra_uppercase_entropy(token: word), extra_entropy, msg
  t.end()

test 'extra l33t entropy', (t) ->
  match = l33t: false
  t.equal scoring.extra_l33t_entropy(match), 0, "0 extra entropy for non-l33t matches"
  for [word, extra_entropy, sub] in [
    [ '',  0, {} ]
    [ 'a', 0, {} ]
    [ '4', 1, {'4': 'a'} ]
    [ '4pple', 1, {'4': 'a'} ]
    [ 'abcet', 0, {} ]
    [ '4bcet', 1, {'4': 'a'} ]
    [ 'a8cet', 1, {'8': 'b'} ]
    [ 'abce+', 1, {'+': 't'} ]
    [ '48cet', 2, {'4': 'a', '8': 'b'} ]
    [ 'a4a4aa',  lg(nCk(6, 2) + nCk(6, 1)), {'4': 'a'} ]
    [ '4a4a44',  lg(nCk(6, 2) + nCk(6, 1)), {'4': 'a'} ]
    [ 'a44att+', lg(nCk(4, 2) + nCk(4, 1)) + lg(nCk(3, 1)), {'4': 'a', '+': 't'} ]
    ]
    match =
      token: word
      sub: sub
      l33t: not matching.empty(sub)
    msg = "extra l33t entropy of #{word} is #{extra_entropy}"
    t.equal scoring.extra_l33t_entropy(match), extra_entropy, msg
  match =
    token: 'Aa44aA'
    l33t: true
    sub: {'4': 'a'}
  extra_entropy = lg(nCk(6, 2) + nCk(6, 1))
  msg = "capitalization doesn't affect extra l33t entropy calc"
  t.equal scoring.extra_l33t_entropy(match), extra_entropy, msg
  t.end()
