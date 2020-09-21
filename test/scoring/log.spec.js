import utils from '../../src/scoring/utils'

const { log2 } = utils
const { log10 } = utils
const EPSILON = 1e-10
const truncateFloat = (float) => Math.round(float / EPSILON) * EPSILON

describe('scoring: utils log', () => {
  it('log2 should calculate correctly', () => {
    const data = [
      [1, 0],
      [2, 1],
      [4, 2],
      [32, 5],
    ]

    data.forEach(([n, result]) => {
      expect(log2(n)).toEqual(result)
    })
  })

  it('log10 should calculate correctly', () => {
    const data = [
      [1, 0],
      [10, 1],
      [100, 2],
    ]

    data.forEach(([n, result]) => {
      expect(log10(n)).toEqual(result)
    })
  })

  const firstNumber = 17
  const secondNumber = 4
  const approxEqual = (actual, expected) => {
    const calculation = truncateFloat(actual)
    const result = truncateFloat(expected)
    expect(calculation).toEqual(result)
  }
  it('product rule', () => {
    const calculation = log10(firstNumber * secondNumber)
    const result = log10(firstNumber) + log10(secondNumber)
    approxEqual(calculation, result)
  })

  it('quotient rule', () => {
    const calculation = log10(firstNumber / secondNumber)
    const result = log10(firstNumber) - log10(secondNumber)
    approxEqual(calculation, result)
  })

  it('base switch rule', () => {
    const calculation = log10(Math.E)
    const result = 1 / Math.log(10)
    approxEqual(calculation, result)
  })

  it('power rule', () => {
    const calculation = log10(firstNumber ** secondNumber)
    const result = secondNumber * log10(firstNumber)
    approxEqual(calculation, result)
  })

  it('base rule', () => {
    const calculation = log10(firstNumber)
    const result = Math.log(firstNumber) / Math.log(10)
    approxEqual(calculation, result)
  })
})
