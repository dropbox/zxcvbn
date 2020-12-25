import fs from 'fs'
import byline from 'byline'
import sprintfClass from 'sprintf-js'
import Matching from '../../src/Matching'
import estimateGuesses from '../../src/scoring/estimate'
import Options from '~/Options'

const CUTOFF = 10
const BATCH_SIZE = 1000000

const sprintf = sprintfClass.sprintf
Options.setOptions()
const matching = new Matching()

const normalize = (token) => {
  return token.toLowerCase()
}

// GET file from https://xato.net/today-i-am-releasing-ten-million-passwords-b6278bbe7495

export class PasswordGenerator {
  public data: any = []

  private shouldInclude(password, xatoRank) {
    for (let i = 0; i < password.length; i += 1) {
      if (password.charCodeAt(i) > 127) {
        console.log(
          'SKIPPING non-ascii password=' + password + ', rank=' + xatoRank,
        )
        return false
      }
    }
    let matches = matching.match(password).filter((match) => {
      return match.i === 0 && match.j === password.length - 1
    })

    for (const match of matches) {
      if (estimateGuesses(match, password) < xatoRank) {
        return false
      }
    }
    return true
  }

  private static prune(counts) {
    const results: (boolean | undefined)[] = []
    for (let pw in counts) {
      const count = counts[pw]
      if (count === 1) {
        results.push(delete counts[pw])
      } else {
        results.push(void 0)
      }
    }
    return results
  }

  public async run(output: string) {
    return new Promise((resolve) => {
      const counts = {}
      let skippedLines = 0
      let lineCount = 0
      const xatoFileName = 'xato_file.txt'

      const input = `${__dirname}/${xatoFileName}`
      const stream = byline.createStream(
        fs.createReadStream(input, {
          encoding: 'utf8',
        }),
      )
      stream.on('readable', () => {
        let line
        const results: number[] = []
        while (null !== (line = stream.read())) {
          lineCount += 1
          if (lineCount % BATCH_SIZE === 0) {
            console.log('counting tokens:', lineCount)
            PasswordGenerator.prune(counts)
          }
          const tokens = line.trim().split(/\s+/)
          if (tokens.length !== 2) {
            skippedLines += 1
            continue
          }
          const combo = tokens.slice(0, 2)
          const password = normalize(combo[1])

          if (password in counts) {
            counts[password] += 1
            results.push()
          } else {
            counts[password] = 1
          }
          results.push(counts[password])
        }
        return results
      })
      return stream.on('end', () => {
        console.log('skipped lines:', skippedLines)
        let pairs: [string, number][] = []
        console.log('copying to tuples')
        for (let pw in counts) {
          const count = counts[pw]
          if (count > CUTOFF) {
            pairs.push([pw, count])
          }
          delete counts[pw]
        }
        console.log('sorting')
        pairs.sort((p1, p2) => {
          return p2[1] - p1[1]
        })
        console.log('filtering')
        pairs = pairs.filter((pair, i) => {
          const [password] = pair
          const rank = i + 1
          return this.shouldInclude(password, rank)
        })
        const outputStreamTxt = fs.createWriteStream(`${output}.txt`, {
          encoding: 'utf8',
        })
        pairs.forEach((pair) => {
          const [pw, count] = pair
          outputStreamTxt.write(sprintf('%-15s %d\n', pw, count))
        })
        outputStreamTxt.end()

        const outputStreamJson = fs.createWriteStream(`${output}.json`, {
          encoding: 'utf8',
        })
        outputStreamJson.write('[')
        const pairLength = pairs.length
        pairs.forEach((pair, index) => {
          const [pw] = pair
          const isLast = pairLength === index + 1
          const comma = isLast ? '' : ','
          outputStreamJson.write(`"${pw}"${comma}`)
        })

        outputStreamJson.write(']')
        outputStreamJson.end()

        resolve()
      })
    })
  }
}
