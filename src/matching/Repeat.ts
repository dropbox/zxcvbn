import { ExtendedMatch } from '../types'

/*
 *-------------------------------------------------------------------------------
 * repeats (aaa, abcabcabc) ------------------------------
 *-------------------------------------------------------------------------------
 */

class MatchRepeat {
  match(password: string) {
    const matches: ExtendedMatch[] = []
    const greedy = /(.+)\1+/g
    const lazy = /(.+?)\1+/g
    const lazyAnchored = /^(.+?)\1+$/
    let lastIndex = 0
    while (lastIndex < password.length) {
      let match
      let baseToken = ''
      greedy.lastIndex = lastIndex
      lazy.lastIndex = lastIndex
      const greedyMatch = greedy.exec(password)
      const lazyMatch = lazy.exec(password)
      if (greedyMatch == null) {
        break
      }
      if (lazyMatch && greedyMatch[0].length > lazyMatch[0].length) {
        // greedy beats lazy for 'aabaab'
        // greedy: [aabaab, aab]
        // lazy:   [aa,     a]
        match = greedyMatch
        // greedy's repeated string might itself be repeated, eg.
        // aabaab in aabaabaabaab.
        // run an anchored lazy match on greedy's repeated string
        // to find the shortest repeated string
        const temp = lazyAnchored.exec(match[0])
        if (temp) {
          baseToken = temp[1]
        }
      } else {
        // lazy beats greedy for 'aaaaa'
        // greedy: [aaaa,  aa]
        // lazy:   [aaaaa, a]
        match = lazyMatch
        if (match) {
          baseToken = match[1]
        }
      }
      if (match) {
        const j = match.index + match[0].length - 1
        // @ts-ignore
        matches.push({
          pattern: 'repeat',
          i: match.index,
          j,
          token: match[0],
          baseToken,
          repeatCount: match[0].length / baseToken.length,
        })
        lastIndex = j + 1
      }
    }
    return matches
  }
}

export default MatchRepeat
