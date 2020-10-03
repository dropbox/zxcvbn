import uppercase from '~/scoring/variant/uppercase'
import utils from '~/scoring/utils'

const { nCk } = utils

describe('scoring: variant uppercase', () => {
  const data = [
    ['', 1],
    ['a', 1],
    ['A', 2],
    ['abcdef', 1],
    ['Abcdef', 2],
    ['abcdeF', 2],
    ['ABCDEF', 2],
    ['aBcdef', nCk(6, 1)],
    ['aBcDef', nCk(6, 1) + nCk(6, 2)],
    ['ABCDEf', nCk(6, 1)],
    ['aBCDEf', nCk(6, 1) + nCk(6, 2)],
    ['ABCdef', nCk(6, 1) + nCk(6, 2) + nCk(6, 3)],
  ]

  data.forEach(([word, variants]) => {
    it(`guess multiplier of ${word} is ${variants}`, () => {
      expect(uppercase(word as string)).toEqual(variants)
    })
  })
})
