test = require 'tape'
feedback = require '../src/feedback'

test 'default feedback messages', (t) ->

  check_feedback = (f, expected_warning, expected_suggestions) ->
    t.equal f.warning, expected_warning
    t.deepEqual f.suggestions, expected_suggestions

  # empty password
  f = feedback.get_feedback(0, [])
  check_feedback(f, '', ["Use a few words, avoid common phrases", "No need for symbols, digits, or uppercase letters"])

  # safely unguessable password
  f = feedback.get_feedback(3, new Array(1))
  check_feedback(f, '', [])

  # very unguessable password
  f = feedback.get_feedback(4, new Array(1))
  check_feedback(f, '', [])

  match =
    token: 'token'

  # -- dictionary match -- #
  match.pattern = 'dictionary'

  # passwords dictionary
  match.dictionary_name = 'passwords'

  # capitalized password with sole match with top10 pattern
  f = feedback.get_feedback(1, [Object.assign {}, match, {token: 'Capitalizedtoken', rank: 10}])
  check_feedback(f, 'This is a top-10 common password', ['Add another word or two. Uncommon words are better.', 'Capitalization doesn\'t help very much'])

  # uppercase password with sole match with top100 pattern
  f = feedback.get_feedback(1, [Object.assign {}, match, {token: 'UPPERCASETOKEN', rank: 100}])
  check_feedback(f, 'This is a top-100 common password', ['Add another word or two. Uncommon words are better.', 'All-uppercase is almost as easy to guess as all-lowercase'])

  # sole match with > top100 pattern
  f = feedback.get_feedback(1, [Object.assign {}, match, rank: 101])
  check_feedback(f, 'This is a very common password', ['Add another word or two. Uncommon words are better.'])

  # top password with l33t substitutions
  f = feedback.get_feedback(1, [Object.assign {}, match, {l33t: true, guesses_log10: 4}])
  check_feedback(f, 'This is similar to a commonly used password', ['Add another word or two. Uncommon words are better.', 'Predictable substitutions like \'@\' instead of \'a\' don\'t help very much'])

  f = feedback.get_feedback(1, [Object.assign {}, match, {reversed: true, guesses_log10: 4}])
  check_feedback(f, 'This is similar to a commonly used password', ['Add another word or two. Uncommon words are better.', 'Reversed words aren\'t much harder to guess'])

  # english_wikipedia dictionary
  match.dictionary_name = 'english_wikipedia'
  f = feedback.get_feedback(1, [match])
  check_feedback(f, 'A word by itself is easy to guess', ['Add another word or two. Uncommon words are better.'])

  # surnames dictionary
  match.dictionary_name = 'surnames'
  f = feedback.get_feedback(1, [match])
  check_feedback(f, 'Names and surnames by themselves are easy to guess', ['Add another word or two. Uncommon words are better.'])

  # male_names dictionary
  match.dictionary_name = 'male_names'
  f = feedback.get_feedback(1, [match])
  check_feedback(f, 'Names and surnames by themselves are easy to guess', ['Add another word or two. Uncommon words are better.'])

  # female_names dictionary
  match.dictionary_name = 'female_names'
  f = feedback.get_feedback(1, [match])
  check_feedback(f, 'Names and surnames by themselves are easy to guess', ['Add another word or two. Uncommon words are better.'])

  # surname, male_name or female_name match with another match
  f = feedback.get_feedback(1, [match, match])
  check_feedback(f, 'Common names and surnames are easy to guess', ['Add another word or two. Uncommon words are better.'])


  # -- spatial match -- #
  match.pattern = 'spatial'

  # password following a straight keyboard pattern
  f = feedback.get_feedback(1, [Object.assign {}, match, {turns: 1}])
  check_feedback(f, 'Straight rows of keys are easy to guess', ['Add another word or two. Uncommon words are better.', 'Use a longer keyboard pattern with more turns'])

  # password following a more complex keyboard pattern
  f = feedback.get_feedback(1, [Object.assign {}, match, {turns: 2}])
  check_feedback(f, 'Short keyboard patterns are easy to guess', ['Add another word or two. Uncommon words are better.', 'Use a longer keyboard pattern with more turns'])


  # -- repeat match -- #
  match.pattern = 'repeat'

  # password with a character repeated
  f = feedback.get_feedback(1, [Object.assign {}, match, {base_token: 'a'}])
  check_feedback(f, 'Repeats like "aaa" are easy to guess', ['Add another word or two. Uncommon words are better.', 'Avoid repeated words and characters'])

  # password with multiple characters repeated
  f = feedback.get_feedback(1, [Object.assign {}, match, {base_token: 'aa'}])
  check_feedback(f, 'Repeats like "abcabcabc" are only slightly harder to guess than "abc"', ['Add another word or two. Uncommon words are better.', 'Avoid repeated words and characters'])


  # -- sequence match -- #
  match.pattern = 'sequence'

  f = feedback.get_feedback(1, [match])
  check_feedback(f, 'Sequences like abc or 6543 are easy to guess', ['Add another word or two. Uncommon words are better.', 'Avoid sequences'])


  # -- regex match -- #
  match.pattern = 'regex'

  f = feedback.get_feedback(1, [Object.assign {}, match, {regex_name: 'recent_year'}])
  check_feedback(f, 'Recent years are easy to guess', ['Add another word or two. Uncommon words are better.', 'Avoid recent years', 'Avoid years that are associated with you'])


  # -- date match -- #
  match.pattern = 'date'

  f = feedback.get_feedback(1, [match])
  check_feedback(f, 'Dates are often easy to guess', ['Add another word or two. Uncommon words are better.', 'Avoid dates and years that are associated with you'])

  t.end()

test 'custom feedback messages', (t) ->

  match =
    pattern: 'dictionary'
    token: 'token'
    rank: 10
    dictionary_name: 'passwords'

  custom_messages =
    top10_common_password: 'custom#top10_common_password',
    uncommon_words_are_better: 'custom#uncommon_words_are_better'

  # Uses custom messages
  f = feedback.get_feedback(1, [match], custom_messages)
  t.equal f.warning, custom_messages.top10_common_password
  t.deepEqual f.suggestions, [custom_messages.uncommon_words_are_better]

  # If custom messages are null then defaults to in-app messages
  f = feedback.get_feedback(1, [match], null)
  t.equal f.warning, 'This is a top-10 common password'
  t.deepEqual f.suggestions, ['Add another word or two. Uncommon words are better.']

  # If message is absent in custom messages defaults to in-app messages
  custom_messages =
    uncommon_words_are_better: 'custom#uncommon_words_are_better'
  f = feedback.get_feedback(1, [match], custom_messages)
  t.equal f.warning, 'This is a top-10 common password'
  t.deepEqual f.suggestions, [custom_messages.uncommon_words_are_better]

  # If message is present in custom messages and has a falsy value returns empty string
  custom_messages =
    top10_common_password: null,
    uncommon_words_are_better: 'custom#uncommon_words_are_better'
  f = feedback.get_feedback(1, [match], custom_messages)
  t.equal f.warning, ''
  t.deepEqual f.suggestions, [custom_messages.uncommon_words_are_better]

  custom_messages.top10_common_password = undefined
  f = feedback.get_feedback(1, [match], custom_messages)
  t.equal f.warning, ''

  custom_messages.top10_common_password = false
  f = feedback.get_feedback(1, [match], custom_messages)
  t.equal f.warning, ''

  t.end()
