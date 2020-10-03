import { START_UPPER, ALL_UPPER_INVERTED } from './data/const'
import Options from './Options'
import { ExtendedMatch, FeedbackType } from './types'

/*
 * -------------------------------------------------------------------------------
 *  Generate feedback ---------------------------------------------------------------
 * -------------------------------------------------------------------------------
 */
class Feedback {
  defaultFeedback: FeedbackType = {
    warning: '',
    suggestions: [],
  }

  constructor() {
    this.setDefaultSuggestions()
  }

  setDefaultSuggestions() {
    this.defaultFeedback.suggestions.push(
      Options.translations.suggestions.useWords,
      Options.translations.suggestions.noNeed,
    )
  }

  getFeedback(score: number, sequence: ExtendedMatch[]) {
    if (sequence.length === 0) {
      return this.defaultFeedback
    }
    if (score > 2) {
      return {
        warning: '',
        suggestions: [],
      }
    }
    let longestMatch = sequence[0]
    const slicedSequence = sequence.slice(1)
    slicedSequence.forEach((match: ExtendedMatch) => {
      if (match.token.length > longestMatch.token.length) {
        longestMatch = match
      }
    })
    let feedback = this.getMatchFeedback(longestMatch, sequence.length === 1)
    const extraFeedback = Options.translations.suggestions.anotherWord
    if (feedback !== null && feedback !== undefined) {
      feedback.suggestions.unshift(extraFeedback)
      if (feedback.warning == null) {
        feedback.warning = ''
      }
    } else {
      feedback = {
        warning: '',
        suggestions: [extraFeedback],
      }
    }
    return feedback
  }

  getMatchFeedback(match: ExtendedMatch, isSoleMatch: Boolean) {
    let warning

    switch (match.pattern) {
      case 'dictionary':
        return this.getDictionaryMatchFeedback(match, isSoleMatch)
      case 'spatial':
        warning = Options.translations.warnings.keyPattern
        if (match.turns === 1) {
          warning = Options.translations.warnings.straightRow
        }
        return {
          warning,
          suggestions: [Options.translations.suggestions.longerKeyboardPattern],
        }
      case 'repeat':
        warning = Options.translations.warnings.extendedRepeat
        if (match.baseToken.length === 1) {
          warning = Options.translations.warnings.simpleRepeat
        }

        return {
          warning,
          suggestions: [Options.translations.suggestions.repeated],
        }
      case 'sequence':
        return {
          warning: Options.translations.warnings.sequences,
          suggestions: [Options.translations.suggestions.sequences],
        }
      case 'regex':
        if (match.regexName === 'recentYear') {
          return {
            warning: Options.translations.warnings.recentYears,
            suggestions: [
              Options.translations.suggestions.recentYears,
              Options.translations.suggestions.associatedYears,
            ],
          }
        }
        break
      case 'date':
        return {
          warning: Options.translations.warnings.dates,
          suggestions: [Options.translations.suggestions.dates],
        }
      default:
        return {
          warning: '',
          suggestions: [],
        }
    }
    return {
      warning: '',
      suggestions: [],
    }
  }

  getDictionaryMatchFeedback(match: ExtendedMatch, isSoleMatch: Boolean) {
    let warning = ''
    const suggestions: string[] = []
    const word = match.token
    const dictName = match.dictionaryName
    if (dictName === 'passwords') {
      if (isSoleMatch && !match.l33t && !match.reversed) {
        if (match.rank <= 10) {
          warning = Options.translations.warnings.topTen
        } else if (match.rank <= 100) {
          warning = Options.translations.warnings.topHundred
        } else {
          warning = Options.translations.warnings.common
        }
      } else if (match.guessesLog10 <= 4) {
        warning = Options.translations.warnings.similarToCommon
      }
    } else if (dictName.includes('wikipedia')) {
      if (isSoleMatch) {
        warning = Options.translations.warnings.wordByItself
      }
    } else if (
      dictName === 'surnames' ||
      dictName === 'maleNames' ||
      dictName === 'femaleNames'
    ) {
      if (isSoleMatch) {
        warning = Options.translations.warnings.namesByThemselves
      } else {
        warning = Options.translations.warnings.commonNames
      }
    }

    if (word.match(START_UPPER)) {
      suggestions.push(Options.translations.suggestions.capitalization)
    } else if (word.match(ALL_UPPER_INVERTED) && word.toLowerCase() !== word) {
      suggestions.push(Options.translations.suggestions.allUppercase)
    }
    if (match.reversed && match.token.length >= 4) {
      suggestions.push(Options.translations.suggestions.reverseWords)
    }
    if (match.l33t) {
      suggestions.push(Options.translations.suggestions.l33t)
    }
    return {
      warning,
      suggestions,
    }
  }
}

export default Feedback
