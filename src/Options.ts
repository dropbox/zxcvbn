import translationKeys from '~/data/feedback/keys'
import { buildRankedDictionary } from '~/helper'
import {
  TranslationKeys,
  Keyboards,
  Keypads,
  LooseObject,
  OptionsMatcher,
  OptionsType,
  FrequencyLists,
  DefaultAdjacencyGraphsKeys,
  OptionsL33tTable,
  OptionsDictionary,
  OptionsGraph,
} from '~/types'

class Options {
  matcher: OptionsMatcher = {
    dictionary: true,
    spatial: true,
    repeat: true,
    sequence: true,
    regex: true,
    date: true,
  }

  // @ts-ignore
  l33tTable: OptionsL33tTable

  // @ts-ignore
  dictionary: OptionsDictionary

  // @ts-ignore
  rankedDictionaries: FrequencyLists

  usedKeyboard: Keyboards = 'qwerty'

  usedKeypad: Keypads = 'keypad'

  // @ts-ignore
  translations: TranslationKeys

  // @ts-ignore
  graphs: OptionsGraph

  availableGraphs: DefaultAdjacencyGraphsKeys[] = []

  keyboardAverageDegree = 0

  keypadAverageDegree = 0

  keyboardStartingPositions = 0

  keypadStartingPositions = 0

  setOptions(options: OptionsType = {}) {
    if (options.matcher) {
      this.matcher = {
        ...this.matcher,
        ...options.matcher,
      }
    }

    if (options.usedKeyboard) {
      this.usedKeyboard = options.usedKeyboard
    }

    if (options.usedKeypad) {
      this.usedKeypad = options.usedKeypad
    }

    if (options.l33tTable) {
      this.l33tTable = options.l33tTable
    } else {
      // eslint-disable-next-line global-require
      this.l33tTable = require('./data/l33tTable').default
    }

    if (options.dictionary) {
      this.dictionary = options.dictionary
    } else {
      // eslint-disable-next-line global-require
      this.dictionary = require('./data/frequency_lists').default
    }

    if (options.translations) {
      this.setTranslations(options.translations)
    } else {
      // eslint-disable-next-line global-require
      const translations = require('./data/feedback/en').default
      this.setTranslations(translations)
    }

    if (options.graphs) {
      this.setAdjacencyGraphs(options.graphs)
    } else {
      // eslint-disable-next-line global-require
      const graphs = require('./data/adjacency_graphs').default
      this.setAdjacencyGraphs(graphs)
    }

    if (this.matcher.dictionary) {
      this.setRankedDictionaries()
    }
  }

  setTranslations(translations: TranslationKeys) {
    if (this.checkCustomTranslations(translations)) {
      this.translations = translations
    } else {
      throw new Error('Invalid translations object fallback to keys')
    }
  }

  checkCustomTranslations(translations: TranslationKeys) {
    let valid = true
    Object.keys(translationKeys).forEach((type) => {
      if (type in translations) {
        Object.keys(translationKeys[type]).forEach((key) => {
          if (!(key in translations[type])) {
            valid = false
          }
        })
      } else {
        valid = false
      }
    })
    return valid
  }

  setRankedDictionaries() {
    const rankedDictionaries: LooseObject = {}
    Object.keys(this.dictionary).forEach((name) => {
      const list = this.dictionary[name]
      rankedDictionaries[name] = buildRankedDictionary(list)
    })
    this.rankedDictionaries = rankedDictionaries as FrequencyLists
  }

  setAdjacencyGraphs(adjacencyGraphs: OptionsGraph) {
    if (adjacencyGraphs) {
      this.graphs = adjacencyGraphs
      this.availableGraphs = Object.keys(
        adjacencyGraphs,
      ) as DefaultAdjacencyGraphsKeys[]
      if (adjacencyGraphs[this.usedKeyboard]) {
        this.keyboardAverageDegree = this.calcAverageDegree(
          // @ts-ignore
          adjacencyGraphs[this.usedKeyboard],
        )
        this.keyboardStartingPositions = Object.keys(
          adjacencyGraphs[this.usedKeyboard],
        ).length
      }
      if (adjacencyGraphs[this.usedKeypad]) {
        this.keypadAverageDegree = this.calcAverageDegree(
          // @ts-ignore
          adjacencyGraphs[this.usedKeypad],
        )

        this.keypadStartingPositions = Object.keys(
          adjacencyGraphs[this.usedKeypad],
        ).length
      }
    }
  }

  calcAverageDegree(graph: OptionsGraph) {
    let average = 0
    Object.keys(graph).forEach((key) => {
      const neighbors = graph[key]
      average += Object.entries(neighbors).length
    })
    average /= Object.entries(graph).length
    return average
  }
}

export default new Options()
