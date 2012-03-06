var time, zxcvbn;

time = function() {
  return (new Date()).getTime();
};

zxcvbn = function(password) {
  var matches, result, start;
  start = time();
  matches = omnimatch(password);
  result = minimum_entropy_match_sequence(password, matches);
  result.calc_time = time() - start;
  return result;
};

if (typeof window !== "undefined" && window !== null) window.zxcvbn = zxcvbn;
