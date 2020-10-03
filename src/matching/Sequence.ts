import { ALL_UPPER, ALL_LOWER, ALL_DIGIT } from '~/data/const'

type UpdateParams = {
  i: number
  j: number
  delta: number
  password: string
  result: any[]
}
/*
 *-------------------------------------------------------------------------------
 * sequences (abcdef) ------------------------------
 *-------------------------------------------------------------------------------
 */
class MatchSequence {
  MAX_DELTA = 5

  match(password: string) {
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
    const result: any[] = []
    if (password.length === 1) {
      return []
    }
    let i = 0
    let lastDelta: number | null = null
    const passwordLength = password.length
    for (let k = 1; k < passwordLength; k += 1) {
      const delta = password.charCodeAt(k) - password.charCodeAt(k - 1)
      if (lastDelta == null) {
        lastDelta = delta
      }
      if (delta !== lastDelta) {
        const j = k - 1
        this.update({
          i,
          j,
          delta: lastDelta,
          password,
          result,
        })
        i = j
        lastDelta = delta
      }
    }
    this.update({
      i,
      j: passwordLength - 1,
      delta: lastDelta as number,
      password,
      result,
    })
    return result
  }

  update({ i, j, delta, password, result }: UpdateParams) {
    if (j - i > 1 || Math.abs(delta) === 1) {
      const absoluteDelta = Math.abs(delta)
      if (absoluteDelta > 0 && absoluteDelta <= this.MAX_DELTA) {
        const token = password.slice(i, +j + 1 || 9e9)
        // TODO conservatively stick with roman alphabet size.
        //  (this could be improved)
        let sequenceName = 'unicode'
        let sequenceSpace = 26

        if (ALL_LOWER.test(token)) {
          sequenceName = 'lower'
          sequenceSpace = 26
        } else if (ALL_UPPER.test(token)) {
          sequenceName = 'upper'
          sequenceSpace = 26
        } else if (ALL_DIGIT.test(token)) {
          sequenceName = 'digits'
          sequenceSpace = 10
        }
        return result.push({
          pattern: 'sequence',
          i,
          j,
          token: password.slice(i, +j + 1 || 9e9),
          sequenceName,
          sequenceSpace,
          ascending: delta > 0,
        })
      }
    }
    return null
  }
}

export default MatchSequence
