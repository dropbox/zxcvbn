
test_passwords = '''
zxcvbn
qwER43@!
Tr0ub4dour&3
correcthorsebatterystaple
coRrecth0rseba++ery9.23.2007staple$

D0g..................
abcdefghijk987654321
neverforget13/3/1997
1qaz2wsx3edc

temppass22
briansmith
briansmith4mayor
password1
viking
thx1138
ScoRpi0ns
do you know

ryanhunter2000
rianhunter2000

asdfghju7654rewq
AOEUIDHG&*()LS_

12345678
defghi6789

rosebud
Rosebud
ROSEBUD
rosebuD
ros3bud99
r0s3bud99
R0$38uD99

verlineVANDERMARK

eheuczkqyq
rWibMFACxAUGZmxhVncy
Ba9ZyWABu99[BK#6MBgbH88Tofv)vs$w
'''

results_tmpl = '''
{{#results}}
<table class="result">
  <tr>
    <td>password: </td>
    <td><strong>{{password}}</strong></td>
  </tr>
  <tr>
    <td>guesses_log10: </td>
    <td>{{guesses_log10}}</td>
  </tr>
  <tr>
    <td>calculated in (ms): </td>
    <td>{{calc_time}}</td>
  </tr>
  <tr>
    <td colspan="2"><strong>match sequence:</strong></td>
  </tr>
</table>
{{& match_sequence_display}}
{{/results}}
'''

props_tmpl = '''
<div class="match-sequence">
{{#match_sequence}}
<table>
  <tr>
    <td colspan="2">'{{token}}'</td>
  </tr>
  <tr>
    <td>pattern:</td>
    <td>{{pattern}}</td>
  </tr>
  <tr>
    <td>guesses_log10:</td>
    <td>{{guesses_log10}}</td>
  </tr>
  {{#cardinality}}
  <tr>
    <td>cardinality:</td>
    <td>{{cardinality}}</td>
  </tr>
  <tr>
    <td>length:</td>
    <td>{{token.length}}</td>
  </tr>
  {{/cardinality}}
  {{#rank}}
  <tr>
    <td>dictionary_name:</td>
    <td>{{dictionary_name}}</td>
  </tr>
  <tr>
    <td>rank:</td>
    <td>{{rank}}</td>
  </tr>
  <tr>
    <td>reversed:</td>
    <td>{{reversed}}</td>
  </tr>
  {{#l33t}}
  <tr>
    <td>l33t subs:</td>
    <td>{{sub_display}}</td>
  </tr>
  <tr>
    <td>un-l33ted:</td>
    <td>{{matched_word}}</td>
  </tr>
  {{/l33t}}
  <tr>
    <td>base-guesses:</td>
    <td>{{base_guesses}}</td>
  </tr>
  <tr>
    <td>uppercase-multiplier:</td>
    <td>{{uppercase_guesses}}</td>
  </tr>
  <tr>
    <td>l33t-multiplier:</td>
    <td>{{l33t_guesses}}</td>
  </tr>
  {{/rank}}
  {{#graph}}
  <tr>
    <td>graph:</td>
    <td>{{graph}}</td>
  </tr>
  <tr>
    <td>turns:</td>
    <td>{{turns}}</td>
  </tr>
  <tr>
    <td>shifted count:</td>
    <td>{{shifted_count}}</td>
  </tr>
  {{/graph}}
  {{#base_token}}
  <tr>
    <td>base_token:</td>
    <td>'{{base_token}}'</td>
  </tr>
  <tr>
    <td>base_guesses:</td>
    <td>{{base_guesses}}</td>
  </tr>
  <td>
    <td>num_repeats:</td>
    <td>{{repeat_count}}</td>
  </tr>
  {{/base_token}}
  {{#sequence_name}}
  <tr>
    <td>sequence-name:</td>
    <td>{{sequence_name}}</td>
  </tr>
  <tr>
    <td>sequence-size</td>
    <td>{{sequence_space}}</td>
  </tr>
  <tr>
    <td>ascending:</td>
    <td>{{ascending}}</td>
  </tr>
  {{/sequence_name}}
  {{#regex_name}}
  <tr>
    <td>regex_name:</td>
    <td>{{regex_name}}</td>
  </tr>
  {{/regex_name}}
  {{#day}}
  <tr>
    <td>day:</td>
    <td>{{day}}</td>
  </tr>
  <tr>
    <td>month:</td>
    <td>{{month}}</td>
  </tr>
  <tr>
    <td>year:</td>
    <td>{{year}}</td>
  </tr>
  <tr>
    <td>separator:</td>
    <td>'{{separator}}'</td>
  </tr>
  {{/day}}
</table>
{{/match_sequence}}
</div>
'''

round_to_x_digits = (n, x) ->
  Math.round(n * Math.pow(10, x)) / Math.pow(10, x)

round_logs = (r) ->
  r.guesses_log2  = round_to_x_digits(r.guesses_log2,  5)
  r.guesses_log10 = round_to_x_digits(r.guesses_log10, 5)
  for m in r.match_sequence
    m.guesses_log2  = round_to_x_digits(m.guesses_log2,  5)
    m.guesses_log10 = round_to_x_digits(m.guesses_log10, 5)

requirejs ['../dist/zxcvbn'], (zxcvbn) ->
  $ ->
    results_lst = []
    for password in test_passwords.split('\n') when password
      r = zxcvbn(password)
      round_logs(r)
      r.match_sequence_display = Mustache.render(props_tmpl, r)
      results_lst.push r

    rendered = Mustache.render(results_tmpl, {
      results: results_lst,
    })
    $('#results').html(rendered)

    last_q = ''
    _listener = ->
      current = $('#search-bar').val()
      unless current
        $('#search-results').html('')
        return
      if current != last_q
        last_q = current
        r = zxcvbn(current)
        round_logs(r)
        r.match_sequence_display = Mustache.render(props_tmpl, r)
        results = {results: [r]}
        rendered = Mustache.render(results_tmpl, results)
        $('#search-results').html(rendered)

    setInterval _listener, 100
