import estimate from '~/scoring/estimate'
import dateGuesses from '~/scoring/guesses/date'

describe('scoring', () => {
  it('estimate_guesses returns cached guesses when available', () => {
    const match = {
      guesses: 1,
    }
    expect(estimate(match, '')).toEqual({
      guesses: 1,
    })
  })

  it('estimate_guesses delegates based on pattern', () => {
    const match = {
      pattern: 'date',
      token: '1977',
      year: 1977,
      month: 7,
      day: 14,
    }
    expect(estimate(match, '1977')).toEqual({
      pattern: 'date',
      token: '1977',
      year: 1977,
      month: 7,
      day: 14,
      guesses: dateGuesses(match),
      guessesLog10: 4.195761320036061,
    })
  })
})
