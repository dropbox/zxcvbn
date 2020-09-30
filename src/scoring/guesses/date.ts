import { MIN_YEAR_SPACE, REFERENCE_YEAR } from '~/data/const'

export default ({ year, separator }) => {
  // base guesses: (year distance from REFERENCE_YEAR) * num_days * num_years
  const yearSpace = Math.max(Math.abs(year - REFERENCE_YEAR), MIN_YEAR_SPACE)

  let guesses = yearSpace * 365
  // add factor of 4 for separator selection (one of ~4 choices)
  if (separator) {
    guesses *= 4
  }
  return guesses
}
