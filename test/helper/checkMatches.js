// eslint-disable-next-line jest/no-export
module.exports = (prefix, matches, patternNames, patterns, ijs, props) => {
  let usedPatternNames = patternNames
  if (typeof patternNames === 'string') {
    usedPatternNames = patterns.map(() => patternNames)
  }
  let isEqualLenArgs =
    usedPatternNames.length === patterns.length &&
    patterns.length === ijs.length

  Object.keys(props).forEach((prop) => {
    const lst = props[prop]
    isEqualLenArgs = isEqualLenArgs && lst.length === patterns.length
  })
  if (!isEqualLenArgs) {
    throw Error('unequal argument lists to check_matches')
  }
  it(`${prefix}: matches.length == ${patterns.length}`, () => {
    expect(matches.length).toEqual(patterns.length)
  })
  for (let k = 0; k < patterns.length - 1; k += 1) {
    const match = matches[k]
    const patternName = usedPatternNames[k]
    const pattern = patterns[k]
    const [i, j] = ijs[k]
    it(`${prefix}: matches[${k}].pattern == '${usedPatternNames}'`, () => {
      expect(match.pattern).toEqual(patternName)
    })
    it(`${prefix}: matches[${k}] should have [i, j] of [${i}, ${j}]`, () => {
      expect([match.i, match.j]).toEqual([i, j])
    })
    it(`${prefix}: matches[${k}].token == '${pattern}'`, () => {
      expect(match.token).toEqual(pattern)
    })

    Object.keys(props).forEach((propName) => {
      const propList = props[propName]
      let propMsg = propList[k]
      if (typeof propMsg === 'string') {
        propMsg = `'${propMsg}'`
      }
      it(`${prefix}: matches[${k}].${propName} == ${propMsg}`, () => {
        expect(match[propName]).toEqual(propList[k])
      })
    })
  }
}
