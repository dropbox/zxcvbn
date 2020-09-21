/*
 *-------------------------------------------------------------------------------
 * sequences (abcdef) ------------------------------
 *-------------------------------------------------------------------------------
 */
class MatchSequence {
  constructor() {
    this.MAX_DELTA = 5
  }

  match(password) {
    /*
     * Identifies sequences by looking for repeated differences in unicode codepoint.
     * this allows skipping, such as 9753, and also matches some extended unicode sequences
     * such as Greek and Cyrillic alphabets.
     *
     * for example, consider the input 'abcdb975zy'
     *
     * password: a   b   c   d   b    9   7   5   z   y
     * index:    0   1   2   3   4    5   6   7   8   9
     * delta:      1   1   1  -2  -41  -2  -2  69   1
     *
     * expected result:
     * [(i, j, delta), ...] = [(0, 3, 1), (5, 7, -2), (8, 9, 1)]
     */
    const result = []
    if (password.length === 1) {
      return []
    }
    // TODO move out of function
    const update = (i, j, delta) => {
      if (j - i > 1 || Math.abs(delta) === 1) {
        const absoluteDelta = Math.abs(delta)
        if (absoluteDelta > 0 && absoluteDelta <= this.MAX_DELTA) {
          const token = password.slice(i, +j + 1 || 9e9)
          // conservatively stick with roman alphabet size.
          // (this could be improved)
          let sequenceName = 'unicode'
          let sequenceSpace = 26

          if (/^[a-z]+$/.test(token)) {
            sequenceName = 'lower'
            sequenceSpace = 26
          } else if (/^[A-Z]+$/.test(token)) {
            sequenceName = 'upper'
            sequenceSpace = 26
          } else if (/^\d+$/.test(token)) {
            sequenceName = 'digits'
            sequenceSpace = 10
          }
          return result.push({
            pattern: 'sequence',
            i,
            j,
            token: password.slice(i, +j + 1 || 9e9),
            sequence_name: sequenceName,
            sequence_space: sequenceSpace,
            ascending: delta > 0,
          })
        }
      }
      return null
    }
    let i = 0
    let lastDelta = null
    const passwordLength = password.length
    for (let k = 1; k < passwordLength; k += 1) {
      const delta = password.charCodeAt(k) - password.charCodeAt(k - 1)
      if (lastDelta == null) {
        lastDelta = delta
      }
      if (delta !== lastDelta) {
        const j = k - 1
        update(i, j, lastDelta)
        i = j
        lastDelta = delta
      }
    }
    update(i, passwordLength - 1, lastDelta)
    return result
  }
}

export default MatchSequence
