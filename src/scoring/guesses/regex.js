import { MIN_YEAR_SPACE, REFERENCE_YEAR } from '../../data/const'

export default ({ regex_name, regex_match, token }) => {
  const charClassBases = {
    alpha_lower: 26,
    alpha_upper: 26,
    alpha: 52,
    alphanumeric: 62,
    digits: 10,
    symbols: 33,
  }
  if (regex_name in charClassBases) {
    return charClassBases[regex_name] ** token.length
  }
  // TODO add more regex types for example special dates like 09.11
  // eslint-disable-next-line default-case
  switch (regex_name) {
    case 'recent_year':
      // conservative estimate of year space: num years from REFERENCE_YEAR.
      // if year is close to REFERENCE_YEAR, estimate a year space of MIN_YEAR_SPACE.
      return Math.max(
        Math.abs(parseInt(regex_match[0], 10) - REFERENCE_YEAR),
        MIN_YEAR_SPACE,
      )
  }
  return 0
}
