scoring = require('./scoring')

feedback =
  messages:
    use_a_few_words: 'Use a few words, avoid common phrases'
    no_need_for_mixed_chars: 'No need for symbols, digits, or uppercase letters'
    uncommon_words_are_better: 'Add another word or two. Uncommon words are better.'
    straight_rows_of_keys_are_easy: 'Straight rows of keys are easy to guess'
    short_keyboard_patterns_are_easy: 'Short keyboard patterns are easy to guess'
    use_longer_keyboard_patterns: 'Use a longer keyboard pattern with more turns'
    repeated_chars_are_easy: 'Repeats like "aaa" are easy to guess'
    repeated_patterns_are_easy: 'Repeats like "abcabcabc" are only slightly harder to guess than "abc"'
    avoid_repeated_chars: 'Avoid repeated words and characters'
    sequences_are_easy: 'Sequences like abc or 6543 are easy to guess'
    avoid_sequences: 'Avoid sequences'
    recent_years_are_easy: 'Recent years are easy to guess'
    avoid_recent_years: 'Avoid recent years'
    avoid_associated_years: 'Avoid years that are associated with you'
    dates_are_easy: 'Dates are often easy to guess'
    avoid_associated_dates_and_years: 'Avoid dates and years that are associated with you'
    top10_common_password: 'This is a top-10 common password'
    top100_common_password: 'This is a top-100 common password'
    very_common_password: 'This is a very common password'
    similar_to_common_password: 'This is similar to a commonly used password'
    a_word_is_easy: 'A word by itself is easy to guess'
    names_are_easy: 'Names and surnames by themselves are easy to guess'
    common_names_are_easy: 'Common names and surnames are easy to guess'
    capitalization_doesnt_help: 'Capitalization doesn\'t help very much'
    all_uppercase_doesnt_help: 'All-uppercase is almost as easy to guess as all-lowercase'
    reverse_doesnt_help: 'Reversed words aren\'t much harder to guess'
    substitution_doesnt_help: 'Predictable substitutions like \'@\' instead of \'a\' don\'t help very much'

  get_feedback: (score, sequence, custom_messages) ->
    @custom_messages = custom_messages

    # starting feedback
    return if sequence.length == 0
      @build_feedback(null, ['use_a_few_words', 'no_need_for_mixed_chars'])

    # no feedback if score is good or great.
    return if score > 2
      @build_feedback()

    # tie feedback to the longest match for longer sequences
    longest_match = sequence[0]
    for match in sequence[1..]
      longest_match = match if match.token.length > longest_match.token.length
    feedback = @get_match_feedback(longest_match, sequence.length == 1)
    extra_feedback = ['uncommon_words_are_better']
    if feedback?
      @build_feedback(feedback.warning, extra_feedback.concat feedback.suggestions)
    else
      @build_feedback(null, extra_feedback)

  get_match_feedback: (match, is_sole_match) ->
    switch match.pattern
      when 'dictionary'
        @get_dictionary_match_feedback match, is_sole_match

      when 'spatial'
        warning = if match.turns == 1
          'straight_rows_of_keys_are_easy'
        else
          'short_keyboard_patterns_are_easy'
        warning: warning
        suggestions: ['use_longer_keyboard_patterns']

      when 'repeat'
        warning = if match.base_token.length == 1
          'repeated_chars_are_easy'
        else
          'repeated_patterns_are_easy'
        warning: warning
        suggestions: ['avoid_repeated_chars']

      when 'sequence'
        warning: 'sequences_are_easy'
        suggestions: ['avoid_sequences']

      when 'regex'
        if match.regex_name == 'recent_year'
          warning: 'recent_years_are_easy'
          suggestions: ['avoid_recent_years', 'avoid_associated_years']

      when 'date'
        warning: 'dates_are_easy'
        suggestions: ['avoid_associated_dates_and_years']

  get_dictionary_match_feedback: (match, is_sole_match) ->
    warning = if match.dictionary_name == 'passwords'
      if is_sole_match and not match.l33t and not match.reversed
        if match.rank <= 10
          'top10_common_password'
        else if match.rank <= 100
          'top100_common_password'
        else
          'very_common_password'
      else if match.guesses_log10 <= 4
        'similar_to_common_password'
    else if match.dictionary_name == 'english_wikipedia'
      if is_sole_match
        'a_word_is_easy'
    else if match.dictionary_name in ['surnames', 'male_names', 'female_names']
      if is_sole_match
        'names_are_easy'
      else
        'common_names_are_easy'

    suggestions = []
    word = match.token
    if word.match(scoring.START_UPPER)
      suggestions.push 'capitalization_doesnt_help'
    else if word.match(scoring.ALL_UPPER) and word.toLowerCase() != word
      suggestions.push 'all_uppercase_doesnt_help'

    if match.reversed and match.token.length >= 4
      suggestions.push 'reverse_doesnt_help'
    if match.l33t
      suggestions.push 'substitution_doesnt_help'

    result =
      warning: warning
      suggestions: suggestions
    result

  get_message: (key) ->
    if @custom_messages?
      @custom_messages[key] || ''
    else if @messages[key]?
      @messages[key]
    else
      throw new Error("unknown message: #{key}")

  build_feedback: (warning_key = null, suggestion_keys = []) ->
    suggestions = []
    for suggestion_key in suggestion_keys
      message = @get_message(suggestion_key)
      suggestions.push message if message?
    feedback =
      warning: if warning_key then @get_message(warning_key) else ''
      suggestions: suggestions
    feedback

module.exports = feedback
