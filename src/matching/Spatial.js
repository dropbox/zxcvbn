import { sorted, extend } from '~/helper'
import Options from '~/Options'
/*
 * ------------------------------------------------------------------------------
 * spatial match (qwerty/dvorak/keypad and so on) -----------------------------------------
 * ------------------------------------------------------------------------------
 */
class MatchSpatial {
  constructor() {
    // TODO check with graphs
    this.SHIFTED_RX = /[~!@#$%^&*()_+QWERTYUIOP{}|ASDFGHJKL:"ZXCVBNM<>?]/
  }

  match(password) {
    const matches = []
    Object.keys(Options.graphs).forEach((graphName) => {
      const graph = Options.graphs[graphName]
      extend(matches, this.helper(password, graph, graphName))
    })
    return sorted(matches)
  }

  helper(password, graph, graphName) {
    let shiftedCount
    const matches = []
    let i = 0
    const passwordLength = password.length
    while (i < passwordLength - 1) {
      let j = i + 1
      let lastDirection = null
      let turns = 0
      if (
        !graphName.includes('keypad') &&
        this.SHIFTED_RX.test(password.charAt(i))
      ) {
        // initial character is shifted
        shiftedCount = 1
      } else {
        shiftedCount = 0
      }
      // eslint-disable-next-line no-constant-condition
      while (true) {
        const prevChar = password.charAt(j - 1)
        const adjacents = graph[prevChar] || []
        let found = false
        let foundDirection = -1
        let curDirection = -1
        // consider growing pattern by one character if j hasn't gone over the edge.
        if (j < passwordLength) {
          const curChar = password.charAt(j)
          const adjacentsLength = adjacents.length
          for (let k = 0; k < adjacentsLength; k += 1) {
            const adjacent = adjacents[k]
            curDirection += 1
            if (adjacent) {
              const adjacentIndex = adjacent.indexOf(curChar)
              if (adjacentIndex !== -1) {
                found = true
                foundDirection = curDirection
                if (adjacentIndex === 1) {
                  // # index 1 in the adjacency means the key is shifted,
                  // # 0 means unshifted: A vs a, % vs 5, etc.
                  // # for example, 'q' is adjacent to the entry '2@'.
                  // # @ is shifted w/ index 1, 2 is unshifted.
                  shiftedCount += 1
                }
                if (lastDirection !== foundDirection) {
                  // # adding a turn is correct even in the initial
                  // case when last_direction is null:
                  // # every spatial pattern starts with a turn.
                  turns += 1
                  lastDirection = foundDirection
                }
                break
              }
            }
          }
        }
        // if the current pattern continued, extend j and try to grow again
        if (found) {
          j += 1
          // otherwise push the pattern discovered so far, if any...
        } else {
          // don't consider length 1 or 2 chains.
          if (j - i > 2) {
            matches.push({
              pattern: 'spatial',
              i,
              j: j - 1,
              token: password.slice(i, j),
              graph: graphName,
              turns,
              shifted_count: shiftedCount,
            })
          }
          // ...and then start a new search for the rest of the password.
          i = j
          break
        }
      }
    }
    return matches
  }
}

export default MatchSpatial
