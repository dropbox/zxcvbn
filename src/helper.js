export const empty = (obj) => Object.keys(obj).length === 0

export const extend = (listToExtend, list) =>
  // eslint-disable-next-line prefer-spread
  listToExtend.push.apply(listToExtend, list)

export const translate = (string, chrMap) => {
  const tempArray = string.split('')
  return tempArray.map((char) => chrMap[char] || char).join('')
}

// mod implementation that works for negative numbers
export const mod = (n, m) => ((n % m) + m) % m

// sort on i primary, j secondary
export const sorted = (matches) =>
  matches.sort((m1, m2) => m1.i - m2.i || m1.j - m2.j)

export const buildRankedDictionary = (orderedList) => {
  const result = {}
  let counter = 1 // rank starts at 1, not 0
  orderedList.forEach((word) => {
    result[word] = counter
    counter += 1
  })
  return result
}
