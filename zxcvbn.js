
/*
# zxcvbn: a password strength meter with solid math and clear assumptions.
#
# zxcvbn takes one argument, a password, and returns a js object describing the password's strengh.
# see the readme doc for details and examples.
#
# zxcvbn takes an optional second argument, other_user_inputs, a string of whitespace-delimited
# words from other inputs on the registration form (such as name, surname, dob, etc).
*/

(function() {
  var zxcvbn;

  zxcvbn = function(password, other_user_inputs) {
    return {
      matching_attacks: ['bruteforce,36', 'letters,12-digits,2', 'word,436-word,1022-digit,2'],
      matches: [['correcthorse77'], ['correcthorse', '77'], ['correct', 'horse', '77']],
      min_attack: 'word,436-word,1022-digit,2',
      attack_time: 4430,
      quality: 3,
      tip: "words make great passwords, but only when you use at least 4."
    };
  };

  if (typeof window !== "undefined" && window !== null) window.zxcvbn = zxcvbn;

}).call(this);
