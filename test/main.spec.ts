import zxcvbn from '../src/main'
import translations from '../src/data/feedback/en'
import passwordTests from './helper/passwordTests'
import Options from '~/Options'

Options.setOptions()

describe('main', () => {
  it('should check without userInputs', () => {
    const result = zxcvbn('test')
    expect(result.calcTime).toBeDefined()
    delete result.calcTime
    expect(result).toEqual({
      crackTimesDisplay: {
        offlineFastHashing1e10PerSecond: 'less than a second',
        offlineSlowHashing1e4PerSecond: 'less than a second',
        onlineThrottling10PerSecond: '9 seconds',
        onlineThrottling100PerHour: '56 minutes',
      },
      crackTimesSeconds: {
        offlineFastHashing1e10PerSecond: 9.4e-9,
        offlineSlowHashing1e4PerSecond: 0.0094,
        onlineThrottling10PerSecond: 9.4,
        onlineThrottling100PerHour: 3384,
      },
      feedback: {
        suggestions: [translations.suggestions.anotherWord],
        warning: translations.warnings.topHundred,
      },
      guesses: 94,
      guessesLog10: 1.9731278535996983,
      password: 'test',
      score: 0,
      sequence: [
        {
          baseGuesses: 93,
          dictionaryName: 'passwords',
          guesses: 93,
          guessesLog10: 1.968482948553935,
          i: 0,
          j: 3,
          l33t: false,
          l33tVariations: 1,
          matchedWord: 'test',
          pattern: 'dictionary',
          rank: 93,
          reversed: false,
          token: 'test',
          uppercaseVariations: 1,
        },
      ],
    })
  })

  it('should check with userInputs', () => {
    const result = zxcvbn('test', ['test', 12, true, []])
    delete result.calcTime
    expect(result).toEqual({
      crackTimesDisplay: {
        offlineFastHashing1e10PerSecond: 'less than a second',
        offlineSlowHashing1e4PerSecond: 'less than a second',
        onlineThrottling10PerSecond: 'less than a second',
        onlineThrottling100PerHour: '1 minute',
      },
      crackTimesSeconds: {
        offlineFastHashing1e10PerSecond: 2e-10,
        offlineSlowHashing1e4PerSecond: 0.0002,
        onlineThrottling10PerSecond: 0.2,
        onlineThrottling100PerHour: 72,
      },
      feedback: {
        suggestions: [translations.suggestions.anotherWord],
        warning: '',
      },
      guesses: 2,
      guessesLog10: 0.30102999566398114,
      password: 'test',
      score: 0,
      sequence: [
        {
          baseGuesses: 1,
          dictionaryName: 'userInputs',
          guesses: 1,
          guessesLog10: 0,
          i: 0,
          j: 3,
          l33t: false,
          l33tVariations: 1,
          matchedWord: 'test',
          pattern: 'dictionary',
          rank: 1,
          reversed: false,
          token: 'test',
          uppercaseVariations: 1,
        },
      ],
    })
  })

  describe('password tests', () => {
    passwordTests.forEach((data) => {
      it(`should resolve ${data.password}`, () => {
        const result = zxcvbn(data.password)
        delete result.calcTime
        expect(JSON.stringify(result)).toEqual(JSON.stringify(data.result))
      })
    })
  })
})
