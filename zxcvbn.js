(function() {
  var time, zxcvbn;

  time = function() {
    return (new Date()).getTime();
  };

  zxcvbn = function(password) {
    var best_match_data, matches, start;
    start = time();
    matches = omnimatch(password);
    best_match_data = minimum_entropy_match_sequence(password, matches);
    best_match_data.calc_time = time() - start;
    return best_match_data;
  };

  if (typeof window !== "undefined" && window !== null) window.zxcvbn = zxcvbn;

}).call(this);
