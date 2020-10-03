import utils from './scoring/utils'
import estimateGuesses from './scoring/estimate'
import { MIN_GUESSES_BEFORE_GROWING_SEQUENCE } from './data/const'
import { Match, ExtendedMatch } from './types'

const scoringHelper = {
  password: '',
  optimal: {} as any,
  excludeAdditive: false,
  fillArray(size: number, valueType: 'object' | 'array') {
    const result: typeof valueType extends 'array' ? string[] : {}[] = []
    for (let i = 0; i < size; i += 1) {
      let value: [] | {} = []
      if (valueType === 'object') {
        value = {}
      }
      result.push(value)
    }
    return result
  },
  // helper: make bruteforce match objects spanning i to j, inclusive.
  makeBruteforceMatch(i: number, j: number) {
    return {
      pattern: 'bruteforce',
      token: this.password.slice(i, +j + 1 || 9e9),
      i,
      j,
    }
  },
  // helper: considers whether a length-sequenceLength
  // sequence ending at match m is better (fewer guesses)
  // than previously encountered sequences, updating state if so.
  update(match: ExtendedMatch | Match, sequenceLength: number) {
    const k = match.j
    const estimatedMatch = estimateGuesses(match, this.password)
    let pi = estimatedMatch.guesses as number
    if (sequenceLength > 1) {
      // we're considering a length-sequenceLength sequence ending with match m:
      // obtain the product term in the minimization function by multiplying m's guesses
      // by the product of the length-(sequenceLength-1)
      // sequence ending just before m, at m.i - 1.
      pi *= this.optimal.pi[estimatedMatch.i - 1][sequenceLength - 1]
    }
    // calculate the minimization func
    let g = utils.factorial(sequenceLength) * pi
    if (!this.excludeAdditive) {
      g += MIN_GUESSES_BEFORE_GROWING_SEQUENCE ** (sequenceLength - 1)
    }
    // update state if new best.
    // first see if any competing sequences covering this prefix,
    // with sequenceLength or fewer matches,
    // fare better than this sequence. if so, skip it and return.
    let shouldSkip = false
    Object.keys(this.optimal.g[k]).forEach((competingPatternLength) => {
      const competingMetricMatch = this.optimal.g[k][competingPatternLength]
      if (parseInt(competingPatternLength, 10) <= sequenceLength) {
        if (competingMetricMatch <= g) {
          shouldSkip = true
        }
      }
    })
    if (!shouldSkip) {
      // this sequence might be part of the final optimal sequence.
      this.optimal.g[k][sequenceLength] = g
      this.optimal.m[k][sequenceLength] = estimatedMatch
      this.optimal.pi[k][sequenceLength] = pi
    }
  },

  // helper: evaluate bruteforce matches ending at passwordCharIndex.
  bruteforceUpdate(passwordCharIndex: number) {
    // see if a single bruteforce match spanning the passwordCharIndex-prefix is optimal.
    let match = this.makeBruteforceMatch(0, passwordCharIndex) as Match
    this.update(match, 1)
    for (let i = 1; i <= passwordCharIndex; i += 1) {
      // generate passwordCharIndex bruteforce matches, spanning from (i=1, j=passwordCharIndex) up to (i=passwordCharIndex, j=passwordCharIndex).
      // see if adding these new matches to any of the sequences in optimal[i-1]
      // leads to new bests.
      match = this.makeBruteforceMatch(i, passwordCharIndex) as Match
      const tmp = this.optimal.m[i - 1]
      // eslint-disable-next-line no-loop-func
      Object.keys(tmp).forEach((sequenceLength) => {
        const lastMatch = tmp[sequenceLength]
        // corner: an optimal sequence will never have two adjacent bruteforce matches.
        // it is strictly better to have a single bruteforce match spanning the same region:
        // same contribution to the guess product with a lower length.
        // --> safe to skip those cases.
        if (lastMatch.pattern !== 'bruteforce') {
          // try adding m to this length-sequenceLength sequence.
          this.update(match, parseInt(sequenceLength, 10) + 1)
        }
      })
    }
  },

  // helper: step backwards through optimal.m starting at the end,
  // constructing the final optimal match sequence.
  unwind(passwordLength: number) {
    const optimalMatchSequence: Match[] = []
    let k = passwordLength - 1
    // find the final best sequence length and score
    let sequenceLength = 0
    let g = 2e308
    const temp = this.optimal.g[k]
    Object.keys(this.optimal.g[k]).forEach((candidateSequenceLength) => {
      const candidateMetricMatch = temp[candidateSequenceLength]
      if (candidateMetricMatch < g) {
        sequenceLength = parseInt(candidateSequenceLength, 10)
        g = candidateMetricMatch
      }
    })
    while (k >= 0) {
      const match: Match = this.optimal.m[k][sequenceLength]
      optimalMatchSequence.unshift(match)
      k = match.i - 1
      sequenceLength -= 1
    }
    return optimalMatchSequence
  },
}

export default {
  // ------------------------------------------------------------------------------
  // search --- most guessable match sequence -------------------------------------
  // ------------------------------------------------------------------------------
  //
  // takes a sequence of overlapping matches, returns the non-overlapping sequence with
  // minimum guesses. the following is a O(l_max * (n + m)) dynamic programming algorithm
  // for a length-n password with m candidate matches. l_max is the maximum optimal
  // sequence length spanning each prefix of the password. In practice it rarely exceeds 5 and the
  // search terminates rapidly.
  //
  // the optimal "minimum guesses" sequence is here defined to be the sequence that
  // minimizes the following function:
  //
  //    g = sequenceLength! * Product(m.guesses for m in sequence) + D^(sequenceLength - 1)
  //
  // where sequenceLength is the length of the sequence.
  //
  // the factorial term is the number of ways to order sequenceLength patterns.
  //
  // the D^(sequenceLength-1) term is another length penalty, roughly capturing the idea that an
  // attacker will try lower-length sequences first before trying length-sequenceLength sequences.
  //
  // for example, consider a sequence that is date-repeat-dictionary.
  //  - an attacker would need to try other date-repeat-dictionary combinations,
  //    hence the product term.
  //  - an attacker would need to try repeat-date-dictionary, dictionary-repeat-date,
  //    ..., hence the factorial term.
  //  - an attacker would also likely try length-1 (dictionary) and length-2 (dictionary-date)
  //    sequences before length-3. assuming at minimum D guesses per pattern type,
  //    D^(sequenceLength-1) approximates Sum(D^i for i in [1..sequenceLength-1]
  //
  // ------------------------------------------------------------------------------
  mostGuessableMatchSequence(
    password: string,
    matches: ExtendedMatch[],
    excludeAdditive = false,
  ) {
    scoringHelper.password = password
    scoringHelper.excludeAdditive = excludeAdditive
    const passwordLength = password.length
    // partition matches into sublists according to ending index j
    let matchesByCoordinateJ = scoringHelper.fillArray(
      passwordLength,
      'array',
    ) as any[]

    matches.forEach((match) => {
      matchesByCoordinateJ[match.j].push(match)
    })
    // small detail: for deterministic output, sort each sublist by i.
    matchesByCoordinateJ = matchesByCoordinateJ.map((match) =>
      match.sort((m1: Match, m2: Match) => m1.i - m2.i),
    )

    scoringHelper.optimal = {
      // optimal.m[k][sequenceLength] holds final match in the best length-sequenceLength
      // match sequence covering the
      // password prefix up to k, inclusive.
      // if there is no length-sequenceLength sequence that scores better (fewer guesses) than
      // a shorter match sequence spanning the same prefix,
      // optimal.m[k][sequenceLength] is undefined.
      m: scoringHelper.fillArray(passwordLength, 'object'),
      // same structure as optimal.m -- holds the product term Prod(m.guesses for m in sequence).
      // optimal.pi allows for fast (non-looping) updates to the minimization function.
      pi: scoringHelper.fillArray(passwordLength, 'object'),
      // same structure as optimal.m -- holds the overall metric.
      g: scoringHelper.fillArray(passwordLength, 'object'),
    }

    for (let k = 0; k < passwordLength; k += 1) {
      matchesByCoordinateJ[k].forEach((match: ExtendedMatch) => {
        if (match.i > 0) {
          Object.keys(scoringHelper.optimal.m[match.i - 1]).forEach(
            (sequenceLength) => {
              scoringHelper.update(match, parseInt(sequenceLength, 10) + 1)
            },
          )
        } else {
          scoringHelper.update(match, 1)
        }
      })
      scoringHelper.bruteforceUpdate(k)
    }
    const optimalMatchSequence = scoringHelper.unwind(passwordLength)
    const optimalSequenceLength = optimalMatchSequence.length
    let guesses = 0
    if (password.length === 0) {
      guesses = 1
    } else {
      guesses =
        scoringHelper.optimal.g[passwordLength - 1][optimalSequenceLength]
    }
    return {
      password,
      guesses,
      guessesLog10: utils.log10(guesses),
      sequence: optimalMatchSequence,
    }
  },
}
