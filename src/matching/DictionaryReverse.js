import { sorted } from '~/helper'
import MatchDictionary from './Dictionary'

/*
 * -------------------------------------------------------------------------------
 *  Dictionary reverse ----------------------------------------------------------------
 * -------------------------------------------------------------------------------
 */
class MatchDictionaryReverse {
  constructor({ userInputs } = {}) {
    this.MatchDictionary = new MatchDictionary({
      userInputs,
    })
  }

  match(password) {
    const passwordReversed = password.split('').reverse().join('')
    const matches = this.MatchDictionary.match(passwordReversed).map(
      (match) => ({
        ...match,
        token: match.token.split('').reverse().join(''), // reverse back
        reversed: true,
        // map coordinates back to original string
        i: password.length - 1 - match.j,
        j: password.length - 1 - match.i,
      }),
    )
    return sorted(matches)
  }
}

export default MatchDictionaryReverse
