export default (orderedList) => {
  const result = {}
  let counter = 1 // rank starts at 1, not 0
  orderedList.forEach((word) => {
    result[word] = counter
    counter += 1
  })
  return result
}
