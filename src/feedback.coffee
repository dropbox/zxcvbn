scoring = require('./scoring')

feedback =
  messages: [
    "Use a few words, avoid common phrases"
    "No need for symbols, digits, or uppercase letters"
    "Add another word or two. Uncommon words are better."
    "Straight rows of keys are easy to guess"
    "Short keyboard patterns are easy to guess"
    "Use a longer keyboard pattern with more turns"
    "Repeats like \"aaa\" are easy to guess"
    "Repeats like \"abcabcabc\" are only slightly harder to guess than \"abc\""
    "Avoid repeated words and characters"
    "Sequences like abc or 6543 are easy to guess"
    "Avoid sequences"
    "Recent years are easy to guess"
    "Avoid recent years"
    "Avoid years that are associated with you"
    "Dates are often easy to guess"
    "Avoid dates and years that are associated with you"
    "This is a top-10 common password"
    "This is a top-100 common password"
    "This is a very common password"
    "This is similar to a commonly used password"
    "A word by itself is easy to guess"
    "Names and surnames by themselves are easy to guess"
    "Common names and surnames are easy to guess"
    "Capitalization doesn't help very much"
    "All-uppercase is almost as easy to guess as all-lowercase"
    "Reversed words aren't much harder to guess"
    "Predictable substitutions like '@' instead of 'a' don't help very much"
  ]

  get_feedback: (score, sequence, custom_messages) ->
    @custom_messages = custom_messages

    # starting feedback
    return if sequence.length == 0
      warning: ''
      suggestions: [
        @get_message(0) # Use a few words, avoid common phrases
        @get_message(1) # No need for symbols, digits, or uppercase letters
      ]

    # no feedback if score is good or great.
    return if score > 2
      warning: ''
      suggestions: []

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = @get_message(2) # Add another word or two. Uncommon words are better.
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
          @get_message(3) # Straight rows of keys are easy to guess
        else
          @get_message(4) # Short keyboard patterns are easy to guess
        warning: warning
        suggestions: [
          @get_message(5) # Use a longer keyboard pattern with more turns
        ]

      when 'repeat'
        warning = if match.base_token.length == 1
          @get_message(6) # Repeats like \"aaa\" are easy to guess
        else
          @get_message(7) # Repeats like \"abcabcabc\" are only slightly harder to guess than \"abc\"
        warning: warning
        suggestions: [
          @get_message(8) # Avoid repeated words and characters
        ]

      when 'sequence'
        @get_message(9) # Sequences like abc or 6543 are easy to guess
        suggestions: [
          @get_message(10) # Avoid sequences
        ]

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: @get_message(11) # Recent years are easy to guess
          suggestions: [
            @get_message(12) # Avoid recent years
            @get_message(13) # Avoid years that are associated with you
          ]

      when 'date'
        warning: @get_message(14) # Dates are often easy to guess
        suggestions: [
          @get_message(15) # Avoid dates and years that are associated with you
        ]

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          @get_message(16) # This is a top-10 common password
        else if match.rank <= 100
          @get_message(17) # This is a top-100 common password
        else
          @get_message(18) # This is a very common password
      else if match.guesses_log10 <= 4
        @get_message(19) # This is similar to a commonly used password
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        @get_message(20) # A word by itself is easy to guess
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        @get_message(21) # Names and surnames by themselves are easy to guess
      else
        @get_message(22) # Common names and surnames are easy to guess
    else
      ''

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push @get_message(23) # Capitalization doesn't help very much
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push @get_message(24) # All-uppercase is almost as easy to guess as all-lowercase

    if match.reversed and match.token.length >= 4
      suggestions.push @get_message(25) # Reversed words aren't much harder to guess
    if match.l33t
      suggestions.push @get_message(26) # Predictable substitutions like '@' instead of 'a' don't help very much

    result =
      warning: warning
      suggestions: suggestions
    result

  get_message: (index) ->
    if @custom_messages? and @custom_messages[index]?
      @custom_messages[index]
    else
      @messages[index]

module.exports = feedback
