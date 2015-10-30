adjacency_graphs = require('./adjacency_graphs')

# on qwerty, 'g' has degree 6, being adjacent to 'ftyhbv'. '\' has degree 1.
# this calculates the average over all keys.
calc_average_degree = (graph) ->
  average = 0
  for key, neighbors of graph
    average += (n for n in neighbors when n).length
  average /= (k for k,v of graph).length
  average

BRUTEFORCE_CARDINALITY = 10
MIN_GUESSES_BEFORE_GROWING_SEQUENCE = 10000
MIN_SUBMATCH_GUESSES_SINGLE_CHAR = 10
MIN_SUBMATCH_GUESSES_MULTI_CHAR = 50

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

  log10: (n) -> Math.log(n) / Math.log(10) # IE doesn't support Math.log10 :(
  log2:  (n) -> Math.log(n) / Math.log(2)

  factorial: (n) ->
    # unoptimized, called only on small n
    return 1 if n < 2
    f = 1
    f *= i for i in [2..n]
    f

  # ------------------------------------------------------------------------------
  # search --- most guessable match sequence -------------------------------------
  # ------------------------------------------------------------------------------
  #
  # takes a sequence of overlapping matches, returns the non-overlapping sequence with
  # minimum guesses. O(nml) dp alg for length-n password with m candidate matches
  # and optimal length-l sequence.
  #
  # the optimal "minimum guesses" sublist is here defined to be the sublist that
  # minimizes:
  #
  #    l! * Product(m.guesses for m in sequence) + D^(l - 1)
  #
  # where l is the length of the sequence.
  #
  # the factorial term is the number of ways to order l patterns.
  #
  # the D^(l-1) term is another length penalty, roughly capturing the idea that an
  # attacker will try lower-length sequences first before trying length-l sequences.
  #
  # for example, consider a sequence that is date-repeat-dictionary.
  #  - an attacker would need to try other date-repeat-dictionary combinations,
  #    hence the product term.
  #  - an attacker would need to try repeat-date-dictionary, dictionary-repeat-date,
  #    ..., hence the factorial term.
  #  - an attacker would also likely try length-1 (dictionary) and length-2 (dictionary-date)
  #    sequences before length-3. assuming at minimum D guesses per pattern type,
  #    D^(l-1) approximates Sum(D^i for i in [1..l-1]
  #
  # ------------------------------------------------------------------------------

  most_guessable_match_sequence: (password, matches, _exclude_additive=false) ->

    # at [k][l], the product of guesses of the optimal sequence of length-l
    # covering password[0..k].
    optimal_product = []

    # at [k][l], the final match (match.j == k) in said optimal sequence of length l.
    backpointers = []

    max_l = 0        # max-length sequence ever recorded
    optimal_l = null # length of current optimal sequence

    make_bruteforce_match = (i, j) =>
      match =
        pattern: 'bruteforce'
        token: password[i..j]
        i: i
        j: j
      match

    score = (guess_product, sequence_length) =>
      result = @factorial(sequence_length) * guess_product
      unless _exclude_additive
        result += Math.pow MIN_GUESSES_BEFORE_GROWING_SEQUENCE, sequence_length - 1
      result

    for k in [0...password.length]
      backpointers[k] = []
      optimal_product[k] = []
      optimal_score = Infinity
      for prev_l in [0..max_l]
        # for each new k, starting scenario to try to beat: bruteforce matches
        # involving the lowest-possible l. three cases:
        #
        # 1. all-bruteforce match (for length-1 sequences.)
        # 2. extending a previous bruteforce match
        #    (possible when optimal[k-1][l] ends in bf.)
        # 3. starting a new single-char bruteforce match
        #    (possible when optimal[k-1][l] exists but does not end in bf.)
        #
        # otherwise: there is no bruteforce starting scenario that might be better
        # than already-discovered lower-l sequences.
        consider_bruteforce = true
        bf_j = k
        if prev_l == 0
          bf_i = 0
          new_l = 1
        else if backpointers[k-1]?[prev_l]?.pattern == 'bruteforce'
          bf_i = backpointers[k-1][prev_l].i
          new_l = prev_l
        else if backpointers[k-1]?[prev_l]?
          bf_i = k
          new_l = prev_l + 1
        else
          consider_bruteforce = false

        if consider_bruteforce
          bf_match = make_bruteforce_match bf_i, bf_j
          prev_j = k - bf_match.token.length # end of preceeding match
          candidate_product = @estimate_guesses bf_match, password
          candidate_product *= optimal_product[prev_j][new_l - 1] if new_l > 1
          candidate_score = score candidate_product, new_l
          if candidate_score < optimal_score
            optimal_score = candidate_score
            optimal_product[k][new_l] = candidate_product
            optimal_l = new_l
            max_l = Math.max max_l, new_l
            backpointers[k][new_l] = bf_match

        # now try beating those bruteforce starting scenarios.
        # for each match m ending at k, see if forming a (prev_l + 1) sequence
        # ending at m is better than the current optimum.
        for match in matches when match.j == k
          [i, j] = [match.i, match.j]
          if prev_l == 0
            # if forming a len-1 sequence [match], match.i must fully cover [0..k]
            continue unless i == 0
          else
            # it's only possible to form a new potentially-optimal sequence ending at
            # match when there's an optimal length-prev_l sequence ending at match.i-1.
            continue unless optimal_product[i-1]?[prev_l]?
          candidate_product = @estimate_guesses match, password
          candidate_product *= optimal_product[i-1][prev_l] if prev_l > 0
          candidate_score = score candidate_product, prev_l + 1
          if candidate_score < optimal_score
            optimal_score = candidate_score
            optimal_product[k][prev_l+1] = candidate_product
            optimal_l = prev_l + 1
            max_l = Math.max max_l, prev_l+1
            backpointers[k][prev_l+1] = match

    # walk backwards and decode the optimal sequence
    match_sequence = []
    l = optimal_l
    k = password.length - 1
    while k >= 0
      match = backpointers[k][l]
      match_sequence.push match
      k = match.i - 1
      l -= 1
    match_sequence.reverse()

    # corner: empty password
    if password.length == 0
      guesses = 1
    else
      guesses = optimal_score

    # final result object
    password: password
    guesses: guesses
    guesses_log10: @log10 guesses
    sequence: match_sequence

  # ------------------------------------------------------------------------------
  # guess estimation -- one function per match pattern ---------------------------
  # ------------------------------------------------------------------------------

  estimate_guesses: (match, password) ->
    return match.guesses if match.guesses? # a match's guess estimate doesn't change. cache it.
    min_guesses = 1
    if match.token.length < password.length
      min_guesses = if match.token.length == 1
        MIN_SUBMATCH_GUESSES_SINGLE_CHAR
      else
        MIN_SUBMATCH_GUESSES_MULTI_CHAR
    estimation_functions =
      bruteforce: @bruteforce_guesses
      dictionary: @dictionary_guesses
      spatial:    @spatial_guesses
      repeat:     @repeat_guesses
      sequence:   @sequence_guesses
      regex:      @regex_guesses
      date:       @date_guesses
    guesses = estimation_functions[match.pattern].call this, match
    match.guesses = Math.max guesses, min_guesses
    match.guesses_log10 = @log10 match.guesses
    match.guesses

  bruteforce_guesses: (match) ->
    guesses = Math.pow BRUTEFORCE_CARDINALITY, match.token.length
    # small detail: make bruteforce matches at minimum one guess bigger than smallest allowed
    # submatch guesses, such that non-bruteforce submatches over the same [i..j] take precidence.
    min_guesses = if match.token.length == 1
      MIN_SUBMATCH_GUESSES_SINGLE_CHAR + 1
    else
      MIN_SUBMATCH_GUESSES_MULTI_CHAR + 1
    Math.max guesses, min_guesses

  repeat_guesses: (match) ->
    match.base_guesses * match.repeat_count

  sequence_guesses: (match) ->
    first_chr = match.token.charAt(0)
    # lower guesses for obvious starting points
    if first_chr in ['a', 'A', 'z', 'Z', '0', '1', '9']
      base_guesses = 4
    else
      if first_chr.match /\d/
        base_guesses = 10 # digits
      else
        # could give a higher base for uppercase,
        # assigning 26 to both upper and lower sequences is more conservative.
        base_guesses = 26
    if not match.ascending
      # need to try a descending sequence in addition to every ascending sequence ->
      # 2x guesses
      base_guesses *= 2
    base_guesses * match.token.length

  MIN_YEAR_SPACE: 20
  REFERENCE_YEAR: 2000
  regex_guesses: (match) ->
    char_class_bases =
      alpha_lower:  26
      alpha_upper:  26
      alpha:        52
      alphanumeric: 62
      digits:       10
      symbols:      33
    if match.regex_name of char_class_bases
      Math.pow(char_class_bases[match.regex_name], match.token.length)
    else switch match.regex_name
      when 'recent_year'
        # conservative estimate of year space: num years from REFERENCE_YEAR.
        # if year is close to REFERENCE_YEAR, estimate a year space of MIN_YEAR_SPACE.
        year_space = Math.abs parseInt(match.regex_match[0]) - @REFERENCE_YEAR
        year_space = Math.max year_space, @MIN_YEAR_SPACE
        year_space

  date_guesses: (match) ->
    # base guesses: (year distance from REFERENCE_YEAR) * num_days * num_years
    year_space = Math.max(Math.abs(match.year - @REFERENCE_YEAR), @MIN_YEAR_SPACE)
    guesses = year_space * 31 * 12
    # double for four-digit years
    guesses *= 2 if match.has_full_year
    # add factor of 4 for separator selection (one of ~4 choices)
    guesses *= 4 if match.separator
    guesses

  KEYBOARD_AVERAGE_DEGREE: calc_average_degree(adjacency_graphs.qwerty)
  # slightly different for keypad/mac keypad, but close enough
  KEYPAD_AVERAGE_DEGREE: calc_average_degree(adjacency_graphs.keypad)

  KEYBOARD_STARTING_POSITIONS: (k for k,v of adjacency_graphs.qwerty).length
  KEYPAD_STARTING_POSITIONS: (k for k,v of adjacency_graphs.keypad).length

  spatial_guesses: (match) ->
    if match.graph in ['qwerty', 'dvorak']
      s = @KEYBOARD_STARTING_POSITIONS
      d = @KEYBOARD_AVERAGE_DEGREE
    else
      s = @KEYPAD_STARTING_POSITIONS
      d = @KEYPAD_AVERAGE_DEGREE
    guesses = 0
    L = match.token.length
    t = match.turns
    # estimate the number of possible patterns w/ length L or less with t turns or less.
    for i in [2..L]
      possible_turns = Math.min(t, i - 1)
      for j in [1..possible_turns]
        guesses += @nCk(i - 1, j - 1) * s * Math.pow(d, j)
    # add extra guesses for shifted keys. (% instead of 5, A instead of a.)
    # math is similar to extra guesses of l33t substitutions in dictionary matches.
    if match.shifted_count
      S = match.shifted_count
      U = match.token.length - match.shifted_count # unshifted count
      if S == 0 or U == 0
        guesses *= 2
      else
        shifted_variations = 0
        shifted_variations += @nCk(S + U, i) for i in [1..Math.min(S, U)]
        guesses *= shifted_variations
    guesses

  dictionary_guesses: (match) ->
    match.base_guesses = match.rank # keep these as properties for display purposes
    match.uppercase_variations = @uppercase_variations match
    match.l33t_variations = @l33t_variations match
    reversed_variations = match.reversed and 2 or 1
    match.base_guesses * match.uppercase_variations * match.l33t_variations * reversed_variations

  START_UPPER: /^[A-Z][^A-Z]+$/
  END_UPPER: /^[^A-Z]+[A-Z]$/
  ALL_UPPER: /^[^a-z]+$/
  ALL_LOWER: /^[^A-Z]+$/

  uppercase_variations: (match) ->
    word = match.token
    return 1 if word.match @ALL_LOWER
    # a capitalized word is the most common capitalization scheme,
    # so it only doubles the search space (uncapitalized + capitalized).
    # allcaps and end-capitalized are common enough too, underestimate as 2x factor to be safe.
    for regex in [@START_UPPER, @END_UPPER, @ALL_UPPER]
      return 2 if word.match regex
    # otherwise calculate the number of ways to capitalize U+L uppercase+lowercase letters
    # with U uppercase letters or less. or, if there's more uppercase than lower (for eg. PASSwORD),
    # the number of ways to lowercase U+L letters with L lowercase letters or less.
    U = (chr for chr in word.split('') when chr.match /[A-Z]/).length
    L = (chr for chr in word.split('') when chr.match /[a-z]/).length
    variations = 0
    variations += @nCk(U + L, i) for i in [1..Math.min(U, L)]
    variations

  l33t_variations: (match) ->
    return 1 if not match.l33t
    variations = 1
    for subbed, unsubbed of match.sub
      # lower-case match.token before calculating: capitalization shouldn't affect l33t calc.
      chrs = match.token.toLowerCase().split('')
      S = (chr for chr in chrs when chr == subbed).length   # num of subbed chars
      U = (chr for chr in chrs when chr == unsubbed).length # num of unsubbed chars
      if S == 0 or U == 0
        # for this sub, password is either fully subbed (444) or fully unsubbed (aaa)
        # treat that as doubling the space (attacker needs to try fully subbed chars in addition to
        # unsubbed.)
        variations *= 2
      else
        # this case is similar to capitalization:
        # with aa44a, U = 3, S = 2, attacker needs to try unsubbed + one sub + two subs
        p = Math.min(U, S)
        possibilities = 0
        possibilities += @nCk(U + S, i) for i in [1..p]
        variations *= possibilities
    variations

  # utilities --------------------------------------------------------------------

module.exports = scoring
