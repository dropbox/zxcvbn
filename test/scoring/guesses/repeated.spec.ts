import repeatGuesses from '~/scoring/guesses/repeat'
import scoring from '~/scoring'
import MatchOmni from '~/Matching'
import Options from '~/Options'

Options.setOptions()

const omniMatch = new MatchOmni()
describe('scoring guesses repeated', () => {
  const data: [string, string, number][] = [
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
      baseToken,
      baseGuesses,
      repeatCount,
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
