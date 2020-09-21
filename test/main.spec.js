import zxcvbn from '../src/main'
import translations from '../src/data/feedback/en'
import passwordTests from './helper/passwordTests'

describe('main', () => {
  it('should check without userInput', () => {
    const result = zxcvbn('test')
    expect(result.calc_time).toBeDefined()
    delete result.calc_time
    expect(result).toEqual({
      crackTimesDisplay: {
        offline_fast_hashing_1e10_per_second: 'less than a second',
        offline_slow_hashing_1e4_per_second: 'less than a second',
        online_no_throttling_10_per_second: '9 seconds',
        online_throttling_100_per_hour: '56 minutes',
      },
      crackTimesSeconds: {
        offline_fast_hashing_1e10_per_second: 9.4e-9,
        offline_slow_hashing_1e4_per_second: 0.0094,
        online_no_throttling_10_per_second: 9.4,
        online_throttling_100_per_hour: 3384,
      },
      feedback: {
        suggestions: [translations.suggestions.anotherWord],
        warning: translations.warnings.topHundred,
      },
      guesses: 94,
      guesses_log10: 1.9731278535996983,
      password: 'test',
      score: 0,
      sequence: [
        {
          base_guesses: 93,
          dictionary_name: 'passwords',
          guesses: 93,
          guesses_log10: 1.968482948553935,
          i: 0,
          j: 3,
          l33t: false,
          l33t_variations: 1,
          matched_word: 'test',
          pattern: 'dictionary',
          rank: 93,
          reversed: false,
          token: 'test',
          uppercase_variations: 1,
        },
      ],
    })
  })

  it('should check with userInput', () => {
    const result = zxcvbn('test', ['test', 12, true, []])
    delete result.calc_time
    expect(result).toEqual({
      crackTimesDisplay: {
        offline_fast_hashing_1e10_per_second: 'less than a second',
        offline_slow_hashing_1e4_per_second: 'less than a second',
        online_no_throttling_10_per_second: 'less than a second',
        online_throttling_100_per_hour: '1 minute',
      },
      crackTimesSeconds: {
        offline_fast_hashing_1e10_per_second: 2e-10,
        offline_slow_hashing_1e4_per_second: 0.0002,
        online_no_throttling_10_per_second: 0.2,
        online_throttling_100_per_hour: 72,
      },
      feedback: {
        suggestions: [translations.suggestions.anotherWord],
        warning: '',
      },
      guesses: 2,
      guesses_log10: 0.30102999566398114,
      password: 'test',
      score: 0,
      sequence: [
        {
          base_guesses: 1,
          dictionary_name: 'userInputs',
          guesses: 1,
          guesses_log10: 0,
          i: 0,
          j: 3,
          l33t: false,
          l33t_variations: 1,
          matched_word: 'test',
          pattern: 'dictionary',
          rank: 1,
          reversed: false,
          token: 'test',
          uppercase_variations: 1,
        },
      ],
    })
  })

  describe('password tests', () => {
    passwordTests.forEach((data) => {
      it(`should resolve ${data.password}`, () => {
        const result = zxcvbn(data.password)
        delete result.calc_time
        expect(JSON.stringify(result)).toEqual(JSON.stringify(data.result))
      })
    })
  })
})
