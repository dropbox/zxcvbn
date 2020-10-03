import Options from '~/Options'
import translationsKeys from '~/data/feedback/keys'

describe('Options', () => {
  describe('translations', () => {
    it('should return default feedback for no sequence on custom translations', () => {
      Options.setOptions({ translations: translationsKeys })
      expect(Options.translations).toEqual(translationsKeys)
    })
    const customTranslations = {
      warnings: {
        straightRow: 'straightRow',
        keyPattern: 'keyPattern',
      },
    }

    it('should return error for wrong custom translations', () => {
      expect(() => {
        // @ts-ignore
        Options.setOptions({ translations: customTranslations })
      }).toThrow('Invalid translations object fallback to keys')
    })
  })

  it('should set custom keyboard', () => {
    Options.setOptions({ usedKeyboard: 'someKeyboard' })
    expect(Options.usedKeyboard).toEqual('someKeyboard')
  })

  it('should set custom keypad', () => {
    Options.setOptions({ usedKeypad: 'someKeypad' })
    expect(Options.usedKeypad).toEqual('someKeypad')
  })
})
