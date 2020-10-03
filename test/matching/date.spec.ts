import MatchDate from '~/matching/Date'
import checkMatches from '../helper/checkMatches'
import genpws from '../helper/genpws'

describe('date matching', () => {
  const matchDate = new MatchDate()
  let password
  let matches
  let msg
  let data = ['', ' ', '-', '/', '\\', '_', '.']
  data.forEach((sep) => {
    password = `13${sep}2${sep}1921`
    matches = matchDate.match(password)
    msg = `matches dates that use '${sep}' as a separator`
    checkMatches(msg, matches, 'date', [password], [[0, password.length - 1]], {
      separator: [sep],
      year: [1921],
      month: [2],
      day: [13],
    })
  })

  data = ['mdy', 'dmy', 'ymd', 'ydm']
  data.forEach((order) => {
    const [d, m, y] = [8, 8, 88]
    password = order
      .replace('y', `${y}`)
      .replace('m', `${m}`)
      .replace('d', `${d}`)
    matches = matchDate.match(password)
    msg = `matches dates with '${order}' format`
    checkMatches(msg, matches, 'date', [password], [[0, password.length - 1]], {
      separator: [''],
      year: [1988],
      month: [8],
      day: [8],
    })
  })

  password = '111504'
  matches = matchDate.match(password)
  msg = 'matches the date with year closest to REFERENCE_YEAR when ambiguous'
  checkMatches(msg, matches, 'date', [password], [[0, password.length - 1]], {
    separator: [''],
    year: [2004],
    month: [11],
    day: [15],
  })

  const numberData = [
    [1, 1, 1999],
    [11, 8, 2000],
    [9, 12, 2005],
    [22, 11, 1551],
  ]
  numberData.forEach(([day, month, year]) => {
    password = `${year}${month}${day}`
    matches = matchDate.match(password)
    msg = `matches ${password}`
    checkMatches(msg, matches, 'date', [password], [[0, password.length - 1]], {
      separator: [''],
      year: [year],
    })
    password = `${year}.${month}.${day}`
    matches = matchDate.match(password)
    msg = `matches ${password}`
    checkMatches(msg, matches, 'date', [password], [[0, password.length - 1]], {
      separator: ['.'],
      year: [year],
    })
  })

  password = '02/02/02'
  matches = matchDate.match(password)
  msg = 'matches zero-padded dates'
  checkMatches(msg, matches, 'date', [password], [[0, password.length - 1]], {
    separator: ['/'],
    year: [2002],
    month: [2],
    day: [2],
  })

  const prefixes = ['a', 'ab']
  const suffixes = ['!']
  const pattern = '1/1/91'
  data = genpws(pattern, prefixes, suffixes)

  data.forEach(([dataPassword, i, j]) => {
    matches = matchDate.match(dataPassword)
    msg = 'matches embedded dates'
    checkMatches(msg, matches, 'date', [pattern], [[i, j]], {
      year: [1991],
      month: [1],
      day: [1],
    })
  })

  matches = matchDate.match('12/20/1991.12.20')
  msg = 'matches overlapping dates'
  checkMatches(
    msg,
    matches,
    'date',
    ['12/20/1991', '1991.12.20'],
    [
      [0, 9],
      [6, 15],
    ],
    {
      separator: ['/', '.'],
      year: [1991, 1991],
      month: [12, 12],
      day: [20, 20],
    },
  )

  matches = matchDate.match('912/20/919')
  msg = 'matches dates padded by non-ambiguous digits'
  checkMatches(msg, matches, 'date', ['12/20/91'], [[1, 8]], {
    separator: ['/'],
    year: [1991],
    month: [12],
    day: [20],
  })
})
