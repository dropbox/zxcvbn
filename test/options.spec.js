import Options from '~/Options'
import translationsKeys from '~/data/feedback/keys'

describe('Options', () => {
  describe('with custom translations', () => {
    it('should return default feedback for no sequence', () => {
      Options.setOptions({ translations: translationsKeys })
      expect(Options.translations).toEqual(translationsKeys)
    })
  })

  describe('with wrong custom translations', () => {
    const customTranslations = {
      warnings: {
        straightRow: 'straightRow',
        keyPattern: 'keyPattern',
      },
    }

    it('should return error', () => {
      expect(() => {
        // eslint-disable-next-line no-new
        Options.setOptions({ translations: customTranslations })
      }).toThrow('Invalid translations object fallback to keys')
    })
  })
})
