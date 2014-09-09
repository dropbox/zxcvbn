zxcvbn = require('../zxcvbn').zxcvbn;
assert = require('assert');

describe 'zxcvbn', ->
  describe '#scoring', ->
    it 'should be stateless', ->
      password = 'jhakef-87';

      assert.equal(zxcvbn(password).score, 4, 'score is 4 before adding to user_inputs');
      assert.equal(zxcvbn(password, [ password ]).score, 0, 'score drops to 0 when password is added to user_inputs');
      assert.equal(zxcvbn(password).score, 4, "score is 4 again when password no longer in user_inputs");
