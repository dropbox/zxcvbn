import Options from './Options'

/*
 * -------------------------------------------------------------------------------
 *  Estimates time for an attacker ---------------------------------------------------------------
 * -------------------------------------------------------------------------------
 */
class TimeEstimates {
  translate(displayStr, value, displayNum) {
    let key = displayStr
    if (displayNum != null && displayNum !== 1) {
      key += 's'
    }
    return Options.translations.timeEstimation[key].replace('{base}', value)
  }

  estimateAttackTimes(guesses) {
    const crackTimesSeconds = {
      onlineThrottling100PerHour: guesses / (100 / 3600),
      onlineThrottling10PerSecond: guesses / 10,
      offlineSlowHashing1e4PerSecond: guesses / 1e4,
      offlineFastHashing1e10PerSecond: guesses / 1e10,
    }
    const crackTimesDisplay = {}
    Object.keys(crackTimesSeconds).forEach((scenario) => {
      const seconds = crackTimesSeconds[scenario]
      crackTimesDisplay[scenario] = this.displayTime(seconds)
    })
    return {
      crackTimesSeconds,
      crackTimesDisplay,
      score: this.guessesToScore(guesses),
    }
  }

  guessesToScore(guesses) {
    const DELTA = 5
    if (guesses < 1e3 + DELTA) {
      return 0
    }
    if (guesses < 1e6 + DELTA) {
      return 1
    }
    if (guesses < 1e8 + DELTA) {
      return 2
    }
    if (guesses < 1e10 + DELTA) {
      return 3
    }
    return 4
  }

  displayTime(seconds) {
    const minute = 60
    const hour = minute * 60
    const day = hour * 24
    const month = day * 31
    const year = month * 12
    const century = year * 100
    let displayNum = null
    let displayStr = 'centuries'
    let base = ''
    if (seconds < 1) {
      displayNum = null
      displayStr = 'ltSecond'
    } else if (seconds < minute) {
      base = Math.round(seconds)
      displayNum = base
      displayStr = 'second'
    } else if (seconds < hour) {
      base = Math.round(seconds / minute)
      displayNum = base
      displayStr = 'minute'
    } else if (seconds < day) {
      base = Math.round(seconds / hour)
      displayNum = base
      displayStr = 'hour'
    } else if (seconds < month) {
      base = Math.round(seconds / day)
      displayNum = base
      displayStr = 'day'
    } else if (seconds < year) {
      base = Math.round(seconds / month)
      displayNum = base
      displayStr = 'month'
    } else if (seconds < century) {
      base = Math.round(seconds / year)
      displayNum = base
      displayStr = 'year'
    }
    return this.translate(displayStr, base, displayNum)
  }
}

export default TimeEstimates
