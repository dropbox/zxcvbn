import { MIN_YEAR_SPACE, REFERENCE_YEAR } from '../../data/const'

export default (match) => {
  const charClassBases = {
    alpha_lower: 26,
    alpha_upper: 26,
    alpha: 52,
    alphanumeric: 62,
    digits: 10,
    symbols: 33,
  }
  if (match.regex_name in charClassBases) {
    return charClassBases[match.regex_name] ** match.token.length
  }
  // TODO add more regex types for example special dates like 09.11
  // eslint-disable-next-line default-case
  switch (match.regex_name) {
    case 'recent_year':
      // conservative estimate of year space: num years from REFERENCE_YEAR.
      // if year is close to REFERENCE_YEAR, estimate a year space of MIN_YEAR_SPACE.
      return Math.max(
        Math.abs(parseInt(match.regex_match[0], 10) - REFERENCE_YEAR),
        MIN_YEAR_SPACE,
      )
  }
  return 0
}
