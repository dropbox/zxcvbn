import l33t from '~/scoring/variant/l33t'
import utils from '~/scoring/utils'
import { empty } from '~/helper'

const { nCk } = utils

describe('scoring: variant l33t', () => {
  const data = [
    ['', 1, {}],
    ['a', 1, {}],
    [
      '4',
      2,
      {
        4: 'a',
      },
    ],
    [
      '4pple',
      2,
      {
        4: 'a',
      },
    ],
    ['abcet', 1, {}],
    [
      '4bcet',
      2,
      {
        4: 'a',
      },
    ],
    [
      'a8cet',
      2,
      {
        8: 'b',
      },
    ],
    [
      'abce+',
      2,
      {
        '+': 't',
      },
    ],
    [
      '48cet',
      4,
      {
        4: 'a',
        8: 'b',
      },
    ],
    [
      'a4a4aa',
      nCk(6, 2) + nCk(6, 1),
      {
        4: 'a',
      },
    ],
    [
      '4a4a44',
      nCk(6, 2) + nCk(6, 1),
      {
        4: 'a',
      },
    ],
    [
      'a44att+',
      (nCk(4, 2) + nCk(4, 1)) * nCk(3, 1),
      {
        '4': 'a',
        '+': 't',
      },
    ],
  ]

  data.forEach(([word, variants, sub]) => {
    it(`extra l33t guesses of ${word} is ${variants}`, () => {
      const match = {
        token: word,
        sub,
        l33t: !empty(sub),
      }
      expect(l33t(match)).toEqual(variants)
    })
  })

  it("capitalization doesn't affect extra l33t guesses calc", () => {
    const match = {
      token: 'Aa44aA',
      l33t: true,
      sub: {
        4: 'a',
      },
    }
    const variants = nCk(6, 2) + nCk(6, 1)
    expect(l33t(match)).toEqual(variants)
  })
})
