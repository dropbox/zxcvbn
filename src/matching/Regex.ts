import { REGEXEN } from '~/data/const'
import { sorted } from '~/helper'
import { ExtendedMatch } from '../types'
/*
 * -------------------------------------------------------------------------------
 *  regex matching ---------------------------------------------------------------
 * -------------------------------------------------------------------------------
 */
class MatchRegex {
  match(password: string, regexes = REGEXEN) {
    const matches: ExtendedMatch[] = []
    // @ts-ignore
    Object.keys(regexes).forEach((name: keyof typeof REGEXEN) => {
      const regex = regexes[name]
      regex.lastIndex = 0 // keeps regexMatch stateless
      const regexMatch = regex.exec(password)
      if (regexMatch) {
        const token = regexMatch[0]
        // @ts-ignore
        matches.push({
          pattern: 'regex',
          token,
          i: regexMatch.index,
          j: regexMatch.index + regexMatch[0].length - 1,
          regexName: name,
          regexMatch,
        })
      }
    })
    return sorted(matches)
  }
}

export default MatchRegex
