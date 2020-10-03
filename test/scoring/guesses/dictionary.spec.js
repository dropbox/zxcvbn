import dictionaryGuesses from '~/scoring/guesses/dictionary'
import l33tVariant from '~/scoring/variant/l33t'
import uppercaseVariant from '~/scoring/variant/uppercase'

describe('scoring: guesses dictionary', () => {
  it('base guesses == the rank', () => {
    const match = {
      token: 'aaaaa',
      rank: 32,
    }
    const result = 32
    expect(dictionaryGuesses(match)).toEqual({
      baseGuesses: 32,
      calculation: result,
      l33tVariations: 1,
      uppercaseVariations: 1,
    })
  })

  it('extra guesses are added for capitalization', () => {
    const match = {
      token: 'AAAaaa',
      rank: 32,
    }
    const result = 32 * uppercaseVariant(match.token)
    expect(dictionaryGuesses(match)).toEqual({
      baseGuesses: 32,
      calculation: result,
      l33tVariations: 1,
      uppercaseVariations: 41,
    })
  })

  it('guesses are doubled when word is reversed', () => {
    const match = {
      token: 'aaa',
      rank: 32,
      reversed: true,
    }
    const result = 32 * 2
    expect(dictionaryGuesses(match)).toEqual({
      baseGuesses: 32,
      calculation: result,
      l33tVariations: 1,
      uppercaseVariations: 1,
    })
  })

  it('extra guesses are added for common l33t substitutions', () => {
    const match = {
      token: 'aaa@@@',
      rank: 32,
      l33t: true,
      sub: {
        '@': 'a',
      },
    }
    const result = 32 * l33tVariant(match)
    expect(dictionaryGuesses(match)).toEqual({
      baseGuesses: 32,
      calculation: result,
      l33tVariations: 41,
      uppercaseVariations: 1,
    })
  })

  it('extra guesses are added for both capitalization and common l33t substitutions', () => {
    const match = {
      token: 'AaA@@@',
      rank: 32,
      l33t: true,
      sub: {
        '@': 'a',
      },
    }
    const result = 32 * l33tVariant(match) * uppercaseVariant(match.token)
    expect(dictionaryGuesses(match)).toEqual({
      baseGuesses: 32,
      calculation: result,
      l33tVariations: 41,
      uppercaseVariations: 3,
    })
  })
})
