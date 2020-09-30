import MatchRegex from '~/matching/Regex'
import checkMatches from '../helper/checkMatches'

describe('regex matching', () => {
  const data = [
    ['1922', 'recentYear'],
    ['2017', 'recentYear'],
  ]

  const matchRegex = new MatchRegex()
  data.forEach(([pattern, name]) => {
    const matches = matchRegex.match(pattern)
    const msg = `matches ${pattern} as a ${name} pattern`
    checkMatches(msg, matches, 'regex', [pattern], [[0, pattern.length - 1]], {
      regexName: [name],
    })
  })
})
