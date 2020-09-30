import date from '~/scoring/guesses/date'
import { MIN_YEAR_SPACE, REFERENCE_YEAR } from '~/data/const'

describe('scoring: guesses date', () => {
  it('guesses for 1123 is 365 * distance_from_ref_year', () => {
    const match = {
      token: '1123',
      separator: '',
      has_full_year: false,
      year: 1923,
      month: 1,
      day: 1,
    }
    const result = 365 * Math.abs(REFERENCE_YEAR - match.year)
    expect(date(match)).toEqual(result)
  })

  it('recent years assume MIN_YEAR_SPACE. extra guesses are added for separators.', () => {
    const match = {
      token: '1/1/2010',
      separator: '/',
      has_full_year: true,
      year: 2010,
      month: 1,
      day: 1,
    }
    const result = 365 * MIN_YEAR_SPACE * 4
    expect(date(match)).toEqual(result)
  })
})
