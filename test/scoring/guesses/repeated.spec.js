import repeatGuesses from '../../../src/scoring/guesses/repeat'
import scoring from '../../../src/scoring'
import MatchOmni from '../../../src/Matching'

const omniMatch = new MatchOmni()
describe('scoring guesses repeated', () => {
  const data = [
    ['aa', 'a', 2],
    ['999', '9', 3],
    ['$$$$', '$', 4],
    ['abab', 'ab', 2],
    ['batterystaplebatterystaplebatterystaple', 'batterystaple', 3],
  ]

  data.forEach(([token, baseToken, repeatCount]) => {
    const baseGuesses = scoring.mostGuessableMatchSequence(
      baseToken,
      omniMatch.match(baseToken),
    ).guesses
    const match = {
      token,
      base_token: baseToken,
      base_guesses: baseGuesses,
      repeat_count: repeatCount,
    }
    it('asd', () => {
      expect(true).toBeTruthy()
    })
    const expectedGuesses = baseGuesses * repeatCount
    const msg = `the repeat pattern '${token}' has guesses of ${expectedGuesses}`

    // eslint-disable-next-line jest/valid-title
    it(msg, () => {
      expect(repeatGuesses(match)).toEqual(expectedGuesses)
    })
  })
})
