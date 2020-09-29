import dateSplits from './dateSplits'

export const DATE_MAX_YEAR = 2050
export const DATE_MIN_YEAR = 1000
export const DATE_SPLITS = dateSplits
export const BRUTEFORCE_CARDINALITY = 10
export const MIN_GUESSES_BEFORE_GROWING_SEQUENCE = 10000
export const MIN_SUBMATCH_GUESSES_SINGLE_CHAR = 10
export const MIN_SUBMATCH_GUESSES_MULTI_CHAR = 50
export const MIN_YEAR_SPACE = 20
// \xbf-\xdf is a range for almost all special uppercase letter like Ä and so on
export const START_UPPER = /^[A-Z\xbf-\xdf][^A-Z\xbf-\xdf]+$/
export const END_UPPER = /^[^A-Z\xbf-\xdf]+[A-Z\xbf-\xdf]$/
// \xdf-\xff is a range for almost all special lowercase letter like ä and so on
export const ALL_UPPER = /^[A-Z\xbf-\xdf]+$/
export const ALL_UPPER_INVERTED = /^[^a-z\xdf-\xff]+$/
export const ALL_LOWER = /^[a-z\xdf-\xff]+$/
export const ALL_LOWER_INVERTED = /^[^A-Z\xbf-\xdf]+$/
export const ONE_UPPER = /[a-z\xdf-\xff]/
export const ONE_LOWER = /[A-Z\xbf-\xdf]/
export const ALPHA_INVERTED = /[^A-Za-z\xbf-\xdf]/gi
export const ALL_DIGIT = /^\d+$/
export const REFERENCE_YEAR = new Date().getFullYear()
export const REGEXEN = { recentYear: /19\d\d|200\d|201\d|202\d/g }
