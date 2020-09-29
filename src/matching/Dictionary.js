import { sorted, buildRankedDictionary } from '~/helper'
import Options from '~/Options'

class MatchDictionary {
  constructor(
    { userInputs = [] } = {
      userInputs: [],
    },
  ) {
    this.rankedDictionaries = Options.rankedDictionaries
    this.rankedDictionaries.userInputs = buildRankedDictionary(
      userInputs.slice(),
    )
  }

  match(password) {
    // rankedDictionaries variable is for unit testing purposes
    const matches = []
    const passwordLength = password.length
    const passwordLower = password.toLowerCase()
    Object.keys(this.rankedDictionaries).forEach((dictionaryName) => {
      const rankedDict = this.rankedDictionaries[dictionaryName]
      for (let i = 0; i < passwordLength; i += 1) {
        for (let j = i; j < passwordLength; j += 1) {
          if (passwordLower.slice(i, +j + 1 || 9e9) in rankedDict) {
            const word = passwordLower.slice(i, +j + 1 || 9e9)
            const rank = rankedDict[word]
            matches.push({
              pattern: 'dictionary',
              i,
              j,
              token: password.slice(i, +j + 1 || 9e9),
              matchedWord: word,
              rank,
              dictionaryName,
              reversed: false,
              l33t: false,
            })
          }
        }
      }
    })
    return sorted(matches)
  }
}

export default MatchDictionary
