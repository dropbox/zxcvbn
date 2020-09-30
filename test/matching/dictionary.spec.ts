import MatchDictionary from '~/matching/Dictionary'
import checkMatches from '../helper/checkMatches'
import genpws from '../helper/genpws'
import Options from '~/Options'

Options.setOptions()

describe('dictionary matching', () => {
  describe('Default dictionary', () => {
    const matchDictionary = new MatchDictionary()
    const matches = matchDictionary.match('wow')
    const patterns = ['wow']
    const msg = 'default dictionaries'
    const ijs = [[0, 2]]
    checkMatches(msg, matches, 'dictionary', patterns, ijs, {
      matchedWord: patterns,
      rank: [322],
      dictionaryName: ['us_tv_and_film'],
    })
  })
  describe('without user input', () => {
    const testDicts = {
      d1: ['motherboard', 'mother', 'board', 'abcd', 'cdef'],
      d2: ['z', '8', '99', '$', 'asdf1234&*'],
    }
    Options.setOptions({
      dictionary: testDicts,
    })
    const matchDictionary = new MatchDictionary({
      userInputs: [],
    })
    const dm = (pw) => matchDictionary.match(pw)
    let matches = dm('motherboard')
    let patterns = ['mother', 'motherboard', 'board']
    let msg = 'matches words that contain other words'
    checkMatches(
      msg,
      matches,
      'dictionary',
      patterns,
      [
        [0, 5],
        [0, 10],
        [6, 10],
      ],
      {
        matchedWord: ['mother', 'motherboard', 'board'],
        rank: [2, 1, 3],
        dictionaryName: ['d1', 'd1', 'd1'],
      },
    )
    matches = dm('abcdef')
    patterns = ['abcd', 'cdef']
    msg = 'matches multiple words when they overlap'
    checkMatches(
      msg,
      matches,
      'dictionary',
      patterns,
      [
        [0, 3],
        [2, 5],
      ],
      {
        matchedWord: ['abcd', 'cdef'],
        rank: [4, 5],
        dictionaryName: ['d1', 'd1'],
      },
    )
    matches = dm('BoaRdZ')
    patterns = ['BoaRd', 'Z']
    msg = 'ignores uppercasing'
    checkMatches(
      msg,
      matches,
      'dictionary',
      patterns,
      [
        [0, 4],
        [5, 5],
      ],
      {
        matchedWord: ['board', 'z'],
        rank: [3, 1],
        dictionaryName: ['d1', 'd2'],
      },
    )

    const prefixes = ['q', '%%']
    const suffixes = ['%', 'qq']
    const testWord = 'asdf1234&*'
    const generatedGenPws = genpws(testWord, prefixes, suffixes)
    generatedGenPws.forEach(([password, i, j]) => {
      matches = dm(password)
      msg = 'identifies words surrounded by non-words'
      checkMatches(msg, matches, 'dictionary', [testWord], [[i, j]], {
        matchedWord: [testWord],
        rank: [5],
        dictionaryName: ['d2'],
      })
    })

    Object.keys(Options.rankedDictionaries).forEach((name) => {
      const dict = Options.rankedDictionaries[name]
      Object.keys(dict).forEach((word) => {
        const rank = dict[word]
        if (word !== 'motherboard') {
          matches = dm(word)
          msg = 'matches against all words in provided dictionaries'
          checkMatches(
            msg,
            matches,
            'dictionary',
            [word],
            [[0, word.length - 1]],
            {
              matchedWord: [word],
              rank: [rank],
              dictionaryName: [name],
            },
          )
        }
      })
    })
  })

  describe('with user input', () => {
    const matchDictionary = new MatchDictionary({
      userInputs: ['foo', 'bar'],
    })
    const matches = matchDictionary
      .match('foobar')
      .filter((match) => match.dictionaryName === 'userInputs')

    const msg = 'matches with provided user input dictionary'
    checkMatches(
      msg,
      matches,
      'dictionary',
      ['foo', 'bar'],
      [
        [0, 2],
        [3, 5],
      ],
      {
        matchedWord: ['foo', 'bar'],
        rank: [1, 2],
      },
    )
  })
})
