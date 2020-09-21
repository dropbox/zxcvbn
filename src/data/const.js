import dateSplits from './dateSplits'

export const DATE_MAX_YEAR = 2050
export const DATE_MIN_YEAR = 1000
export const DATE_SPLITS = dateSplits
export const BRUTEFORCE_CARDINALITY = 10
export const MIN_GUESSES_BEFORE_GROWING_SEQUENCE = 10000
export const MIN_SUBMATCH_GUESSES_SINGLE_CHAR = 10
export const MIN_SUBMATCH_GUESSES_MULTI_CHAR = 50
export const MIN_YEAR_SPACE = 20
export const START_UPPER = /^[A-Z][^A-Z]+$/
export const END_UPPER = /^[^A-Z]+[A-Z]$/
export const ALL_UPPER = /^[^a-z]+$/
export const ALL_LOWER = /^[^A-Z]+$/

export const REFERENCE_YEAR = new Date().getFullYear()
export const REGEXEN = {recent_year: /19\d\d|200\d|201\d/g}
