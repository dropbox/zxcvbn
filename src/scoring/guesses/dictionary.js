import uppercaseVariant from '../variant/uppercase'
import l33tVariant from '../variant/l33t'

// TODO remove reference
export default (match) => {
  const baseGuesses = match.rank // keep these as properties for display purposes
  const uppercaseVariations = uppercaseVariant(match)
  const l33tVariations = l33tVariant(match)
  const reversedVariations = (match.reversed && 2) || 1
  const calculation =
    baseGuesses * uppercaseVariations * l33tVariations * reversedVariations
  return {
    baseGuesses,
    uppercaseVariations,
    l33tVariations,
    calculation,
  }
}
