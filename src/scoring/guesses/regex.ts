import { MIN_YEAR_SPACE, REFERENCE_YEAR } from '~/data/const'

export default ({ regexName, regexMatch, token }) => {
  const charClassBases = {
    alphaLower: 26,
    alphaUpper: 26,
    alpha: 52,
    alphanumeric: 62,
    digits: 10,
    symbols: 33,
  }
  if (regexName in charClassBases) {
    return charClassBases[regexName] ** token.length
  }
  // TODO add more regex types for example special dates like 09.11
  // eslint-disable-next-line default-case
  switch (regexName) {
    case 'recentYear':
      // conservative estimate of year space: num years from REFERENCE_YEAR.
      // if year is close to REFERENCE_YEAR, estimate a year space of MIN_YEAR_SPACE.
      return Math.max(
        Math.abs(parseInt(regexMatch[0], 10) - REFERENCE_YEAR),
        MIN_YEAR_SPACE,
      )
  }
  return 0
}
