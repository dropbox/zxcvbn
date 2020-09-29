import uppercaseVariant from '../variant/uppercase'
import l33tVariant from '../variant/l33t'

export default ({ rank, reversed, l33t, sub, token }) => {
  const baseGuesses = rank // keep these as properties for display purposes
  const uppercaseVariations = uppercaseVariant(token)
  const l33tVariations = l33tVariant({ l33t, sub, token })
  const reversedVariations = (reversed && 2) || 1
  const calculation =
    baseGuesses * uppercaseVariations * l33tVariations * reversedVariations
  return {
    baseGuesses,
    uppercaseVariations,
    l33tVariations,
    calculation,
  }
}
