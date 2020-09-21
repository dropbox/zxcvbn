import spatialGuesses from '../../../src/scoring/guesses/spatial'
import utils from '../../../src/scoring/utils'
import Options from '../../../src/Options'

const { nCk } = utils

describe('scoring: guesses spatial', () => {
  const getKeyBoardBaseGuesses = (token) =>
    Options.keyboardStartingPositions *
    Options.keyboardAverageDegree *
    (token.length - 1)
  const getKeyPadBaseGuesses = (token) =>
    Options.keypadStartingPositions *
    Options.keypadAverageDegree *
    (token.length - 1)
  it('with no turns or shifts, guesses is starts * degree * (len-1)', () => {
    const match = {
      token: 'zxcvbn',
      graph: 'qwerty',
      turns: 1,
      shifted_count: 0,
    }

    expect(spatialGuesses(match)).toEqual(getKeyBoardBaseGuesses(match.token))
  })

  it('guesses is added for shifted keys, similar to capitals in dictionary matching', () => {
    const match = {
      token: 'ZxCvbn',
      graph: 'qwerty',
      turns: 1,
      shifted_count: 2,
      guesses: null,
    }
    const result = getKeyBoardBaseGuesses(match.token) * (nCk(6, 2) + nCk(6, 1))
    expect(spatialGuesses(match)).toEqual(result)
  })

  it('when everything is shifted, guesses are doubled', () => {
    const match = {
      token: 'ZXCVBN',
      graph: 'qwerty',
      turns: 1,
      shifted_count: 6,
      guesses: null,
    }
    const result = getKeyBoardBaseGuesses(match.token) * 2
    expect(spatialGuesses(match)).toEqual(result)
  })

  it('spatial guesses accounts for turn positions, directions and starting keys', () => {
    const match = {
      token: 'zxcft6yh',
      graph: 'qwerty',
      turns: 3,
      shifted_count: 0,
    }
    let guesses = 0
    const tokenLength = match.token.length
    for (let i = 2; i <= tokenLength; i += 1) {
      const turnLength = Math.min(match.turns, i - 1)
      for (let j = 1; j <= turnLength; j += 1) {
        guesses +=
          nCk(i - 1, j - 1) *
          Options.keyboardStartingPositions *
          Options.keyboardAverageDegree ** j
      }
    }

    expect(spatialGuesses(match)).toEqual(guesses)
  })

  it('use default key graph if graph not available', () => {
    const match = {
      token: 'zxcvbn',
      graph: 'abcdef',
      turns: 1,
      shifted_count: 0,
    }

    expect(spatialGuesses(match)).toEqual(getKeyPadBaseGuesses(match.token))
  })
})
