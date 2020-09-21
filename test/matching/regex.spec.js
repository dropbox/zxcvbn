import MatchRegex from '../../src/matching/Regex'
import checkMatches from '../helper/checkMatches'

describe('regex matching', () => {
  const data = [
    ['1922', 'recent_year'],
    ['2017', 'recent_year'],
  ]

  const matchRegex = new MatchRegex()
  data.forEach(([pattern, name]) => {
    const matches = matchRegex.match(pattern)
    const msg = `matches ${pattern} as a ${name} pattern`
    checkMatches(msg, matches, 'regex', [pattern], [[0, pattern.length - 1]], {
      regex_name: [name],
    })
  })
})
