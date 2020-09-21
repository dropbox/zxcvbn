export default (match) => {
  const firstChr = match.token.charAt(0)
  let baseGuesses = 0
  const startingPoints = ['a', 'A', 'z', 'Z', '0', '1', '9']
  // lower guesses for obvious starting points
  if (startingPoints.includes(firstChr)) {
    baseGuesses = 4
  } else if (firstChr.match(/\d/)) {
    baseGuesses = 10 // digits
  } else {
    // could give a higher base for uppercase,
    // assigning 26 to both upper and lower sequences is more conservative.
    baseGuesses = 26
  }
  // need to try a descending sequence in addition to every ascending sequence ->
  // 2x guesses
  if (!match.ascending) {
    baseGuesses *= 2
  }
  return baseGuesses * match.token.length
}
