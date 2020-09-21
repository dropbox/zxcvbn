module.exports = (pattern, prefixes, suffixes) => {
  const result = []
  const slicedPrefixes = prefixes.slice()
  const slicedSuffixes = suffixes.slice()
  ;[slicedPrefixes, slicedSuffixes].forEach((lst) => {
    if (lst.indexOf('') === -1) {
      lst.unshift('')
    }
  })
  slicedPrefixes.forEach((prefix) => {
    slicedSuffixes.forEach((suffix) => {
      const [i, j] = [prefix.length, prefix.length + pattern.length - 1]
      result.push([prefix + pattern + suffix, i, j])
    })
  })
  return result
}
