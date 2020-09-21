export default {
  // binomial coefficients
  // src: http://blog.plover.com/math/choose.html
  nCk(n, k) {
    let count = n
    if (k > count) {
      return 0
    }
    if (k === 0) {
      return 1
    }
    let coEff = 1
    for (let i = 1; i <= k; i += 1) {
      coEff *= count
      coEff /= i
      count -= 1
    }
    return coEff
  },
  log10(n) {
    return Math.log(n) / Math.log(10) // IE doesn't support Math.log10 :(
  },
  log2(n) {
    return Math.log(n) / Math.log(2)
  },
  factorial(num) {
    let rval = 1
    for (let i = 2; i <= num; i += 1) rval *= i
    return rval
  },
}
