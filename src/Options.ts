import translationKeys from '~/data/feedback/keys'
import { buildRankedDictionary } from '~/helper'
import {
  TranslationKeys,
  Keyboards,
  Keypads,
  LooseObject,
  OptionsType,
  FrequencyLists,
  DefaultAdjacencyGraphsKeys,
  OptionsL33tTable,
  OptionsDictionary,
  OptionsGraph,
} from '~/types'
import l33tTable from '~/data/l33tTable'
import frequencyLists from '~/data/frequency_lists'
import translationsEn from '~/data/feedback/en'
import graphs from '~/data/adjacency_graphs'

class Options {
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
    if (options.usedKeyboard) {
      this.usedKeyboard = options.usedKeyboard
    }

    if (options.usedKeypad) {
      this.usedKeypad = options.usedKeypad
    }

    if (options.l33tTable) {
      this.l33tTable = options.l33tTable
    } else {
      this.l33tTable = l33tTable
    }

    if (options.dictionary) {
      this.dictionary = options.dictionary
    } else {
      this.dictionary = frequencyLists
    }

    if (options.translations) {
      this.setTranslations(options.translations)
    } else {
      this.setTranslations(translationsEn)
    }

    if (options.graphs) {
      this.setAdjacencyGraphs(options.graphs)
    } else {
      this.setAdjacencyGraphs(graphs)
    }

    this.setRankedDictionaries()
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
