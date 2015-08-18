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
  t.end()

  t.equal matching.mod(0, 1), 0
  t.equal matching.mod(5, 5), 0
  t.equal matching.mod(-1, 5), 4
  t.equal matching.mod(-5, 5), 0
  t.equal matching.mod(6, 5), 1

test 'sequence matching', (t) ->
  t.deepEqual matching.sequence_match(''), []
  t.deepEqual matching.sequence_match('a'), []
  t.deepEqual matching.sequence_match('1'), []
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
      t.equal matches.length, 1
      match = matches[0]
      t.equal match.pattern, 'sequence'
      t.equal match.i, i
      t.equal match.j, j
      t.equal match.token, pattern
      t.equal match.sequence_name, name
      t.equal match.ascending, is_ascending
  t.equal matching.sequence_match('abcba').length, 2
  t.equal matching.sequence_match('xyzabc').length, 1
  t.equal matching.sequence_match('ab').length, 0
  t.end()

