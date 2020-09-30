import regexGuesses from '~/scoring/guesses/regex'
import { MIN_YEAR_SPACE, REFERENCE_YEAR } from '~/data/const'

describe('scoring: guesses regex', () => {
  it('guesses of 26^7 for 7-char lowercase regex', () => {
    const match = {
      token: 'aizocdk',
      regexName: 'alphaLower',
      regexMatch: ['aizocdk'],
    }
    const result = 26 ** 7
    expect(regexGuesses(match)).toEqual(result)
  })

  it('guesses of 62^5 for 5-char alphanumeric regex', () => {
    const match = {
      token: 'ag7C8',
      regexName: 'alphanumeric',
      regexMatch: ['ag7C8'],
    }
    const result = (2 * 26 + 10) ** 5
    expect(regexGuesses(match)).toEqual(result)
  })

  it('guesses of |year - REFERENCE_YEAR| for distant year matches', () => {
    const match = {
      token: '1972',
      regexName: 'recentYear',
      regexMatch: ['1972'],
    }
    const result = Math.abs(REFERENCE_YEAR - 1972)
    expect(regexGuesses(match)).toEqual(result)
  })

  it('guesses of MIN_YEAR_SPACE for a year close to REFERENCE_YEAR', () => {
    const match = {
      token: '2005',
      regexName: 'recentYear',
      regexMatch: ['2005'],
    }
    expect(regexGuesses(match)).toEqual(MIN_YEAR_SPACE)
  })

  it('should equal 0 for not found regex names', () => {
    const match = {
      token: '',
      regexName: 'someRegexName',
      regexMatch: [''],
    }
    expect(regexGuesses(match)).toEqual(0)
  })
})
