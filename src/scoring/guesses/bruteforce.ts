import {
  BRUTEFORCE_CARDINALITY,
  MIN_SUBMATCH_GUESSES_SINGLE_CHAR,
  MIN_SUBMATCH_GUESSES_MULTI_CHAR,
} from '~/data/const'

export default ({ token }) => {
  let guesses = BRUTEFORCE_CARDINALITY ** token.length
  if (guesses === Number.POSITIVE_INFINITY) {
    guesses = Number.MAX_VALUE
  }
  let minGuesses
  // small detail: make bruteforce matches at minimum one guess bigger than smallest allowed
  // submatch guesses, such that non-bruteforce submatches over the same [i..j] take precedence.
  if (token.length === 1) {
    minGuesses = MIN_SUBMATCH_GUESSES_SINGLE_CHAR + 1
  } else {
    minGuesses = MIN_SUBMATCH_GUESSES_MULTI_CHAR + 1
  }

  return Math.max(guesses, minGuesses)
}
