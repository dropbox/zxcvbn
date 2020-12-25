import { SimpleListGenerator } from './_generators/SimpleListGenerator'
import { PasswordGenerator } from './_generators/PasswordGenerator'
import { registerList, registerCustomList, run } from './_helpers/runtime'

registerList(
  'en',
  'commonWords',
  'https://github.com/hermitdave/FrequencyWords/raw/master/content/2018/en/en_50k.txt',
  SimpleListGenerator,
  { hasOccurrences: true },
)
registerList(
  'en',
  'firstnames',
  'https://raw.githubusercontent.com/dominictarr/random-name/master/first-names.txt',
  SimpleListGenerator,
)
registerList(
  'en',
  'lastnames',
  'https://raw.githubusercontent.com/arineng/arincli/master/lib/last-names.txt',
  SimpleListGenerator,
)

registerList(
  'de',
  'commonWords',
  'https://raw.githubusercontent.com/hermitdave/FrequencyWords/master/content/2018/de/de_50k.txt',
  SimpleListGenerator,
  { hasOccurrences: true },
)
registerList(
  'de',
  'firstnames',
  'https://gist.githubusercontent.com/hrueger/2aa48086e9720ee9b87ec734889e1b15/raw',
  SimpleListGenerator,
)
registerList(
  'de',
  'lastnames',
  'https://gist.githubusercontent.com/hrueger/6599d1ac1e03b4c3dc432d722ffcefd0/raw',
  SimpleListGenerator,
)

registerCustomList('common', 'passwords', PasswordGenerator)
run()
