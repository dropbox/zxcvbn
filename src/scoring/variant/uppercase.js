import utils from '../utils'
import { START_UPPER, END_UPPER, ALL_UPPER, ALL_LOWER } from '../../data/const'

export default (match) => {
  const word = match.token
  // TODO this is a good fix https://github.com/dropbox/zxcvbn/issues/232
  // const word = match.token.replace(/[^A-Za-z]/gi, '')
  if (word.match(ALL_LOWER) || word.toLowerCase() === word) {
    return 1
  }
  // a capitalized word is the most common capitalization scheme,
  // so it only doubles the search space (uncapitalized + capitalized).
  // allcaps and end-capitalized are common enough too, underestimate as 2x factor to be safe.
  const commonCases = [START_UPPER, END_UPPER, ALL_UPPER]
  const commonCasesLength = commonCases.length
  for (let i = 0; i < commonCasesLength; i += 1) {
    const regex = commonCases[i]
    if (word.match(regex)) {
      return 2
    }
  }
  // otherwise calculate the number of ways to capitalize U+L uppercase+lowercase letters
  // with U uppercase letters or less. or, if there's more uppercase than lower (for eg. PASSwORD),
  // the number of ways to lowercase U+L letters with L lowercase letters or less.
  const upperCaseCount = word.split('').filter((char) => char.match(/[A-Z]/))
    .length
  const lowerCaseCount = word.split('').filter((char) => char.match(/[a-z]/))
    .length

  let variations = 0
  const variationLength = Math.min(upperCaseCount, lowerCaseCount)
  for (let i = 1; i <= variationLength; i += 1) {
    variations += utils.nCk(upperCaseCount + lowerCaseCount, i)
  }
  return variations
}
