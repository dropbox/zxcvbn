import { sorted } from '~/helper'
import MatchDictionary from './Dictionary'
import { ExtendedMatch } from '../types'

/*
 * -------------------------------------------------------------------------------
 *  Dictionary reverse ----------------------------------------------------------------
 * -------------------------------------------------------------------------------
 */
class MatchDictionaryReverse {
  MatchDictionary: any

  constructor(
    { userInputs = [] } = {
      userInputs: [],
    },
  ) {
    this.MatchDictionary = new MatchDictionary({
      userInputs,
    })
  }

  match(password: string) {
    const passwordReversed = password.split('').reverse().join('')
    const matches = this.MatchDictionary.match(passwordReversed).map(
      (match: ExtendedMatch) => ({
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
