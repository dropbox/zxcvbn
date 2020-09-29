import {
  MIN_SUBMATCH_GUESSES_SINGLE_CHAR,
  MIN_SUBMATCH_GUESSES_MULTI_CHAR,
} from '../data/const'
import bruteforceGuesses from './guesses/bruteforce'
import dateGuesses from './guesses/date'
import dictionaryGuesses from './guesses/dictionary'
import regexGuesses from './guesses/regex'
import repeatGuesses from './guesses/repeat'
import sequenceGuesses from './guesses/sequence'
import spatialGuesses from './guesses/spatial'
import utils from './utils'

// ------------------------------------------------------------------------------
// guess estimation -- one function per match pattern ---------------------------
// ------------------------------------------------------------------------------

export default (match, password) => {
  const extraData = {}
  // a match's guess estimate doesn't change. cache it.
  if (match.guesses != null) {
    return match
  }
  let minGuesses = 1
  if (match.token.length < password.length) {
    if (match.token.length === 1) {
      minGuesses = MIN_SUBMATCH_GUESSES_SINGLE_CHAR
    } else {
      minGuesses = MIN_SUBMATCH_GUESSES_MULTI_CHAR
    }
  }
  const estimationFunctions = {
    bruteforce: bruteforceGuesses,
    dictionary: dictionaryGuesses,
    spatial: spatialGuesses,
    repeat: repeatGuesses,
    sequence: sequenceGuesses,
    regex: regexGuesses,
    date: dateGuesses,
  }
  const estimationResult = estimationFunctions[match.pattern](match)
  let guesses = 0
  if (match.pattern === 'dictionary') {
    guesses = estimationResult.calculation
    extraData.baseGuesses = estimationResult.baseGuesses
    extraData.uppercaseVariations = estimationResult.uppercaseVariations
    extraData.l33tVariations = estimationResult.l33tVariations
  } else {
    guesses = estimationResult
  }

  const matchGuesses = Math.max(guesses, minGuesses)
  return {
    ...match,
    ...extraData,
    guesses: matchGuesses,
    guessesLog10: utils.log10(matchGuesses),
  }
}
