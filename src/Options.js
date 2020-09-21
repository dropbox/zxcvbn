import feedbackKeys from '~/data/feedback/keys'
import defaultAdjacencyGraphs from '~/data/adjacency_graphs'
import { buildRankedDictionary } from '~/helper'
import defaultTranslations from '~/data/feedback/en'
import frequencyLists from '~/data/frequency_lists'
import l33tTableDefault from '~/data/l33tTable'

export const defaultOptions = {
  translations: defaultTranslations,
  graphs: defaultAdjacencyGraphs,
  usedKeyboard: 'qwerty',
  usedKeypad: 'keypad',
  l33tTable: l33tTableDefault,
  dictionary: frequencyLists,
  matcher: {
    dictionary: true,
    spatial: true,
    repeat: true,
    sequence: true,
    regex: true,
    date: true,
  },
}

class Options {
  constructor() {
    this.setOptions()
  }

  setOptions(options = {}) {
    const usedOptions = {
      ...defaultOptions,
      ...options,
    }

    this.l33tTable = usedOptions.l33tTable
    this.dictionary = usedOptions.dictionary
    this.usedKeyboard = usedOptions.usedKeyboard
    this.usedKeypad = usedOptions.usedKeypad

    if (usedOptions.translations) {
      this.setTranslations(usedOptions.translations)
    }

    this.setAdjacencyGraphs(usedOptions.graphs)

    if (usedOptions.matcher.dictionary) {
      this.setRankedDictionaries()
    }
  }

  setTranslations(translations) {
    if (this.checkCustomTranslations(translations)) {
      this.translations = translations
    } else {
      throw new Error('Invalid translations object fallback to keys')
    }
  }

  checkCustomTranslations(translations) {
    let valid = true
    Object.keys(feedbackKeys).forEach((type) => {
      if (type in translations) {
        Object.keys(feedbackKeys[type]).forEach((key) => {
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
    const rankedDictionaries = {}
    Object.keys(this.dictionary).forEach((name) => {
      const list = this.dictionary[name]
      rankedDictionaries[name] = buildRankedDictionary(list)
    })
    this.rankedDictionaries = rankedDictionaries
  }

  setAdjacencyGraphs(adjacencyGraphs) {
    this.graphs = adjacencyGraphs
    this.availbableGraphs = []
    this.keyboardAverageDegree = 0
    this.keypadAverageDegree = 0
    this.keyboardStartingPositions = 0
    this.keypadStartingPositions = 0
    if (adjacencyGraphs) {
      this.availbableGraphs = Object.keys(adjacencyGraphs)
      if (adjacencyGraphs[this.usedKeyboard]) {
        this.keyboardAverageDegree = this.calcAverageDegree(
          adjacencyGraphs[this.usedKeyboard],
        )
        this.keyboardStartingPositions = Object.keys(
          adjacencyGraphs[this.usedKeyboard],
        ).length
      }
      if (adjacencyGraphs[this.usedKeypad]) {
        this.keypadAverageDegree = this.calcAverageDegree(
          adjacencyGraphs[this.usedKeypad],
        )

        this.keypadStartingPositions = Object.keys(
          adjacencyGraphs[this.usedKeypad],
        ).length
      }
    }
  }

  calcAverageDegree(graph) {
    let average = 0
    for (const key in graph) {
      const neighbors = graph[key]
      average += Object.entries(neighbors).length
    }
    average /= Object.entries(graph).length
    return average
  }
}

export default new Options()
