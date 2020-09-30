import MatchL33t from '~/matching/L33t'
import checkMatches from '../helper/checkMatches'
import Options from '~/Options'
import {LooseObject} from '~/types'

Options.setOptions()

describe('l33t matching', () => {
  let msg
  const testTable = {
    a: ['4', '@'],
    c: ['(', '{', '[', '<'],
    g: ['6', '9'],
    o: ['0'],
  }

  const dicts = {
    words: ['aac', 'password', 'paassword', 'asdf0'],
    words2: ['cgo'],
  }

  describe('default const', () => {
    const matchL33t = new MatchL33t()
    it("doesn't match single-character l33ted words", () => {
      expect(matchL33t.match('4 1 @')).toEqual([])
    })
  })

  Options.setOptions({
    dictionary: dicts,
    l33tTable: testTable,
  })
  const matchL33t = new MatchL33t({
    userInputs: [],
  })

  describe('main match', () => {
    it("doesn't match ''", () => {
      expect(matchL33t.match('')).toEqual([])
    })

    it("doesn't match pure dictionary words", () => {
      expect(matchL33t.match('password')).toEqual([])
    })

    it("doesn't match when multiple l33t substitutions are needed for the same letter", () => {
      expect(matchL33t.match('p4@ssword')).toEqual([])
    })

    it("doesn't match with subsets of possible l33t substitutions", () => {
      expect(matchL33t.match('4sdf0')).toEqual([])
    })
    const data = [
      [
        'p4ssword',
        'p4ssword',
        'password',
        'words',
        3,
        [0, 7],
        {
          4: 'a',
        },
      ],
      [
        'p@ssw0rd',
        'p@ssw0rd',
        'password',
        'words',
        3,
        [0, 7],
        {
          '@': 'a',
          '0': 'o',
        },
      ],
      [
        'aSdfO{G0asDfO',
        '{G0',
        'cgo',
        'words2',
        1,
        [5, 7],
        {
          '{': 'c',
          '0': 'o',
        },
      ],
    ]

    data.forEach(([password, pattern, word, dictionaryName, rank, ij, sub]) => {
      msg = 'matches against common l33t substitutions'
      checkMatches(
        msg,
        matchL33t.match(password as string),
        'dictionary',
        [pattern],
        [ij],
        {
          l33t: [true],
          sub: [sub],
          matchedWord: [word],
          rank: [rank],
          dictionaryName: [dictionaryName],
        },
      )
    })
    const matches = matchL33t.match('@a(go{G0')
    msg = 'matches against overlapping l33t patterns'
    checkMatches(
      msg,
      matches,
      'dictionary',
      ['@a(', '(go', '{G0'],
      [
        [0, 2],
        [2, 4],
        [5, 7],
      ],
      {
        l33t: [true, true, true],
        sub: [
          {
            '@': 'a',
            '(': 'c',
          },
          {
            '(': 'c',
          },
          {
            '{': 'c',
            '0': 'o',
          },
        ],
        matchedWord: ['aac', 'cgo', 'cgo'],
        rank: [1, 1, 1],
        dictionaryName: ['words', 'words2', 'words2'],
      },
    )
  })

  describe('helpers', () => {
    it('reduces l33t table to only the substitutions that a password might be employing', () => {
      const data: [string, LooseObject][] = [
        ['', {}],
        ['abcdefgo123578!#$&*)]}>', {}],
        ['a', {}],
        [
          '4',
          {
            a: ['4'],
          },
        ],
        [
          '4@',
          {
            a: ['4', '@'],
          },
        ],
        [
          '4({60',
          {
            a: ['4'],
            c: ['(', '{'],
            g: ['6'],
            o: ['0'],
          },
        ],
      ]

      data.forEach(([pw, expected]) => {
        expect(matchL33t.relevantL33tSubtable(pw, testTable)).toEqual(expected)
      })
    })

    it('enumerates the different sets of l33t substitutions a password might be using', () => {
      const data = [
        [{}, [{}]],
        [
          {
            a: ['@'],
          },
          [
            {
              '@': 'a',
            },
          ],
        ],
        [
          {
            a: ['@', '4'],
          },
          [
            {
              '@': 'a',
            },
            {
              4: 'a',
            },
          ],
        ],
        [
          {
            a: ['@', '4'],
            c: ['('],
          },
          [
            {
              '@': 'a',
              '(': 'c',
            },
            {
              '4': 'a',
              '(': 'c',
            },
          ],
        ],
      ]

      data.forEach(([table, subs]) => {
        expect(matchL33t.enumerateL33tSubs(table)).toEqual(subs)
      })
    })
  })
})
