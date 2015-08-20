test = require 'tape'
matching = require '../src/matching'

# takes a pattern and list of prefixes/suffixes
# returns a bunch of variants of that pattern embedded
# with each possible prefix/suffix combination, including no prefix/suffix
# returns a list of triplets [variant, i, j] where [i,j] is the start/end of the pattern, inclusive
genpws = (pattern, prefixes, suffixes) ->
  prefixes = prefixes.slice()
  suffixes = suffixes.slice()
  for lst in [prefixes, suffixes]
    lst.unshift '' if '' not in lst
  result = []
  for prefix in prefixes
    for suffix in suffixes
      [i, j] = [prefix.length, prefix.length + pattern.length - 1]
      result.push [prefix + pattern + suffix, i, j]
  result

check_matches = (t, matches, pattern_names, patterns, ijs, props) ->
  if typeof pattern_names is "string"
    # shortcut: if checking for a list of the same type of patterns,
    # allow passing a string 'pat' instead of array ['pat', 'pat', ...]
    pattern_names = (pattern_names for i in [0...patterns.length])

  is_equal_len_args = pattern_names.length == patterns.length == ijs.length
  for prop, lst of props
    # props is structured as: keys that points to list of values
    is_equal_len_args = is_equal_len_args and (lst.length == patterns.length)
  throw 'unequal argument lists to check_matches' unless is_equal_len_args

  t.equal matches.length, patterns.length
  for k in [0...patterns.length]
    match = matches[k]
    pattern_name = pattern_names[k]
    pattern = patterns[k]
    [i, j] = ijs[k]
    t.equal match.pattern, pattern_name
    t.equal match.i, i
    t.equal match.j, j
    t.equal match.token, pattern
    for prop_name, prop_list of props
      t.equal match[prop_name], prop_list[k]

test 'matching utils', (t) ->
  t.ok matching.empty []
  t.notOk matching.empty [1]
  t.notOk matching.empty [1, 2]
  t.notOk matching.empty [[]]
  t.ok matching.empty {}
  t.notOk matching.empty {a: 1}
  t.notOk matching.empty {0: {}}

  lst = []
  matching.extend lst, []
  t.deepEqual lst, []
  matching.extend lst, [1]
  t.deepEqual lst, [1]
  matching.extend lst, [2, 3]
  t.deepEqual lst, [1, 2, 3]
  [lst1, lst2] = [[1], [2]]
  matching.extend lst1, lst2
  t.deepEqual lst1, [1, 2]
  t.deepEqual lst2, [2]

  chr_map = {a: 'A', b: 'B'}
  t.equal matching.translate('a', chr_map), 'A'
  t.equal matching.translate('c', chr_map), 'c'
  t.equal matching.translate('ab', chr_map), 'AB'
  t.equal matching.translate('abc', chr_map), 'ABc'
  t.equal matching.translate('aa', chr_map), 'AA'
  t.equal matching.translate('abab', chr_map), 'ABAB'
  t.equal matching.translate('', chr_map), ''
  t.equal matching.translate('', {}), ''
  t.equal matching.translate('abc', {}), 'abc'

  t.equal matching.mod(0, 1), 0
  t.equal matching.mod(1, 1), 0
  t.equal matching.mod(-1, 1), 0
  t.equal matching.mod(5, 5), 0
  t.equal matching.mod(3, 5), 3
  t.equal matching.mod(-1, 5), 4
  t.equal matching.mod(-5, 5), 0
  t.equal matching.mod(6, 5), 1

  t.deepEqual matching.sorted([]), []
  [m1, m2, m3, m4, m5, m6] = [
    {i: 5, j: 5}
    {i: 6, j: 7}
    {i: 2, j: 5}
    {i: 0, j: 0}
    {i: 2, j: 3}
    {i: 0, j: 3}
  ]
  t.deepEqual matching.sorted([m1, m2, m3, m4, m5, m6]), [m4, m6, m5, m3, m1, m2]
  t.end()

test 'dictionary matching', (t) ->
  test_dicts =
    d1:
      motherboard: 1
      mother: 2
      board: 3
      abcd: 4
      cdef: 5
    d2:
      'z': 1
      '8': 2
      '99': 3
      '$': 4
      'asdf1234&*': 5
  dm = (pw) -> matching.dictionary_match pw, test_dicts
  matches = dm 'motherboard'
  patterns = ['mother', 'motherboard', 'board']
  check_matches t, matches, 'dictionary', patterns, [[0,5], [0,10], [6,10]],
    matched_word: ['mother', 'motherboard', 'board']
    rank: [2, 1, 3]
    dictionary_name: ['d1', 'd1', 'd1']
  matches = dm 'abcdef'
  patterns = ['abcd', 'cdef']
  check_matches t, matches, 'dictionary', patterns, [[0,3], [2,5]],
    matched_word: ['abcd', 'cdef']
    rank: [4, 5]
    dictionary_name: ['d1', 'd1']
  matches = dm 'boardz'
  patterns = ['board', 'z']
  check_matches t, matches, 'dictionary', patterns, [[0,4], [5,5]],
    matched_word: ['board', 'z']
    rank: [3, 1]
    dictionary_name: ['d1', 'd2']
  prefixes = ['q', '%%']
  suffixes = ['%', 'qq']
  for name, dict of test_dicts
    for word, rank of dict
      continue if word is 'motherboard'
      for [password, i, j] in genpws word, prefixes, suffixes
        matches = dm password
        check_matches t, matches, 'dictionary', [word], [[i,j]],
          matched_word: [word]
          rank: [rank]
          dictionary_name: [name]
  # test embedded dictionaries
  matches = matching.dictionary_match 'rosebud'
  patterns = ['ros', 'rose', 'rosebud', 'bud']
  ijs = [[0,2], [0,3], [0,6], [4,6]]
  check_matches t, matches, 'dictionary', patterns, ijs,
    matched_word: patterns
    rank: [13085, 65, 245, 786]
    dictionary_name: ['surnames', 'female_names', 'passwords', 'male_names']
  t.end()

test 'sequence matching', (t) ->
  t.deepEqual matching.sequence_match(''), []
  t.deepEqual matching.sequence_match('a'), []
  t.deepEqual matching.sequence_match('1'), []
  matches = matching.sequence_match 'abcbabc'
  check_matches t, matches, 'sequence', ['abc', 'cba', 'abc'], [[0, 2], [2, 4], [4, 6]],
    ascending: [true, false, true]
  t.equal matching.sequence_match('xyzabc').length, 1
  t.equal matching.sequence_match('cbazyx').length, 1
  t.equal matching.sequence_match('ab').length, 0
  prefixes = ['!', '22', 'ttt']
  suffixes = ['!', '22', 'ttt']
  for [pattern, name, is_ascending] in [
    ['ABC',   'upper',  true]
    ['CBA',   'upper',  false]
    ['PQR',   'upper',  true]
    ['RQP',   'upper',  false]
    ['XYZ',   'upper',  true]
    ['ZYX',   'upper',  false]
    ['abcd',  'lower',  true]
    ['dcba',  'lower',  false]
    ['ghij',  'lower',  true]
    ['jihg',  'lower',  false]
    ['wxyz',  'lower',  true]
    ['zyxw',  'lower',  false]
    ['01234', 'digits', true]
    ['43210', 'digits', false]
    ['67890', 'digits', true]
    ['09876', 'digits', false]
    ]
    for [password, i, j] in genpws pattern, prefixes, suffixes
      matches = matching.sequence_match password
      check_matches t, matches, 'sequence', [pattern], [[i, j]],
        sequence_name: [name]
        ascending: [is_ascending]
  t.end()

test 'repeat matching', (t) ->
  t.deepEqual matching.repeat_match(''), []
  t.deepEqual matching.repeat_match('#'), []
  t.deepEqual matching.repeat_match('##'), []
  prefixes = ['@', 'y4@']
  suffixes = ['u', 'u%7']
  for length in [3, 12]
    for chr in ['a', 'Z', '4', '&']
      pattern = Array(length + 1).join(chr)
      for [password, i, j] in genpws pattern, prefixes, suffixes
        matches = matching.repeat_match password
        check_matches t, matches, 'repeat', [pattern], [[i, j]],
          repeated_char: [chr]
  matches = matching.repeat_match 'BBB1111aaaaa@@@@@@'
  patterns = ['BBB','1111','aaaaa','@@@@@@']
  check_matches t, matches, 'repeat', patterns, [[0, 2],[3, 6],[7, 11],[12, 17]],
    repeated_char: ['B', '1', 'a', '@']
  matches = matching.repeat_match '2818BBBbzsdf1111@*&@!aaaaaEUDA@@@@@@1729'
  check_matches t, matches, 'repeat', patterns, [[4, 6],[12, 15],[21, 25],[30, 35]],
    repeated_char: ['B', '1', 'a', '@']
  t.end()
