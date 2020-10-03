import {
  DATE_MAX_YEAR,
  DATE_MIN_YEAR,
  DATE_SPLITS,
  REFERENCE_YEAR,
} from '~/data/const'
import { sorted } from '~/helper'
import { ExtendedMatch } from '../types'

/*
 * -------------------------------------------------------------------------------
 *  date matching ----------------------------------------------------------------
 * -------------------------------------------------------------------------------
 */
class MatchDate {
  match(password: string) {
    /*
     * a "date" is recognized as:
     *   any 3-tuple that starts or ends with a 2- or 4-digit year,
     *   with 2 or 0 separator chars (1.1.91 or 1191),
     *   maybe zero-padded (01-01-91 vs 1-1-91),
     *   a month between 1 and 12,
     *   a day between 1 and 31.
     *
     * note: this isn't true date parsing in that "feb 31st" is allowed,
     * this doesn't check for leap years, etc.
     *
     * recipe:
     * start with regex to find maybe-dates, then attempt to map the integers
     * onto month-day-year to filter the maybe-dates into dates.
     * finally, remove matches that are substrings of other matches to reduce noise.
     *
     * note: instead of using a lazy or greedy regex to find many dates over the full string,
     * this uses a ^...$ regex against every substring of the password -- less performant but leads
     * to every possible date match.
     */
    const metric = (candidate: ExtendedMatch) =>
      Math.abs(candidate.year - REFERENCE_YEAR)
    const matches: ExtendedMatch[] = []
    const maybeDateNoSeparator = /^\d{4,8}$/
    const maybeDateWithSeparator = /^(\d{1,4})([\s/\\_.-])(\d{1,2})\2(\d{1,4})$/

    // # dates without separators are between length 4 '1191' and 8 '11111991'
    for (let i = 0; i <= Math.abs(password.length - 4); i += 1) {
      for (let j = i + 3; j <= i + 7; j += 1) {
        if (j >= password.length) {
          break
        }
        const token = password.slice(i, +j + 1 || 9e9)
        if (maybeDateNoSeparator.exec(token)) {
          const candidates: any[] = []
          const index = token.length
          const splittedDates = DATE_SPLITS[index]
          // @ts-ignore
          splittedDates.forEach(([k, l]) => {
            const dmy = this.mapIntegersToDayMonthYear([
              parseInt(token.slice(0, k), 10),
              parseInt(token.slice(k, l), 10),
              parseInt(token.slice(l), 10),
            ])
            if (dmy != null) {
              candidates.push(dmy)
            }
          })
          if (candidates.length > 0) {
            /*
             * at this point: different possible dmy mappings for the same i,j substring.
             * match the candidate date that likely takes the fewest guesses: a year closest
             * to 2000.
             * (scoring.REFERENCE_YEAR).
             *
             * ie, considering '111504', prefer 11-15-04 to 1-1-1504
             * (interpreting '04' as 2004)
             */
            let bestCandidate = candidates[0]
            let minDistance = metric(candidates[0])
            candidates.slice(1).forEach((candidate) => {
              const distance = metric(candidate)
              if (distance < minDistance) {
                bestCandidate = candidate
                minDistance = distance
              }
            })
            // @ts-ignore
            matches.push({
              pattern: 'date',
              token,
              i,
              j,
              separator: '',
              year: bestCandidate.year,
              month: bestCandidate.month,
              day: bestCandidate.day,
            })
          }
        }
      }
    }

    // # dates with separators are between length 6 '1/1/91' and 10 '11/11/1991'
    for (let i = 0; i <= Math.abs(password.length - 6); i += 1) {
      for (let j = i + 5; j <= i + 9; j += 1) {
        if (j >= password.length) {
          break
        }
        const token = password.slice(i, +j + 1 || 9e9)
        const regexMatch = maybeDateWithSeparator.exec(token)
        if (regexMatch != null) {
          const dmy = this.mapIntegersToDayMonthYear([
            parseInt(regexMatch[1], 10),
            parseInt(regexMatch[3], 10),
            parseInt(regexMatch[4], 10),
          ])
          if (dmy != null) {
            matches.push({
              pattern: 'date',
              token,
              i,
              j,
              separator: regexMatch[2],
              // @ts-ignore
              year: dmy.year,
              month: dmy.month,
              day: dmy.day,
            })
          }
        }
      }
    }
    /*
     * matches now contains all valid date strings in a way that is tricky to capture
     * with regexes only. while thorough, it will contain some unintuitive noise:
     *
     * '2015_06_04', in addition to matching 2015_06_04, will also contain
     * 5(!) other date matches: 15_06_04, 5_06_04, ..., even 2015 (matched as 5/1/2020)
     *
     * to reduce noise, remove date matches that are strict substrings of others
     */
    const filteredMatches = matches.filter((match) => {
      let isSubmatch = false
      const matchesLength = matches.length
      for (let o = 0; o < matchesLength; o += 1) {
        const otherMatch = matches[o]
        if (match !== otherMatch) {
          if (otherMatch.i <= match.i && otherMatch.j >= match.j) {
            isSubmatch = true
            break
          }
        }
      }
      return !isSubmatch
    })
    return sorted(filteredMatches)
  }

  mapIntegersToDayMonthYear(integers: number[]) {
    /*
     * given a 3-tuple, discard if:
     *   middle int is over 31 (for all dmy formats, years are never allowed in the middle)
     *   middle int is zero
     *   any int is over the max allowable year
     *   any int is over two digits but under the min allowable year
     *   2 integers are over 31, the max allowable day
     *   2 integers are zero
     *   all integers are over 12, the max allowable month
     */
    if (integers[1] > 31 || integers[1] <= 0) {
      return null
    }
    let over12 = 0
    let over31 = 0
    let under1 = 0
    for (let o = 0, len1 = integers.length; o < len1; o += 1) {
      const int = integers[o]
      if ((int > 99 && int < DATE_MIN_YEAR) || int > DATE_MAX_YEAR) {
        return null
      }
      if (int > 31) {
        over31 += 1
      }
      if (int > 12) {
        over12 += 1
      }
      if (int <= 0) {
        under1 += 1
      }
    }
    if (over31 >= 2 || over12 === 3 || under1 >= 2) {
      return null
    }
    // first look for a four digit year: yyyy + daymonth or daymonth + yyyy
    const possibleYearSplits = [
      [integers[2], integers.slice(0, 2)], // year last
      [integers[0], integers.slice(1, 3)], // year first
    ]

    const possibleYearSplitsLength = possibleYearSplits.length
    for (let j = 0; j < possibleYearSplitsLength; j += 1) {
      const [y, rest] = possibleYearSplits[j]
      if (DATE_MIN_YEAR <= y && y <= DATE_MAX_YEAR) {
        // @ts-ignore
        const dm = this.mapIntegersToDayMonth(rest)
        if (dm != null) {
          return {
            year: y,
            month: dm.month,
            day: dm.day,
          }
        }
        /*
         * for a candidate that includes a four-digit year,
         * when the remaining integers don't match to a day and month,
         * it is not a date.
         */
        return null
      }
    }
    // given no four-digit year, two digit years are the most flexible int to match, so
    // try to parse a day-month out of integers[0..1] or integers[1..0]
    for (let k = 0; k < possibleYearSplitsLength; k += 1) {
      const [y, rest] = possibleYearSplits[k]
      // @ts-ignore
      const dm = this.mapIntegersToDayMonth(rest)
      if (dm != null) {
        return {
          // @ts-ignore
          year: this.twoToFourDigitYear(y),
          month: dm.month,
          day: dm.day,
        }
      }
    }
    return null
  }

  mapIntegersToDayMonth(integers: number[]) {
    const temp = [integers, integers.slice().reverse()]
    for (let i = 0; i < temp.length; i += 1) {
      const data = temp[i]
      const day = data[0]
      const month = data[1]
      if (day >= 1 && day <= 31 && month >= 1 && month <= 12) {
        return {
          day,
          month,
        }
      }
    }
    return null
  }

  twoToFourDigitYear(year: number) {
    if (year > 99) {
      return year
    }
    if (year > 50) {
      // 87 -> 1987
      return year + 1900
    }
    // 15 -> 2015
    return year + 2000
  }
}

export default MatchDate
