scoring = require('./scoring')
translations = require('./translations-pt-br')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      translations.suggestions.useWords # "Use a few words, avoid common phrases"
      translations.suggestions.noNeed # "No need for symbols, digits, or uppercase letters"
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
    extra_feedback = translations.suggestions.anotherWord # 'Add another word or two. Uncommon words are better.'
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
          translations.warnings.straightRow # 'Straight rows of keys are easy to guess'
        else
          translations.warnings.keyPattern # 'Short keyboard patterns are easy to guess'
        warning: warning
        suggestions: [
          translations.suggestions.longerKeyboardPattern # 'Use a longer keyboard pattern with more turns'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          translations.warnings.simpleRepeat # 'Repeats like "aaa" are easy to guess'
        else
          translations.warnings.extendedRepeat # 'Repeats like "abcabcabc" are only slightly harder to guess than "abc"'
        warning: warning
        suggestions: [
          translations.suggestions.repeated # 'Avoid repeated words and characters'
        ]

      when 'sequence'
        warning: translations.warnings.sequences # "Sequences like abc or 6543 are easy to guess"
        suggestions: [
          translations.suggestions.sequences # 'Avoid sequences'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: translations.warnings.recentYears # "Recent years are easy to guess"
          suggestions: [
            translations.suggestions.recentYears # 'Avoid recent years'
            translations.suggestions.associatedYears # 'Avoid years that are associated with you'
          ]

      when 'date'
        warning: translations.warnings.dates # "Dates are often easy to guess"
        suggestions: [
          translations.suggestions.dates # 'Avoid dates and years that are associated with you'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          translations.warnings.topTen # 'This is a top-10 common password'
        else if match.rank <= 100
          translations.warnings.topHundred # 'This is a top-100 common password'
        else
        translations.warnings.common # 'This is a very common password'
      else if match.guesses_log10 <= 4
        translations.warnings.similarToCommon # 'This is similar to a commonly used password'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        translations.warnings.wordByItself # 'A word by itself is easy to guess'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        translations.warnings.namesByThemselves # 'Names and surnames by themselves are easy to guess'
      else
        translations.warnings.commonNames # 'Common names and surnames are easy to guess'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push translations.suggestions.capitalization # "Capitalization doesn't help very much"
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push translations.suggestions.allUppercase # "All-uppercase is almost as easy to guess as all-lowercase"

    if match.reversed and match.token.length >= 4
      suggestions.push translations.suggestions.reverseWords # "Reversed words aren't much harder to guess"
    if match.l33t
      suggestions.push translations.suggestions.l33t # "Predictable substitutions like '@' instead of 'a' don't help very much"

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
