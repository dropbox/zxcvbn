import MatchSequence from '~/matching/Sequence'
import checkMatches from '../helper/checkMatches'
import genpws from '../helper/genpws'

describe('sequence matching', () => {
  const matchSequence = new MatchSequence()

  it("doesn't match length sequences", () => {
    const data = ['', 'a', '1']

    data.forEach((password) => {
      expect(matchSequence.match(password)).toEqual([])
    })
  })

  let matches = matchSequence.match('abcbabc')
  let msg = 'matches overlapping patterns'
  checkMatches(
    msg,
    matches,
    'sequence',
    ['abc', 'cba', 'abc'],
    [
      [0, 2],
      [2, 4],
      [4, 6],
    ],
    {
      ascending: [true, false, true],
    },
  )

  const prefixes = ['!', '22']
  const suffixes = ['!', '22']
  const pattern = 'jihg'
  const generatedGenPws = genpws(pattern, prefixes, suffixes)

  generatedGenPws.forEach(([password, i, j]) => {
    matches = matchSequence.match(password)
    msg = `matches embedded sequence patterns ${password}`
    checkMatches(msg, matches, 'sequence', [pattern], [[i, j]], {
      sequenceName: ['lower'],
      ascending: [false],
    })
  })

  const data: [string, string, boolean][] = [
    ['ABC', 'upper', true],
    ['CBA', 'upper', false],
    ['PQR', 'upper', true],
    ['RQP', 'upper', false],
    ['XYZ', 'upper', true],
    ['ZYX', 'upper', false],
    ['abcd', 'lower', true],
    ['dcba', 'lower', false],
    ['jihg', 'lower', false],
    ['wxyz', 'lower', true],
    ['zxvt', 'lower', false],
    ['0369', 'digits', true],
    ['97531', 'digits', false],
  ]

  data.forEach(([dataPattern, name, isAscending]) => {
    matches = matchSequence.match(dataPattern)
    msg = `matches '${dataPattern}' as a '${name}' sequence`
    checkMatches(
      msg,
      matches,
      'sequence',
      [dataPattern],
      [[0, dataPattern.length - 1]],
      {
        sequenceName: [name],
        ascending: [isAscending],
      },
    )
  })
})
