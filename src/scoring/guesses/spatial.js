import utils from '../utils'
import Options from '../../Options'

export default (match) => {
  let startingPosition = Options.keypadStartingPositions
  let averageDegree = Options.keypadAverageDegree
  if (Options.availbableGraphs.includes(match.graph)) {
    startingPosition = Options.keyboardStartingPositions
    averageDegree = Options.keyboardAverageDegree
  }
  let guesses = 0
  const tokenLength = match.token.length
  const { turns } = match
  // # estimate the number of possible patterns w/ tokenLength or less with turns or less.
  for (let i = 2; i <= tokenLength; i += 1) {
    const possibleTurns = Math.min(turns, i - 1)
    for (let j = 1; j <= possibleTurns; j += 1) {
      guesses += utils.nCk(i - 1, j - 1) * startingPosition * averageDegree ** j
    }
  }
  // add extra guesses for shifted keys. (% instead of 5, A instead of a.)
  // math is similar to extra guesses of l33t substitutions in dictionary matches.
  if (match.shifted_count) {
    const shiftedCount = match.shifted_count
    const unShiftedCount = match.token.length - match.shifted_count
    if (shiftedCount === 0 || unShiftedCount === 0) {
      guesses *= 2
    } else {
      let shiftedVariations = 0
      for (let i = 1; i <= Math.min(shiftedCount, unShiftedCount); i += 1) {
        shiftedVariations += utils.nCk(shiftedCount + unShiftedCount, i)
      }
      guesses *= shiftedVariations
    }
  }
  return guesses
}
