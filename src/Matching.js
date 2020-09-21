import { extend, sorted } from './helper'
/*
 * -------------------------------------------------------------------------------
 *  Omnimatch combine matchers ---------------------------------------------------------------
 * -------------------------------------------------------------------------------
 */
class Matching {
  constructor(
    {
      dictionary = true,
      spatial = true,
      repeat = true,
      sequence = true,
      regex = true,
      date = true,
    } = {
      dictionary: true,
      spatial: true,
      repeat: true,
      sequence: true,
      regex: true,
      date: true,
    },
  ) {
    this.matchers = []
    this.options = {
      dictionary,
      spatial,
      repeat,
      sequence,
      regex,
      date,
    }
    if (dictionary) {
      // eslint-disable-next-line global-require
      const Dictionary = require('./matching/Dictionary').default
      // eslint-disable-next-line global-require
      const L33t = require('./matching/L33t').default
      // eslint-disable-next-line global-require
      const DictionaryReverse = require('./matching/DictionaryReverse').default
      this.matchers.push({
        name: 'dictionary',
        Class: Dictionary,
        params: ['userInputs', 'dictionary'],
      })

      this.matchers.push({
        name: 'dictionaryReverse',
        Class: DictionaryReverse,
        params: ['userInputs', 'dictionary'],
      })

      this.matchers.push({
        name: 'l33t',
        Class: L33t,
        params: ['userInputs', 'dictionary', 'l33tTable'],
      })
    }
    if (spatial) {
      // eslint-disable-next-line global-require
      const Spatial = require('./matching/Spatial').default

      this.matchers.push({
        name: 'spatial',
        Class: Spatial,
        params: ['graphs'],
      })
    }
    if (repeat) {
      // eslint-disable-next-line global-require
      const Repeat = require('./matching/Repeat').default

      this.matchers.push({
        name: 'repeat',
        Class: Repeat,
        params: [],
      })
    }
    if (sequence) {
      // eslint-disable-next-line global-require
      const Sequence = require('./matching/Sequence').default

      this.matchers.push({
        name: 'sequence',
        Class: Sequence,
        params: [],
      })
    }
    if (regex) {
      // eslint-disable-next-line global-require
      const Regex = require('./matching/Regex').default

      this.matchers.push({
        name: 'regex',
        Class: Regex,
        params: [],
      })
    }
    if (date) {
      // eslint-disable-next-line global-require
      const Date = require('./matching/Date').default

      this.matchers.push({
        name: 'date',
        Class: Date,
        params: [],
      })
    }
  }

  match(password, options) {
    const matches = []
    this.matchers.forEach((entry) => {
      const matcher = new entry.Class(options)
      extend(matches, matcher.match(password))
    })
    return sorted(matches)
  }
}

export default Matching
