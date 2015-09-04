test = require 'tape'
matching = require '../src/matching'
adjacency_graphs = require '../src/adjacency_graphs'

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
    t.deepEqual [match.i, match.j], [i, j]
    t.equal match.token, pattern
    for prop_name, prop_list of props
      t.deepEqual match[prop_name], prop_list[k]


test 'matching utils', (t) ->
  t.ok matching.empty []
  t.ok matching.empty {}
  for obj in [
    [1]
    [1, 2]
    [[]]
    {a: 1}
    {0: {}}
    ]
    t.notOk matching.empty obj

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
  for [string, map, result] in [
    ['a',    chr_map, 'A']
    ['c',    chr_map, 'c']
    ['ab',   chr_map, 'AB']
    ['abc',  chr_map, 'ABc']
    ['aa',   chr_map, 'AA']
    ['abab', chr_map, 'ABAB']
    ['',     chr_map, '']
    ['',     {},      '']
    ['abc',  {},      'abc']
    ]
    t.equal matching.translate(string, map), result

  for [[dividend, divisor], remainder] in [
    [[ 0, 1],  0]
    [[ 1, 1],  0]
    [[-1, 1],  0]
    [[ 5, 5],  0]
    [[ 3, 5],  3]
    [[-1, 5],  4]
    [[-5, 5],  0]
    [[ 6, 5],  1]
    ]
    t.equal matching.mod(dividend, divisor), remainder

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
  dm = (pw) -> matching.dictionary_match pw, test_dicts
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

  matches = dm 'BoaRdZ'
  patterns = ['BoaRd', 'Z']
  check_matches t, matches, 'dictionary', patterns, [[0,4], [5,5]],
    matched_word: ['board', 'z']
    rank: [3, 1]
    dictionary_name: ['d1', 'd2']

  prefixes = ['q', '%%']
  suffixes = ['%', 'qq']
  for name, dict of test_dicts
    for word, rank of dict
      continue if word is 'motherboard' # skip words that contain others
      for [password, i, j] in genpws word, prefixes, suffixes
        matches = dm password
        check_matches t, matches, 'dictionary', [word], [[i,j]],
          matched_word: [word]
          rank: [rank]
          dictionary_name: [name]

  # test the default dictionaries
  matches = matching.dictionary_match 'rosebud'
  patterns = ['ros', 'rose', 'rosebud', 'bud']
  ijs = [[0,2], [0,3], [0,6], [4,6]]
  check_matches t, matches, 'dictionary', patterns, ijs,
    matched_word: patterns
    rank: [13085, 65, 245, 786]
    dictionary_name: ['surnames', 'female_names', 'passwords', 'male_names']
  t.end()


test 'l33t matching', (t) ->
  test_table =
    a: ['4', '@']
    c: ['(', '{', '[', '<']
    g: ['6', '9']
    o: ['0']

  for [pw, expected] in [
    [ '', {} ]
    [ 'abcdefgo123578!#$&*)]}>', {} ]
    [ 'a',     {} ]
    [ '4',     {'a': ['4']} ]
    [ '4@',    {'a': ['4','@']} ]
    [ '4({60', {'a': ['4'], 'c': ['(','{'], 'g': ['6'], 'o': ['0']} ]
    ]
    t.deepEquals matching.relevant_l33t_subtable(pw, test_table), expected

  for [table, subs] in [
    [ {},                        [{}] ]
    [ {a: ['@']},                [{'@': 'a'}] ]
    [ {a: ['@','4']},            [{'@': 'a'}, {'4': 'a'}] ]
    [ {a: ['@','4'], c: ['(']},  [{'@': 'a', '(': 'c' }, {'4': 'a', '(': 'c'}] ]
    ]
    t.deepEquals matching.enumerate_l33t_subs(table), subs

  lm = (pw) -> matching.l33t_match pw, dicts, test_table
  dicts =
    words:
      aac: 1
      password: 3
      paassword: 4
      asdf0: 5
    words2:
      cgo: 1

  t.deepEquals lm(''), []
  t.deepEquals lm('password'), [] # l33t doesn't pick up pure dictionary matches
  for [password, pattern, word, dictionary_name, rank, ij, sub] in [
    [ 'p4ssword',    'p4ssword', 'password', 'words',  3, [0,7],  {'4': 'a'} ]
    [ 'p@ssw0rd',    'p@ssw0rd', 'password', 'words',  3, [0,7],  {'@': 'a', '0': 'o'} ]
    [ 'aSdfO{G0asDfO', '{G0',    'cgo',      'words2', 1, [5, 7], {'{': 'c', '0': 'o'} ]
    ]
    check_matches t, lm(password), 'dictionary', [pattern], [ij],
      l33t: [true]
      sub: [sub]
      matched_word: [word]
      rank: [rank]
      dictionary_name: [dictionary_name]

  matches = lm '@a(go{G0'
  check_matches t, matches, 'dictionary', ['@a(', '(go', '{G0'], [[0,2], [2,4], [5,7]],
    l33t: [true, true, true]
    sub: [{'@': 'a', '(': 'c'}, {'(': 'c'}, {'{': 'c', '0': 'o'}]
    matched_word: ['aac', 'cgo', 'cgo']
    rank: [1, 1, 1]
    dictionary_name: ['words', 'words2', 'words2']

  # known issue: don't match when different substitutions are needed for same letter
  t.deepEqual lm('p4@ssword'), []

  # known issue: subsets of substitutions aren't tried.
  # for long inputs, trying every subset of every possible substitution could quickly get large,
  # but there might be a performant way to fix.
  # (so in this example: {'4': a, '0': 'o'} is detected as a possible sub,
  # but the subset {'4': 'a'} isn't tried, missing the match for asdf0.)
  # TODO: consider partially fixing by trying all subsets of size 1 and maybe 2
  t.deepEqual lm('4sdf0'), []
  t.end()


test 'spatial matching', (t) ->
  for password in ['', '/', 'a', 'qw', '*/']
    t.deepEqual matching.spatial_match(password), []

  # for testing, make a subgraph that contains a single keyboard
  _graphs = qwerty: adjacency_graphs.qwerty
  pattern = '6tfGHJ'
  matches = matching.spatial_match "rz!#{pattern}%z", _graphs
  check_matches t, matches, 'spatial', [pattern], [[3, 3 + pattern.length - 1]],
    graph: ['qwerty']
    turns: [2]
    shifted_count: [3]

  for [pattern, keyboard, turns, shifts] in [
    [ '12345',        'qwerty',     1, 0 ]
    [ '@WSX',         'qwerty',     1, 4 ]
    [ '6tfGHJ',       'qwerty',     2, 3 ]
    [ 'hGFd',         'qwerty',     1, 2 ]
    [ '/;p09876yhn',  'qwerty',     3, 0 ]
    [ 'Xdr%',         'qwerty',     1, 2 ]
    [ '159-',         'keypad',     1, 0 ]
    [ '*84',          'keypad',     1, 0 ]
    [ '/8520',        'keypad',     1, 0 ]
    [ '369',          'keypad',     1, 0 ]
    [ '/963.',        'mac_keypad', 1, 0 ]
    [ '*-632.0214',   'mac_keypad', 9, 0 ]
    [ 'aoEP%yIxkjq:', 'dvorak',     4, 5 ]
    [ ';qoaOQ:Aoq;a', 'dvorak',    11, 4 ]
    ]
    _graphs = {}
    _graphs[keyboard] = adjacency_graphs[keyboard]
    matches = matching.spatial_match pattern, _graphs
    check_matches t, matches, 'spatial', [pattern], [[0, pattern.length - 1]],
      graph: [keyboard]
      turns: [turns]
      shifted_count: [shifts]
  t.end()

test 'sequence matching', (t) ->
  for password in ['', 'a', '1', 'ab']
    t.deepEqual matching.sequence_match(password), []

  matches = matching.sequence_match 'abcbabc'
  check_matches t, matches, 'sequence', ['abc', 'cba', 'abc'], [[0, 2], [2, 4], [4, 6]],
    ascending: [true, false, true]

  t.equal matching.sequence_match('xyzabc').length, 1
  t.equal matching.sequence_match('cbazyx').length, 1

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
  for password in ['', '#', '##']
    t.deepEqual matching.repeat_match(password), []

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


test 'date matching', (t) ->
  tested_pws = {} # don't test the same pw twice
  for [day, month, year] in [
    [1,  1,  1999]
    [22, 11, 1551]
    [11, 8,  2000]
    [9,  12, 2005]
    [4,  6,  2015]
    ]
    for order in ['m,d,y', 'd,m,y', 'y,m,d', 'y,d,m']
      for separator in ['', ' ', '-', '/', '\\', '_', '.']
        for test_two_digit_years in [true, false]
          for test_zero_padding in [true, false]
            y = year.toString()
            if test_two_digit_years
              y = y[2..]
            m = month.toString()
            d = day.toString()
            if test_zero_padding
              m = '0' + m if m.length is 1
              d = '0' + d if d.length is 1
            pattern = order
              .replace 'y', y
              .replace 'm', m
              .replace 'd', d
              .replace /,/g, separator
            continue if pattern of tested_pws
            tested_pws[pattern] = true
            prefixes = ['a', 'ab']
            suffixes = ['!', '@!']
            for [password, i, j] in genpws pattern, prefixes, suffixes
              matches = matching.date_match password
              props = separator: [separator]
              if not test_two_digit_years or parseInt(y) > 31
                # skip year checks where year has multiple mappings
                expected_year = if test_two_digit_years
                  matching.two_to_four_digit_year(year % 100)
                else
                  year
                props.year = [expected_year]
              if not test_two_digit_years and day > 12
                # similar: such cases will have unambiguous day mappings
                props.day = [day]
                props.month = [month]
              check_matches t, matches, 'date', [pattern], [[i, j]], props
  # overlapping dates
  matches = matching.date_match '12/20/1991.12.20'
  check_matches t, matches, 'date', ['12/20/1991', '1991.12.20'], [[0, 9], [6,15]],
    separator: ['/', '.']
    year: [1991, 1991]
    month: [12, 12]
    day: [20, 20]
  # adjacent but non-ambiguous digits
  matches = matching.date_match '912/20/919'
  check_matches t, matches, 'date', ['12/20/91'], [[1, 8]],
    separator: ['/']
    year: [1991]
    month: [12]
    day: [20]
  t.end()
