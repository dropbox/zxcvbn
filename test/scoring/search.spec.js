import scoring from '~/scoring'
import Options from '~/Options'

Options.setOptions()

describe('scoring search', () => {
  const getMatch = (i, j, guesses) => ({
    i,
    j,
    guesses,
  })
  const excludeAdditive = true
  const password = '0123456789'

  describe('returns one bruteforce match given an empty match sequence:', () => {
    const result = scoring.mostGuessableMatchSequence(password, [])
    const firstSequence = result.sequence[0]

    it('result.length == 1', () => {
      expect(result.sequence.length).toEqual(1)
    })

    it("match.pattern == 'bruteforce'", () => {
      expect(firstSequence.pattern).toEqual('bruteforce')
    })

    it(`match.token == ${password}`, () => {
      expect(firstSequence.token).toEqual(password)
    })

    it(`[i, j] == [${firstSequence.i}, ${firstSequence.j}]`, () => {
      expect([firstSequence.i, firstSequence.j]).toEqual([0, 9])
    })
  })

  describe('returns match + bruteforce when match covers a prefix of password:', () => {
    const matches = [getMatch(0, 5, 1)]
    const firstMatch = matches[0]
    const result = scoring.mostGuessableMatchSequence(
      password,
      matches,
      excludeAdditive,
    )
    const secondSequence = result.sequence[1]

    it('result.match.sequence.length == 2', () => {
      expect(result.sequence.length).toEqual(2)
    })

    it('first match is the provided match object', () => {
      expect(result.sequence[0]).toEqual(firstMatch)
    })

    it('second match is bruteforce', () => {
      expect(secondSequence.pattern).toEqual('bruteforce')
    })

    it('second match covers full suffix after first match', () => {
      expect([secondSequence.i, secondSequence.j]).toEqual([6, 9])
    })
  })

  describe('returns bruteforce + match when match covers a suffix:', () => {
    const matches = [getMatch(3, 9, 1)]
    const firstMatch = matches[0]
    const result = scoring.mostGuessableMatchSequence(
      password,
      matches,
      excludeAdditive,
    )
    const firstSequence = result.sequence[0]

    it('result.match.sequence.length == 2', () => {
      expect(result.sequence.length).toEqual(2)
    })

    it('first match is bruteforce', () => {
      expect(firstSequence.pattern).toEqual('bruteforce')
    })

    it('first match covers full prefix before second match', () => {
      expect([firstSequence.i, firstSequence.j]).toEqual([0, 2])
    })

    it('second match is the provided match object', () => {
      expect(result.sequence[1]).toEqual(firstMatch)
    })
  })

  describe('returns bruteforce + match + bruteforce when match covers an infix:', () => {
    const matches = [getMatch(1, 8, 1)]
    const result = scoring.mostGuessableMatchSequence(
      password,
      matches,
      excludeAdditive,
    )
    const firstSequence = result.sequence[0]
    const thirdSequence = result.sequence[2]

    it('irst match is bruteforce', () => {
      expect(firstSequence.pattern).toEqual('bruteforce')
    })

    it('third match is bruteforce', () => {
      expect(thirdSequence.pattern).toEqual('bruteforce')
    })

    it('first match covers full prefix before second match', () => {
      expect([firstSequence.i, firstSequence.j]).toEqual([0, 0])
    })

    it('third match covers full suffix after second match', () => {
      expect([thirdSequence.i, thirdSequence.j]).toEqual([9, 9])
    })
  })

  describe('chooses lower-guesses match given two matches of the same span:', () => {
    const matches = [getMatch(0, 9, 1), getMatch(0, 9, 2)]
    const firstMatch = matches[0]
    const secondMatch = matches[1]
    let result = scoring.mostGuessableMatchSequence(
      password,
      matches,
      excludeAdditive,
    )

    it('result.length == 1', () => {
      expect(result.sequence.length).toEqual(1)
    })

    // TODO make this better `it` will be triggered after
    //  `firstMatch.guesses = 3` and will fail because of it
    const backupFirstMatch = JSON.parse(JSON.stringify(firstMatch))
    const backupSequence = JSON.parse(JSON.stringify(result.sequence[0]))
    it('result.sequence[0] == m0', () => {
      expect(backupSequence).toEqual(backupFirstMatch)
    })

    firstMatch.guesses = 3
    result = scoring.mostGuessableMatchSequence(
      password,
      matches,
      excludeAdditive,
    )

    it('result.sequence[0] == m1', () => {
      expect(result.sequence[0]).toEqual(secondMatch)
    })
  })

  describe('covers correctly', () => {
    const matches = [getMatch(0, 9, 3), getMatch(0, 3, 2), getMatch(4, 9, 1)]
    const firstMatch = matches[0]
    const secondMatch = matches[1]
    const thirdMatch = matches[2]

    describe('when m0 covers m1 and m2, choose [m0] when m0 < m1 * m2 * fact(2):', () => {
      const result = scoring.mostGuessableMatchSequence(
        password,
        matches,
        excludeAdditive,
      )
      it('total guesses == 3', () => {
        expect(result.guesses).toEqual(3)
      })

      it('sequence is [m0]', () => {
        expect(result.sequence).toEqual([firstMatch])
      })
    })

    describe('when m0 covers m1 and m2, choose [m1, m2] when m0 > m1 * m2 * fact(2):', () => {
      firstMatch.guesses = 5
      const result = scoring.mostGuessableMatchSequence(
        password,
        matches,
        excludeAdditive,
      )
      it('total guesses == 4', () => {
        expect(result.guesses).toEqual(4)
      })

      it('sequence is [m1, m2]', () => {
        expect(result.sequence).toEqual([secondMatch, thirdMatch])
      })
    })
  })
})
