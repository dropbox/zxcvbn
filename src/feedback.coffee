scoring = require('./scoring')

feedback =
  default_feedback:
    warning: ''
    suggestions: [
      "Use multiple words, but avoid common phrases."
      "You can create strong passwords without using symbols, numbers, or uppercase letters."
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
    extra_feedback = 'Add more words that are less common.'
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
          'Straight rows of keys are easy to guess.'
        else
          'Short keyboard patterns are easy to guess.'
        warning: warning
        suggestions: [
          'Use longer keyboard patterns and change typing direction multiple times.'
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          'Repeated characters are easy to guess.'
        else
          'Repeated character patterns are easy to guess.'
        warning: warning
        suggestions: [
          'Avoid repeated words and characters.'
        ]

      when 'sequence'
        warning: "Common character sequences are easy to guess."
        suggestions: [
          'Avoid common character sequences.'
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: "Recent years are easy to guess."
          suggestions: [
            'Avoid recent years.'
            'Avoid years that are associated with you.'
          ]

      when 'date'
        warning: "Dates are easy to guess."
        suggestions: [
          'Avoid dates and years that are associated with you.'
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'This is a heavily used password.'
        else if match.rank <= 100
          'This is a frequently used password.'
        else
          'This is a commonly used password.'
      else if match.guesses_log10 <= 4
        'This is similar to a commonly used password'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        'Single words are easy to guess.'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'Single names or surnames are easy to guess.'
      else
        'Common names and surnames are easy to guess.'
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push "Capitalize more than the first letter."
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push "Capitalize some, but not all letters."

    if match.reversed and match.token.length >= 4
      suggestions.push "Avoid reversed spellings of common words."
    if match.l33t
      suggestions.push "Avoid predictable letter substitutions like '@' for 'a'."

    result =
      warning: warning
      suggestions: suggestions
    result

module.exports = feedback
