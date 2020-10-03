import defaultAdjacencyGraphs from '~/data/adjacency_graphs'
import frequencyLists from '~/data/frequency_lists'
import translationKeys from '~/data/feedback/keys'
import l33tTableDefault from '~/data/l33tTable'

export type DefaultAdjacencyGraphsKeys = keyof typeof defaultAdjacencyGraphs
export type DefaultAdjacencyGraphs = typeof defaultAdjacencyGraphs
export type TranslationKeys = typeof translationKeys
export type L33tTableDefault = typeof l33tTableDefault
export type FrequencyLists = typeof frequencyLists

export interface LooseObject {
  [key: string]: any
}

export type Pattern =
  | 'dictionary'
  | 'regex'
  | 'repeat'
  | 'bruteforce'
  | 'sequence'
  | 'spatial'
  | 'date'

export type DictionaryNames =
  | 'passwords'
  | 'maleNames'
  | 'femaleNames'
  | 'tvAndFilm'
  | 'wikipedia'
  | 'surnames'
  | 'userInputs'

export interface Match {
  pattern: Pattern
  i: number
  j: number
  token: string
}

export interface ExtendedMatch {
  pattern: Pattern
  i: number
  j: number
  token: string
  matchedWord: string
  rank: number
  dictionaryName: DictionaryNames
  reversed: boolean
  l33t: boolean
  baseGuesses: number
  uppercaseVariations: number
  l33tVariations: number
  guesses: number
  guessesLog10: number
  turns: number
  baseToken: string[] | string
  sub?: LooseObject
  subDisplay?: string
  sequenceName?: 'lower' | 'digits'
  sequenceSpace?: number
  ascending?: boolean
  regexName?:
    | 'recentYear'
    | 'alphaLower'
    | 'alphaUpper'
    | 'alpha'
    | 'alphanumeric'
    | 'digits'
    | 'symbols'
  shiftedCount?: number
  graph?: DefaultAdjacencyGraphsKeys
  repeatCount?: number
  regexMatch?: string[]
  year: number
  month: number
  day: number
  separator?: string
}

export interface Optimal {
  m: Match
  pi: Match
  g: Match
}

export interface CrackTimesSeconds {
  onlineThrottling100PerHour: number
  onlineThrottling10PerSecond: number
  offlineSlowHashing1e4PerSecond: number
  offlineFastHashing1e10PerSecond: number
}

export interface CrackTimesDisplay {
  onlineThrottling100PerHour: string
  onlineThrottling10PerSecond: string
  offlineSlowHashing1e4PerSecond: string
  offlineFastHashing1e10PerSecond: string
}

export interface FeedbackType {
  warning: string
  suggestions: string[]
}

export type MatchingMatcherParams =
  | 'userInputs'
  | 'dictionary'
  | 'l33tTable'
  | 'graphs'

export type MatchingMatcherNames =
  | 'dictionary'
  | 'dictionaryReverse'
  | 'l33t'
  | 'spatial'
  | 'repeat'
  | 'sequence'
  | 'regex'
  | 'date'

export type Keyboards =
  | 'qwerty'
  | 'qwertz'
  | 'qwertz_altgr'
  | 'qwertz_altgr_shift'
  | 'dvorak'
  | string

export type Keypads = 'keypad' | 'mac_keypad' | string

export type OptionsL33tTable =
  | L33tTableDefault
  | {
      [key: string]: string[]
    }
export type OptionsDictionary =
  | FrequencyLists
  | {
      [key: string]: string[] | number[]
    }
export type OptionsGraph =
  | DefaultAdjacencyGraphs
  | {
      [key: string]: {
        [key: string]: string[]
      }
    }
export interface OptionsType {
  translations?: TranslationKeys
  graphs?: OptionsGraph
  usedKeyboard?: Keyboards
  usedKeypad?: Keypads
  l33tTable?: OptionsL33tTable
  dictionary?: OptionsDictionary
}
