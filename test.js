var password, results, results_tmpl, test_passwords;

test_passwords = 'zxcvbn\nTHEFUTUREISNOW\nbacktothefuture\ncorrecthorsebatterystaple\ncoRrecth0rseba++ery1.18.1958staple$\ntr0ub4d0ur&3\n\nRAINBOWSHELL123698745\n\nchangeme83\nsugarman4mayor\nsugarman\npassword1\nviking\nthx1138\nScoRpi0ns\n\nrianhunter2000\nryanhunter2000\n\nasdfghju7654rewq\nAOEUIDHG&*()LS_\n\n12345678\ndefghi6789\n\nD0g..................\n\nrosebud\nRosebud\nrosebuD\nRosebuD\nROSEBUD\nrosebud99\nRosebud99\nrosebuD99\nRosebuD99\nroSebud99\nr0s3bud99\nr0$38ud99\nR0$38uD99\nR0$38UD99\nr0$38UD99\nr0$38Ud99\n\nterrycrabtree\nverlinealmajhoub\n\neheuczkqyq\njrfkfrgexjlt\nhztuyuyktcjhfoc\njhynqzmmzumhihwegxyy\n\nDCcqyDaBdz\nissswmuZkNGM\nyUUjdWVoJBtErrM\nrWibMFACxAUGZmxhVncy\n\n>XE<68L3ju\nWABu99[BK#6M\nGaGxt<2qp4u3<dN\nBgbH88Ba9ZyTofv)vs$w\nBa9ZyWABu99[BK#6MBgbH88Tofv)vs$w';

results_tmpl = '<table>\n  <tr>\n    <th>password</th>\n    <th>calc millis</th>\n    <th>entropy</th>\n    <th>crack time</th>\n  </tr>\n  {{#results}}\n  <tr>\n    <td>\n      {{#min_match}}<span class="match" onclick="console.log(\'{{display}}\')">{{token}}</span>{{/min_match}}\n    </td>\n    <td>{{calc_time}}</td>\n    <td>~{{min_entropy}}</td>\n    <td>{{crack_time.display}}</td>\n  </tr>\n  {{/results}}\n</table>';

results = {
  results: (function() {
    var _i, _len, _ref, _results;
    _ref = test_passwords.split('\n');
    _results = [];
    for (_i = 0, _len = _ref.length; _i < _len; _i++) {
      password = _ref[_i];
      if (password) _results.push(zxcvbn(password));
    }
    return _results;
  })()
};

$(function() {
  var last_q, rendered, _listener;
  rendered = Mustache.render(results_tmpl, results);
  $('#results').html(rendered);
  last_q = '';
  _listener = function() {
    var current;
    current = $('#search').val().trim();
    if (current && (current !== last_q)) {
      last_q = current;
      results = {
        results: [zxcvbn(current)]
      };
      rendered = Mustache.render(results_tmpl, results);
      $('#search-results').html(rendered);
      return console.log(rendered);
    }
  };
  return setInterval(_listener, 100);
});
