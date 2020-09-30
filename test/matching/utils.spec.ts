import {
  empty,
  sorted,
  extend,
  translate,
  mod,
  buildRankedDictionary,
} from '~/helper'
import {LooseObject} from '~/types'

describe('utils matching', () => {
  describe('empty', () => {
    it('returns true for an empty array', () => {
      expect(empty([])).toBeTruthy()
    })
    it('returns true for an empty object', () => {
      expect(empty({})).toBeTruthy()
    })

    it('returns false for non-empty objects and arrays', () => {
      const values = [
        [1],
        [1, 2],
        [[]],
        {
          a: 1,
        },
        {
          0: {},
        },
      ]
      values.forEach((value) => {
        expect(empty(value)).toBeFalsy()
      })
    })
  })

  describe('sorted', () => {
    it('sorting an empty list leaves it empty', () => {
      expect(sorted([])).toEqual([])
    })
    it('matches are sorted on i index primary, j secondary', () => {
      const [m1, m2, m3, m4, m5, m6] = [
        {
          i: 5,
          j: 5,
        },
        {
          i: 6,
          j: 7,
        },
        {
          i: 2,
          j: 5,
        },
        {
          i: 0,
          j: 0,
        },
        {
          i: 2,
          j: 3,
        },
        {
          i: 0,
          j: 3,
        },
      ]
      // @ts-ignore
      expect(sorted([m1, m2, m3, m4, m5, m6])).toEqual([m4, m6, m5, m3, m1, m2])
    })
  })

  describe('extend', () => {
    it('an empty list with an empty list leaves it empty', () => {
      const lst = []
      extend(lst, [])
      expect(lst).toEqual([])
    })
    it('an empty list with another makes it equal to the other', () => {
      const lst = []
      extend(lst, [1])
      expect(lst).toEqual([1])
    })
    it("a list with another adds each of the other's elements", () => {
      const lst = [1]
      extend(lst, [2, 3])
      expect(lst).toEqual([1, 2, 3])
    })
    it("a list by another doesn't affect the other", () => {
      const lst = [1]
      const lst2 = [2]
      extend(lst, lst2)
      expect(lst2).toEqual([2])
    })
  })

  describe('translate', () => {
    it('a string to a result with provided charmap', () => {
      const charMap = {
        a: 'A',
        b: 'B',
      }
      const data: [string, LooseObject, string][] = [
        ['a', charMap, 'A'],
        ['c', charMap, 'c'],
        ['ab', charMap, 'AB'],
        ['abc', charMap, 'ABc'],
        ['aa', charMap, 'AA'],
        ['abab', charMap, 'ABAB'],
        ['', charMap, ''],
        ['', {}, ''],
        ['abc', {}, 'abc'],
      ]
      data.forEach(([string, map, result]) => {
        expect(translate(string, map)).toEqual(result)
      })
    })
  })

  describe('mod', () => {
    const data: [number[], number][] = [
      [[0, 1], 0],
      [[1, 1], 0],
      [[-1, 1], 0],
      [[5, 5], 0],
      [[3, 5], 3],
      [[-1, 5], 4],
      [[-5, 5], 0],
      [[6, 5], 1],
    ]
    data.forEach(([[dividend, divisor], remainder]) => {
      it(`(${dividend}, ${divisor}) == ${remainder}`, () => {
        expect(mod(dividend, divisor)).toEqual(remainder)
      })
    })
  })
  describe('buildRankedDictionary', () => {
    it('should build correctly', () => {
      expect(buildRankedDictionary(['foo', 'bar', 'rofl'])).toEqual({
        foo: 1,
        bar: 2,
        rofl: 3,
      })
    })
  })
})
