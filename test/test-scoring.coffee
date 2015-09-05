test = require 'tape'
scoring = require '../src/scoring'

EPSILON = 1e-10 # truncate to 10th decimal place
truncate_float = (float) -> Math.round(float / EPSILON) * EPSILON
approx_equal = (t, actual, expected, msg) ->
  t.equal truncate_float(actual), truncate_float(expected), msg

test 'nCk', (t) ->
  nCk = scoring.nCk
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
  lg = scoring.lg
  for [n, result] in [
    [ 1,  0 ]
    [ 2,  1 ]
    [ 4,  2 ]
    [ 32, 5 ]
    ]
    t.equal lg(n), result, "lg(#{n}) == #{result}"
  n = 17
  p = 4
  approx_equal t, lg(n * p), lg(n) + lg(p), "logarithm product rule"
  approx_equal t, lg(n / p), lg(n) - lg(p), "logarithm quotient rule"
  approx_equal t, lg(10), 1 / Math.log10(2), "logarithm base switch rule"
  approx_equal t, lg(Math.pow(n, p)), p * lg(n), "logarithm power rule"
  approx_equal t, lg(n), Math.log(n) / Math.log(2), "logarithm base change rule"
  t.end()

test 'minimum entropy search', (t) ->
  m = (i, j, entropy) ->
    i: i
    j: j
    entropy: entropy
  password = '0123456789'
  cardinality = 10 # |digits| == 10

  # empty match sequence: result should be one bruteforce match
  result = scoring.minimum_entropy_match_sequence password, []
  t.equal result.match_sequence.length, 1
  m0 = result.match_sequence[0]
  t.equal m0.pattern, 'bruteforce'
  t.equal m0.token, password
  t.equal m0.cardinality, cardinality
  expected = Math.round scoring.lg(Math.pow(cardinality, password.length))
  t.equal Math.round(result.entropy), expected
  t.equal Math.round(m0.entropy), expected
  t.deepEqual [m0.i, m0.j], [0, 9]

  # match that doesn't fully cover password: result should be match + bruteforce
  #  -- match at the start
  matches = [m0] = [m(0, 5, 1)]
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.match_sequence.length, 2
  t.equal result.match_sequence[0], m0
  m1 = result.match_sequence[1]
  t.equal m1.pattern, 'bruteforce'
  t.deepEqual [m1.i, m1.j], [6, 9]
  #  -- match at the end
  matches = [m1] = [m(3, 9, 1)]
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.match_sequence.length, 2
  t.equal result.match_sequence[1], m1
  m0 = result.match_sequence[0]
  t.equal m0.pattern, 'bruteforce'
  t.deepEqual [m0.i, m0.j], [0, 2]
  #  -- match in the middle: bruteforce + match + bruteforce
  matches = [m1] = [m(1, 8, 1)]
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.match_sequence.length, 3
  t.equal result.match_sequence[1], m1
  m0 = result.match_sequence[0]
  m2 = result.match_sequence[2]
  t.equal m0.pattern, 'bruteforce'
  t.equal m2.pattern, 'bruteforce'
  t.deepEqual [m0.i, m0.j], [0, 0]
  t.deepEqual [m2.i, m2.j], [9, 9]

  # when m0 and m1 both cover password and m0 has lower entropy, choose m0
  matches = [m0, m1] = [m(0, 9, 1), m(0, 9, 2)]
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.match_sequence.length, 1
  t.equal result.match_sequence[0], m0
  # make sure ordering doesn't matter
  m0.entropy = 3
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.match_sequence.length, 1
  t.equal result.match_sequence[0], m1

  # when m0 fully covers m1 and m2
  #  -- returns [m0] when m0 has lower entropy than m1 + m2
  matches = [m0, m1, m2] = [m(0, 9, 1), m(0, 3, 1), m(4, 9, 1)]
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.entropy, 1
  t.deepEqual result.match_sequence, [m0]
  #  -- returns [m1, m2] when m0 has higher entropy
  m0.entropy = 3
  result = scoring.minimum_entropy_match_sequence password, matches
  t.equal result.entropy, 2
  t.deepEqual result.match_sequence, [m1, m2]

  t.end()
