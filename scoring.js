var GUESS_RATE_PER_SECOND, KEYBOARD_BRANCHING, KEYBOARD_SIZE, KEYPAD_BRANCHING, KEYPAD_SIZE, NUM_DAYS, NUM_MONTHS, NUM_YEARS, bruteforce_entropy, calc_bruteforce_cardinality, calc_entropy, date_entropy, dictionary_entropy, digits_entropy, display_info, log2, minimum_entropy_match_sequence, nCk, nPk, repeat_entropy, sequence_entropy, spatial_entropy, year_entropy,
  __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

nPk = function(n, k) {
  var m, result, _ref;
  result = 1;
  for (m = _ref = n - k + 1; _ref <= n ? m <= n : m >= n; _ref <= n ? m++ : m--) {
    result *= m;
  }
  return result;
};

nCk = function(n, k) {
  var k_fact, m;
  k_fact = 1;
  for (m = 1; 1 <= k ? m <= k : m >= k; 1 <= k ? m++ : m--) {
    k_fact *= m;
  }
  return nPk(n, k) / k_fact;
};

log2 = function(n) {
  return Math.log(n) / Math.log(2);
};

GUESS_RATE_PER_SECOND = 1000;

minimum_entropy_match_sequence = function(password, matches) {
  var augmented, backpointers, bruteforce_cardinality, candidate_entropy, i, j, k, match, min_entropy, min_match, prev_entropy, start_i, up_to_k, _i, _j, _k, _l, _len, _len2, _ref, _ref2, _ref3, _results, _results2;
  bruteforce_cardinality = calc_bruteforce_cardinality(password);
  up_to_k = [];
  backpointers = [];
  k = 0;
  while (k < password.length) {
    prev_entropy = up_to_k[k - 1] || 0;
    up_to_k[k] = prev_entropy + log2(bruteforce_cardinality);
    backpointers[k] = null;
    for (_i = 0, _len = matches.length; _i < _len; _i++) {
      match = matches[_i];
      _ref = match.ij, i = _ref[0], j = _ref[1];
      if (i > k) break;
      if (j > k) continue;
      candidate_entropy = (up_to_k[i - 1] || 0) + calc_entropy(match);
      if (candidate_entropy < up_to_k[j]) {
        up_to_k[j] = candidate_entropy;
        backpointers[j] = match;
      }
    }
    k += 1;
  }
  k = password.length - 1;
  min_match = [];
  min_entropy = up_to_k[k];
  while (k > 0) {
    match = backpointers[k];
    if (match) {
      min_match.push(match);
      k = match.ij[0] - 1;
    } else {
      k -= 1;
    }
  }
  min_match.reverse();
  start_i = 0;
  augmented = [];
  for (_j = 0, _len2 = min_match.length; _j < _len2; _j++) {
    match = min_match[_j];
    _ref2 = match.ij, i = _ref2[0], j = _ref2[1];
    if (i - start_i > 0) {
      augmented.push({
        pattern: 'bruteforce',
        ij: (function() {
          _results = [];
          for (var _k = start_i; start_i <= i ? _k < i : _k > i; start_i <= i ? _k++ : _k--){ _results.push(_k); }
          return _results;
        }).apply(this),
        token: password.slice(start_i, i),
        cardinality: bruteforce_cardinality
      });
    }
    start_i = j + 1;
    augmented.push(match);
  }
  if (start_i < password.length) {
    augmented.push({
      pattern: 'bruteforce',
      ij: (function() {
        _results2 = [];
        for (var _l = start_i, _ref3 = password.length; start_i <= _ref3 ? _l <= _ref3 : _l >= _ref3; start_i <= _ref3 ? _l++ : _l--){ _results2.push(_l); }
        return _results2;
      }).apply(this),
      token: password.slice(start_i, password.length + 1 || 9e9),
      cardinality: bruteforce_cardinality
    });
  }
  min_match = augmented;
  return {
    password: password,
    crack_time: display_info(Math.pow(2, min_entropy) * (1 / GUESS_RATE_PER_SECOND)),
    min_entropy: Math.round(min_entropy),
    min_match: min_match
  };
};

calc_entropy = function(match) {
  if (match.entropy != null) return match.entropy;
  return match.entropy = (function() {
    switch (match.pattern) {
      case 'repeat':
        return repeat_entropy(match);
      case 'sequence':
        return sequence_entropy(match);
      case 'digits':
        return digits_entropy(match);
      case 'year':
        return year_entropy(match);
      case 'date':
        return date_entropy(match);
      case 'spatial':
        return spatial_entropy(match);
      case 'dictionary':
        return dictionary_entropy(match);
    }
  })();
};

repeat_entropy = function(match) {
  var cardinality;
  cardinality = calc_bruteforce_cardinality(match.token);
  return log2(cardinality * match.token.length);
};

sequence_entropy = function(match) {
  var base_entropy, first_chr;
  first_chr = match.token[0];
  if (first_chr === ('a' || '1')) {
    base_entropy = 1;
  } else {
    if (first_chr.match(/\d/)) {
      base_entropy = log2(10);
    } else if (first_chr.match(/[a-z]/)) {
      base_entropy = log2(26);
    } else {
      base_entropy = log2(26) + 1;
    }
  }
  if (!match.ascending) base_entropy += 1;
  return base_entropy + log2(match.token.length);
};

digits_entropy = function(match) {
  return log2(Math.pow(10, match.token.length));
};

NUM_YEARS = 119;

NUM_MONTHS = 12;

NUM_DAYS = 31;

year_entropy = function(match) {
  return log2(NUM_YEARS);
};

date_entropy = function(match) {
  var entropy;
  if (match.year < 100) {
    entropy = log2(NUM_DAYS * NUM_MONTHS * 100);
  } else {
    entropy = log2(NUM_DAYS * NUM_MONTHS * NUM_YEARS);
  }
  if (match.separator) entropy += 2;
  return entropy;
};

KEYBOARD_BRANCHING = 6;

KEYBOARD_SIZE = 47;

KEYPAD_BRANCHING = 9;

KEYPAD_SIZE = 15;

spatial_entropy = function(match) {
  var branching, entropy, possible_turn_points, possible_turn_seqs, start_choices, _ref;
  if ((_ref = match.graph) === 'qwerty' || _ref === 'dvorak') {
    start_choices = KEYBOARD_SIZE;
    branching = KEYBOARD_BRANCHING;
  } else {
    start_choices = KEYPAD_SIZE;
    branching = KEYPAD_BRANCHING;
  }
  entropy = log2(start_choices * match.token.length);
  if (match.turns > 0) {
    possible_turn_points = match.token.length - 1;
    possible_turn_seqs = nCk(possible_turn_points, match.turns);
    entropy += log2(branching * possible_turn_seqs);
  }
  return entropy;
};

dictionary_entropy = function(match) {
  var chr, entropy, h4x_chrs, k, num_alpha, num_h4x, num_possibles, num_upper, sub_chrs, v;
  entropy = log2(match.rank);
  if (match.token.match(/^[A-Z][^A-Z]+$/)) {
    entropy += 1;
  } else if (match.token.match(/^[^A-Z]+[A-Z]$/)) {
    entropy += 2;
  } else if (match.token.match(/^[^a-z]+$/)) {
    entropy += 2;
  } else if (match.token.match(/^[^a-z]+[^A-Z]+[^a-z]$/)) {
    entropy += 2;
  } else if (!match.token.match(/^[^A-Z]+$/)) {
    num_alpha = ((function() {
      var _i, _len, _ref, _results;
      _ref = match.token;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chr = _ref[_i];
        if (chr.match(/[A-Za-z]/)) _results.push(chr);
      }
      return _results;
    })()).length;
    num_upper = ((function() {
      var _i, _len, _ref, _results;
      _ref = match.token;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chr = _ref[_i];
        if (chr.match(/[A-Z]/)) _results.push(chr);
      }
      return _results;
    })()).length;
    entropy += log2(nCk(num_alpha, num_upper));
  }
  if (match.h4x0rd) {
    sub_chrs = (function() {
      var _ref, _results;
      _ref = match.sub;
      _results = [];
      for (k in _ref) {
        v = _ref[k];
        _results.push(v);
      }
      return _results;
    })();
    h4x_chrs = (function() {
      var _ref, _results;
      _ref = match.sub;
      _results = [];
      for (k in _ref) {
        v = _ref[k];
        _results.push(k);
      }
      return _results;
    })();
    num_possibles = ((function() {
      var _i, _len, _ref, _results;
      _ref = match.token;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chr = _ref[_i];
        if (__indexOf.call(sub_chrs.concat(h4x_chrs), chr) >= 0) {
          _results.push(chr);
        }
      }
      return _results;
    })()).length;
    num_h4x = ((function() {
      var _i, _len, _ref, _results;
      _ref = match.token;
      _results = [];
      for (_i = 0, _len = _ref.length; _i < _len; _i++) {
        chr = _ref[_i];
        if (__indexOf.call(h4x_chrs, chr) >= 0) _results.push(chr);
      }
      return _results;
    })()).length;
    entropy += log2(nCk(num_possibles, num_h4x));
  }
  return entropy;
};

bruteforce_entropy = function(match) {
  return log2(Math.pow(match.cardinality, match.token.length));
};

calc_bruteforce_cardinality = function(password) {
  var cardinality, chr, digits, lower, ord, symbols, upper, _i, _len, _ref;
  _ref = [false, false, false, false], lower = _ref[0], upper = _ref[1], digits = _ref[2], symbols = _ref[3];
  for (_i = 0, _len = password.length; _i < _len; _i++) {
    chr = password[_i];
    ord = chr.charCodeAt(0);
    if ((0x30 <= ord && ord <= 0x39)) {
      digits = true;
    } else if ((0x41 <= ord && ord <= 0x5a)) {
      upper = true;
    } else if ((0x61 <= ord && ord <= 0x7a)) {
      lower = true;
    } else {
      symbols = true;
    }
  }
  cardinality = 0;
  if (digits) cardinality += 10;
  if (upper) cardinality += 26;
  if (lower) cardinality += 26;
  if (symbols) cardinality += 33;
  return cardinality;
};

display_info = function(seconds) {
  var century, day, hour, minute, month, year;
  minute = 60;
  hour = minute * 60;
  day = hour * 24;
  month = day * 31;
  year = month * 12;
  century = year * 100;
  if (seconds < minute) {
    return {
      quality: 0,
      display: 'instant'
    };
  } else if (seconds < hour) {
    return {
      quality: 1,
      display: "" + (1 + Math.ceil(seconds / minute)) + " minutes"
    };
  } else if (seconds < day) {
    return {
      quality: 1,
      display: "" + (1 + Math.ceil(seconds / hour)) + " hours"
    };
  } else if (seconds < month) {
    return {
      quality: 2,
      display: "" + (1 + Math.ceil(seconds / day)) + " days"
    };
  } else if (seconds < year) {
    return {
      quality: 3,
      display: "" + (1 + Math.ceil(seconds / month)) + " months"
    };
  } else if (seconds < century) {
    return {
      quality: 4,
      display: "" + (1 + Math.ceil(seconds / year)) + " years"
    };
  } else {
    return {
      quality: 5,
      display: 'centuries'
    };
  }
};
