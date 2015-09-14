adjacency_graphs = require('./adjacency_graphs')

# on qwerty, 'g' has degree 6, being adjacent to 'ftyhbv'. '\' has degree 1.
# this calculates the average over all keys.
calc_average_degree = (graph) ->
  average = 0
  for key, neighbors of graph
    average += (n for n in neighbors when n).length
  average /= (k for k,v of graph).length
  average

scoring =
  nCk: (n, k) ->
    # http://blog.plover.com/math/choose.html
    return 0 if k > n
    return 1 if k == 0
    r = 1
    for d in [1..k]
      r *= n
      r /= d
      n -= 1
    r

  lg: (n) -> Math.log(n) / Math.log(2)

  # ------------------------------------------------------------------------------
  # minimum entropy search -------------------------------------------------------
  # ------------------------------------------------------------------------------
  #
  # takes a list of overlapping matches, returns the non-overlapping sublist with
  # minimum entropy. O(nm) dp alg for length-n password with m candidate matches.
  # ------------------------------------------------------------------------------

  minimum_entropy_match_sequence: (password, matches) ->
    bruteforce_cardinality = @calc_bruteforce_cardinality password # e.g. 26 for lowercase
    up_to_k = []      # minimum entropy up to k.
    # for the optimal seq of matches up to k, backpointers holds the final match (match.j == k).
    # null means the sequence ends w/ a brute-force character.
    backpointers = []
    for k in [0...password.length]
      # starting scenario to try and beat:
      # adding a brute-force character to the minimum entropy sequence at k-1.
      up_to_k[k] = (up_to_k[k-1] or 0) + @lg bruteforce_cardinality
      backpointers[k] = null
      for match in matches when match.j == k
        [i, j] = [match.i, match.j]
        # see if best entropy up to i-1 + entropy of this match is less than current minimum at j.
        candidate_entropy = (up_to_k[i-1] or 0) + @calc_entropy(match)
        if candidate_entropy < up_to_k[j]
          up_to_k[j] = candidate_entropy
          backpointers[j] = match

    # walk backwards and decode the best sequence
    match_sequence = []
    k = password.length - 1
    while k >= 0
      match = backpointers[k]
      if match
        match_sequence.push match
        k = match.i - 1
      else
        k -= 1
    match_sequence.reverse()

    # fill in the blanks between pattern matches with bruteforce "matches"
    # that way the match sequence fully covers the password:
    # match1.j == match2.i - 1 for every adjacent match1, match2.
    make_bruteforce_match = (i, j) =>
      pattern: 'bruteforce'
      i: i
      j: j
      token: password[i..j]
      entropy: @lg Math.pow(bruteforce_cardinality, j - i + 1)
      cardinality: bruteforce_cardinality
    k = 0
    match_sequence_copy = []
    for match in match_sequence
      [i, j] = [match.i, match.j]
      if i - k > 0
        match_sequence_copy.push make_bruteforce_match(k, i - 1)
      k = j + 1
      match_sequence_copy.push match
    if k < password.length
      match_sequence_copy.push make_bruteforce_match(k, password.length - 1)
    match_sequence = match_sequence_copy

    min_entropy = up_to_k[password.length - 1] or 0  # or 0 corner case is for an empty password ''
    crack_time = @entropy_to_crack_time min_entropy

    # final result object
    password: password
    entropy: @round_to_x_digits(min_entropy, 3)
    match_sequence: match_sequence
    crack_time: @round_to_x_digits(crack_time, 3)
    crack_time_display: @display_time crack_time
    score: @crack_time_to_score crack_time

  round_to_x_digits: (n, x) -> Math.round(n * Math.pow(10, x)) / Math.pow(10, x)

  # ------------------------------------------------------------------------------
  # threat model -- stolen hash catastrophe scenario -----------------------------
  # ------------------------------------------------------------------------------
  #
  # assumes:
  # * passwords are stored as salted hashes, different random salt per user.
  #   (making rainbow attacks infeasable.)
  # * hashes and salts were stolen. attacker is guessing passwords at max rate.
  # * attacker has several CPUs at their disposal.
  # ------------------------------------------------------------------------------

  SECONDS_PER_GUESS: .010 / 100 # single guess time (10ms) over number of cores guessing in parallel
  # for a hash function like bcrypt/scrypt/PBKDF2, 10ms per guess is a safe lower bound.
  # (usually a guess would take longer -- this assumes fast hardware and a small work factor.)
  # adjust for your site accordingly if you use another hash function, possibly by
  # several orders of magnitude!

  entropy_to_crack_time: (entropy) ->
    .5 * Math.pow(2, entropy) * @SECONDS_PER_GUESS # .5 for average vs total

  crack_time_to_score: (seconds) ->
    return 0 if seconds < Math.pow(10, 2)
    return 1 if seconds < Math.pow(10, 4)
    return 2 if seconds < Math.pow(10, 6)
    return 3 if seconds < Math.pow(10, 8)
    return 4

  # ------------------------------------------------------------------------------
  # entropy calcs -- one function per match pattern ------------------------------
  # ------------------------------------------------------------------------------

  calc_entropy: (match) ->
    return match.entropy if match.entropy? # a match's entropy doesn't change. cache it.
    entropy_functions =
      dictionary: @dictionary_entropy
      spatial:    @spatial_entropy
      repeat:     @repeat_entropy
      sequence:   @sequence_entropy
      regex:      @regex_entropy
      date:       @date_entropy
    match.entropy = entropy_functions[match.pattern].call this, match

  repeat_entropy: (match) ->
    num_repeats = match.token.length / match.base_token.length
    match.base_entropy + @lg num_repeats

  sequence_entropy: (match) ->
    first_chr = match.token.charAt(0)
    # lower entropy for obvious starting points
    if first_chr in ['a', 'A', 'z', 'Z', '0', '1', '9']
      base_entropy = 2
    else
      if first_chr.match /\d/
        base_entropy = @lg(10) # digits
      else if first_chr.match /[a-z]/
        base_entropy = @lg(26) # lower
      else
        base_entropy = @lg(26) + 1 # extra bit for uppercase
    if not match.ascending
      base_entropy += 1 # extra bit for descending instead of ascending
    base_entropy + @lg match.token.length

  MIN_YEAR_SPACE: 20
  REFERENCE_YEAR: 2000
  regex_entropy: (match) ->
    char_class_bases =
      alpha_lower:  26
      alpha_upper:  26
      alpha:        52
      alphanumeric: 62
      digits:       10
      symbols:      33
    if match.regex_name of char_class_bases
      @lg Math.pow(char_class_bases[match.regex_name], match.token.length)
    else switch match.regex_name
      when 'recent_year'
        # conservative estimate of year space: num years from REFERENCE_YEAR.
        # if year is close to REFERENCE_YEAR, estimate a year space of MIN_YEAR_SPACE.
        year_space = Math.abs parseInt(match.regex_match[0]) - @REFERENCE_YEAR
        year_space = Math.max year_space, @MIN_YEAR_SPACE
        @lg year_space

  date_entropy: (match) ->
    # base entropy: lg of (year distance from REFERENCE_YEAR * num_days * num_years)
    year_space = Math.max(Math.abs(match.year - @REFERENCE_YEAR), @MIN_YEAR_SPACE)
    entropy = @lg(year_space * 31 * 12)
    # add one bit for four-digit years
    entropy += 1 if match.has_full_year
    # add two bits for separator selection (one of ~4 choices)
    entropy += 2 if match.separator
    entropy

  KEYBOARD_AVERAGE_DEGREE: calc_average_degree(adjacency_graphs.qwerty)
  # slightly different for keypad/mac keypad, but close enough
  KEYPAD_AVERAGE_DEGREE: calc_average_degree(adjacency_graphs.keypad)

  KEYBOARD_STARTING_POSITIONS: (k for k,v of adjacency_graphs.qwerty).length
  KEYPAD_STARTING_POSITIONS: (k for k,v of adjacency_graphs.keypad).length

  spatial_entropy: (match) ->
    if match.graph in ['qwerty', 'dvorak']
      s = @KEYBOARD_STARTING_POSITIONS
      d = @KEYBOARD_AVERAGE_DEGREE
    else
      s = @KEYPAD_STARTING_POSITIONS
      d = @KEYPAD_AVERAGE_DEGREE
    possibilities = 0
    L = match.token.length
    t = match.turns
    # estimate the number of possible patterns w/ length L or less with t turns or less.
    for i in [2..L]
      possible_turns = Math.min(t, i - 1)
      for j in [1..possible_turns]
        possibilities += @nCk(i - 1, j - 1) * s * Math.pow(d, j)
    entropy = @lg possibilities
    # add extra entropy for shifted keys. (% instead of 5, A instead of a.)
    # math is similar to extra entropy of l33t substitutions in dictionary matches.
    if match.shifted_count
      S = match.shifted_count
      U = match.token.length - match.shifted_count # unshifted count
      if U == 0
        entropy += 1
      else
        possibilities = 0
        possibilities += @nCk(S + U, i) for i in [1..Math.min(S, U)]
        entropy += @lg possibilities
    entropy

  dictionary_entropy: (match) ->
    match.base_entropy = @lg match.rank # keep these as properties for display purposes
    match.uppercase_entropy = @extra_uppercase_entropy match
    match.reversed_entropy = match.reversed and 1 or 0
    match.l33t_entropy = @extra_l33t_entropy(match)
    match.base_entropy + match.uppercase_entropy + match.l33t_entropy + match.reversed_entropy

  START_UPPER: /^[A-Z][^A-Z]+$/
  END_UPPER: /^[^A-Z]+[A-Z]$/
  ALL_UPPER: /^[^a-z]+$/
  ALL_LOWER: /^[^A-Z]+$/

  extra_uppercase_entropy: (match) ->
    word = match.token
    return 0 if word.match @ALL_LOWER
    # a capitalized word is the most common capitalization scheme,
    # so it only doubles the search space (uncapitalized + capitalized): 1 extra bit of entropy.
    # allcaps and end-capitalized are common enough too, underestimate as 1 extra bit to be safe.
    for regex in [@START_UPPER, @END_UPPER, @ALL_UPPER]
      return 1 if word.match regex
    # otherwise calculate the number of ways to capitalize U+L uppercase+lowercase letters
    # with U uppercase letters or less. or, if there's more uppercase than lower (for eg. PASSwORD),
    # the number of ways to lowercase U+L letters with L lowercase letters or less.
    U = (chr for chr in word.split('') when chr.match /[A-Z]/).length
    L = (chr for chr in word.split('') when chr.match /[a-z]/).length
    possibilities = 0
    possibilities += @nCk(U + L, i) for i in [1..Math.min(U, L)]
    @lg possibilities

  extra_l33t_entropy: (match) ->
    return 0 if not match.l33t
    extra_entropy = 0
    for subbed, unsubbed of match.sub
      # lower-case match.token before calculating: capitalization shouldn't affect l33t calc.
      chrs = match.token.toLowerCase().split('')
      S = (chr for chr in chrs when chr == subbed).length   # num of subbed chars
      U = (chr for chr in chrs when chr == unsubbed).length # num of unsubbed chars
      if S == 0 or U == 0
        # for this sub, password is either fully subbed (444) or fully unsubbed (aaa)
        # treat that as doubling the space (attacker needs to try fully subbed chars in addition to
        # unsubbed.)
        extra_entropy += 1
      else
        # this case is similar to capitalization:
        # with aa44a, U = 3, S = 2, attacker needs to try unsubbed + one sub + two subs
        p = Math.min(U, S)
        possibilities = 0
        possibilities += @nCk(U + S, i) for i in [1..p]
        extra_entropy += @lg possibilities
    extra_entropy

  # utilities --------------------------------------------------------------------

  calc_bruteforce_cardinality: (password) ->
    [lower, upper, digits, symbols, latin1_symbols, latin1_letters] = (
      false for i in [0...6]
    )
    unicode_codepoints = []
    for chr in password.split('')
      ord = chr.charCodeAt(0)
      if 0x30 <= ord <= 0x39
        digits = true
      else if 0x41 <= ord <= 0x5a
        upper = true
      else if 0x61 <= ord <= 0x7a
        lower = true
      else if ord <= 0x7f
        symbols = true
      else if 0x80 <= ord <= 0xBF
        latin1_symbols = true
      else if 0xC0 <= ord <= 0xFF
        latin1_letters = true
      else if ord > 0xFF
        unicode_codepoints.push ord
    c = 0
    c += 10 if digits
    c += 26 if upper
    c += 26 if lower
    c += 33 if symbols
    c += 64 if latin1_symbols
    c += 64 if latin1_letters
    if unicode_codepoints.length
      min_cp = max_cp = unicode_codepoints[0]
      for cp in unicode_codepoints[1..]
        min_cp = cp if cp < min_cp
        max_cp = cp if cp > max_cp
      # if the range between unicode codepoints is small,
      # assume one extra alphabet is in use (eg cyrillic, korean) and add a ballpark +40
      #
      # if the range is large, be very conservative and add +100 instead of the range.
      # (codepoint distance between chinese chars can be many thousand, for example,
      # but that cardinality boost won't be justified if the characters are common.)
      range = max_cp - min_cp + 1
      range = 40 if range < 40
      range = 100 if range > 100
      c += range
    c

  display_time: (seconds) ->
    minute = 60
    hour = minute * 60
    day = hour * 24
    month = day * 31
    year = month * 12
    century = year * 100
    [display_num, display_str] = if seconds < minute
      [seconds, "#{seconds} second"]
    else if seconds < hour
      base = Math.round seconds / minute
      [base, "#{base} minute"]
    else if seconds < day
      base = Math.round seconds / hour
      [base, "#{base} hour"]
    else if seconds < month
      base = Math.round seconds / day
      [base, "#{base} day"]
    else if seconds < year
      base = Math.round seconds / month
      [base, "#{base} month"]
    else if seconds < century
      base = Math.round seconds / year
      [base, "#{base} year"]
    else
      [null, 'centuries']
    display_str += 's' if display_num? and display_num != 1
    display_str


module.exports = scoring
