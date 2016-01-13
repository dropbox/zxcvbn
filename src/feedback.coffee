scoring = require('./scoring')

dictionary =
  s_add_words: 'Add another word or two. Uncommon words are better.'
  s_all_caps_helps_little: "All-uppercase is almost as easy to guess as all-lowercase"
  s_avoid_personal_dates: 'Avoid dates and years that are associated with you'
  s_avoid_personal_years: 'Avoid years that are associated with you'
  s_avoid_recent_years: 'Avoid recent years'
  s_avoid_repeats: 'Avoid repeated words and characters'
  s_avoid_sequences: 'Avoid sequences'
  s_capitalization_helps_little: "Capitalization doesn't help very much"
  s_no_need_for_specials: 'No need for symbols, digits, or uppercase letters'
  s_reversed_words_helps_little: "Reversed words aren't much harder to guess"
  s_substitutions_help_little: "Predictable substitutions like '@' instead of 'a' don't help very much"
  s_use_few_words: 'Use a few words, avoid common phrases'
  s_use_longer_pattern: 'Use a longer keyboard pattern with more turns'
  w_common_names: 'Common names and surnames are easy to guess'
  w_common_password: 'This is a very common password'
  w_dates: warning: "Dates are often easy to guess"
  w_dictionary_word: 'A word by itself is easy to guess'
  w_names: 'Names and surnames by themselves are easy to guess'
  w_recent_years: warning: "Recent years are easy to guess"
  w_repeats: 'Repeats like "abcabcabc" are only slightly harder to guess than "abc"'
  w_repeats_dumb: 'Repeats like "aaa" are easy to guess'
  w_sequences: warning: "Sequences like abc or 6543 are easy to guess"
  w_short_pattern: 'Short keyboard patterns are easy to guess'
  w_similar_to_common_password: 'This is similar to a commonly used password'
  w_straight_row: 'Straight rows of keys are easy to guess'
  w_top100_password: 'This is a top-100 common password'
  w_top10_password: 'This is a top-10 common password'

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      's_use_few_words'
      's_no_need_for_specials'
    ]

  get_feedback: (score, sequence) ->
# starting feedback
    return @default_feedback if sequence.length == 0

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = 's_add_words'
    if feedback?
      feedback.suggestions.unshift extra_feedback
      feedback.warning = '' unless feedback.warning?
    else
      feedback =
        warning: ''
        suggestions: [extra_feedback]
    feedback

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        layout = match.graph.toUpperCase()
        warning = if match.turns == 1
          'w_straight_row'
        else
          'w_short_pattern'
        warning: warning
        suggestions: [
          's_use_longer_pattern'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'w_repeats_dumb'
        else
          'w_repeats'
        warning: warning
        suggestions: [
          's_avoid_repeats'
        ]

      when 'sequence'
        warning: 'w_sequences'
        suggestions: [
          's_avoid_sequences'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: 'w_recent_years'
          suggestions: [
            's_avoid_recent_years'
            's_avoid_personal_years'
          ]

      when 'date'
        warning: 'w_dates'
        suggestions: [
          's_avoid_personal_dates'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'w_top10_password'
        else if match.rank <= 100
          'w_top100_password'
        else
          'w_common_password'
      else if match.guesses_log10 <= 4
        'w_similar_to_common_password'
    else if match.dictionary_name == 'english'
      if is_sole_match
        'w_dictionary_word'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'w_names'
      else
        'w_common_names'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push 's_capitalization_helps_little'
    else if word.match(scoring.ALL_UPPER)
      suggestions.push 's_all_caps_helps_little'

    if match.reversed and match.token.length >= 4
      suggestions.push 's_reversed_words_helps_little'
    if match.l33t
      suggestions.push 's_substitutions_help_little'

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback