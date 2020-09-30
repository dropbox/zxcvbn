import bruteforce from '~/scoring/guesses/bruteforce'
import {
  BRUTEFORCE_CARDINALITY,
  MIN_SUBMATCH_GUESSES_SINGLE_CHAR,
  MIN_SUBMATCH_GUESSES_MULTI_CHAR,
} from '~/data/const'

describe('scoring: guesses bruteforce', () => {
  it(`should be Exponentiation of ${BRUTEFORCE_CARDINALITY} and the token length`, () => {
    const testData = [
      {
        match: {
          token: 'a'.repeat(2),
        },
        result: 100,
      },
      {
        match: {
          token: 'a'.repeat(123),
        },
        result: 1e123,
      },
      {
        match: {
          token: 'a'.repeat(308),
        },
        result: 1e308,
      },
    ]
    testData.forEach((data) => {
      expect(bruteforce(data.match)).toEqual(data.result)
    })
  })

  it(`should be ${Number.MAX_VALUE} from Number.MAX_VALUE`, () => {
    const token = 'a'.repeat(309)
    const match = {
      token,
    }
    expect(bruteforce(match)).toEqual(Number.MAX_VALUE)
  })

  it(`should be ${MIN_SUBMATCH_GUESSES_SINGLE_CHAR} from MIN_SUBMATCH_GUESSES_SINGLE_CHAR`, () => {
    const match = {
      token: 'a',
    }
    expect(bruteforce(match)).toEqual(11)
  })

  // TODO this can't be reached because min guesses is 51 and with a password length of 2 you get 100 already
  // eslint-disable-next-line jest/no-disabled-tests
  it.skip(`should be ${MIN_SUBMATCH_GUESSES_MULTI_CHAR} from MIN_SUBMATCH_GUESSES_MULTI_CHAR`, () => {
    const match = {
      token: 'ab',
    }
    expect(bruteforce(match)).toEqual(11)
  })
})
