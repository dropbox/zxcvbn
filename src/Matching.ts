import { extend, sorted } from './helper'
import Dictionary from './matching/Dictionary'
import L33t from './matching/L33t'
import DictionaryReverse from './matching/DictionaryReverse'
import Spatial from './matching/Spatial'
import Repeat from './matching/Repeat'
import Sequence from './matching/Sequence'
import Regex from './matching/Regex'
import Date from './matching/Date'

/*
 * -------------------------------------------------------------------------------
 *  Omnimatch combine matchers ---------------------------------------------------------------
 * -------------------------------------------------------------------------------
 */

class Matching {
  matchers: any[] = [
    Dictionary,
    DictionaryReverse,
    L33t,
    Spatial,
    Repeat,
    Sequence,
    Regex,
    Date,
  ]

  options = {}

  match(password: string, options: any = {}) {
    const matches: any[] = []
    this.matchers.forEach((Entry) => {
      const matcher = new Entry(options)
      extend(matches, matcher.match(password))
    })
    return sorted(matches)
  }
}

export default Matching
