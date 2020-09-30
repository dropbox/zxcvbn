import utils from '~/scoring/utils'

const { nCk } = utils

describe('scoring: utils nck', () => {
  it('should calculate correctly', () => {
    const data = [
      [0, 0, 1],
      [1, 0, 1],
      [5, 0, 1],
      [0, 1, 0],
      [0, 5, 0],
      [2, 1, 2],
      [4, 2, 6],
      [33, 7, 4272048],
    ]

    data.forEach(([n, k, result]) => {
      expect(nCk(n, k)).toEqual(result)
    })
  })

  it('should mirror identity', () => {
    const n = 49
    const k = 12
    const calculation = nCk(n, k)
    const result = nCk(n, n - k)
    expect(calculation).toEqual(result)
  })

  it("should pascal's triangle identity", () => {
    const n = 49
    const k = 12
    const calculation = nCk(n, k)
    const result = nCk(n - 1, k - 1) + nCk(n - 1, k)
    expect(calculation).toEqual(result)
  })
})
