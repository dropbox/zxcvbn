var ALPHANUM_CHARS, KEYBOARD_BRANCHING, KEYBOARD_SIZE, KEYPAD_BRANCHING, KEYPAD_SIZE, NUM_DAYS, NUM_MONTHS, NUM_YEARS, PRINTABLE_CHARS, bruteforce_entropy, calc_entropy, date_entropy, dictionary_entropy, digits_entropy, log2, match, nCk, nPk, repeat_entropy, sequence_entropy, spatial_entropy, year_entropy, _i, _len, _ref,
  __indexOf = Array.prototype.indexOf || function(item) { for (var i = 0, l = this.length; i < l; i++) { if (i in this && this[i] === item) return i; } return -1; };

log2 = function(n) {
  return Math.log(n) / Math.log(2);
};

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

PRINTABLE_CHARS = 95;

ALPHANUM_CHARS = 62;

NUM_YEARS = 119;

NUM_MONTHS = 12;

NUM_DAYS = 31;

KEYBOARD_BRANCHING = 6;

KEYBOARD_SIZE = 47;

KEYPAD_BRANCHING = 9;

KEYPAD_SIZE = 15;

calc_entropy = function(match) {
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
    case 'bruteforce':
      return bruteforce_entropy(match);
  }
};

repeat_entropy = function(match) {
  return log2(PRINTABLE_CHARS * match.token.length);
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

_ref = bruteforce_match('lKajsf2-2-198877');
for (_i = 0, _len = _ref.length; _i < _len; _i++) {
  match = _ref[_i];
  console.log(match, calc_entropy(match));
}
