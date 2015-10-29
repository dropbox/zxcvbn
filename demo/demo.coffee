
test_passwords = '''
zxcvbn
qwER43@!
Tr0ub4dour&3
correcthorsebatterystaple
coRrecth0rseba++ery9.23.2007staple$

p@ssword
p@$$word
123456
123456789
11111111
zxcvbnm,./
love88
angel08
monkey13
iloveyou
woaini
wang
tianya
zhang198822
li4478
a6a4Aa8a
b6b4Bb8b
z6z4Zz8z
aiIiAaIA
zxXxZzXZ
pässwörd
alpha bravo charlie delta
a b c d e f g h i j k l m n o p q r s t u v w x y z 0 1 2 3 4 5 6 7 8 9
a b c 1 2 3
correct-horse-battery-staple
correct.horse.battery.staple
correct,horse,battery,staple
correct~horse~battery~staple
WhyfaultthebardifhesingstheArgives’harshfate?
Eupithes’sonAntinousbroketheirsilence
Athena lavished a marvelous splendor
buckmulliganstenderchant
seethenthatyewalkcircumspectly
LihiandthepeopleofMorianton
establishedinthecityofZarahemla
!"£$%^&*()

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
    <td colspan="2"><strong>{{password}}</strong></td>
  </tr>
  <tr>
    <td>guesses_log10: </td>
    <td colspan="2">{{guesses_log10}}</td>
  </tr>
  <tr>
    <td>score: </td>
    <td>{{score}} / 4</td>
  <tr>
    <td>function runtime (ms): </td>
    <td colspan="2">{{calc_time}}</td>
  </tr>
  <tr>
    <td colspan="3">guess times:</td>
  </tr>
  {{& guess_times_display}}
  {{& feedback_display }}
  <tr>
    <td colspan="3"><strong>match sequence:</strong></td>
  </tr>
</table>
{{& sequence_display}}
{{/results}}
'''

guess_times_tmpl = '''
  <tr>
    <td>100 / hour:</td>
    <td>{{online_throttling_100_per_hour}}</td>
    <td> (throttled online attack)</td>
  </tr>
  <tr>
    <td>10&nbsp; / second:</td>
    <td>{{online_no_throttling_10_per_second}}</td>
    <td> (unthrottled online attack)</td>
  </tr>
  <tr>
    <td>10k / second:</td>
    <td>{{offline_slow_hashing_1e4_per_second}}</td>
    <td> (offline attack, slow hash, many cores)</td>
  <tr>
    <td>10B / second:</td>
    <td>{{offline_fast_hashing_1e10_per_second}}</td>
    <td> (offline attack, fast hash, many cores)</td>
  </tr>
'''

feedback_tmpl = '''
{{#warning}}
<tr>
  <td>warning: </td>
  <td colspan="2">{{warning}}</td>
</tr>
{{/warning}}
{{#has_suggestions}}
<tr>
  <td style="vertical-align: top">suggestions:</td>
  <td colspan="2">
    {{#suggestions}}
    - {{.}} <br />
    {{/suggestions}}
  </td>
</tr>
{{/has_suggestions}}
'''

props_tmpl = '''
<div class="match-sequence">
{{#sequence}}
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
    <td>{{length}}</td>
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
    <td>uppercase-variations:</td>
    <td>{{uppercase_variations}}</td>
  </tr>
  <tr>
    <td>l33t-variations:</td>
    <td>{{l33t_variations}}</td>
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
  <tr>
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
{{/sequence}}
</div>
'''

round_to_x_digits = (n, x) ->
  Math.round(n * Math.pow(10, x)) / Math.pow(10, x)

round_logs = (r) ->
  r.guesses_log10 = round_to_x_digits(r.guesses_log10, 5)
  for m in r.sequence
    m.guesses_log10 = round_to_x_digits(m.guesses_log10, 5)

requirejs ['../dist/zxcvbn'], (zxcvbn) ->
  $ ->
    window.zxcvbn = zxcvbn
    results_lst = []
    for password in test_passwords.split('\n') when password
      r = zxcvbn(password)
      round_logs(r)
      r.sequence_display = Mustache.render(props_tmpl, r)
      r.guess_times_display = Mustache.render(guess_times_tmpl, r.crack_times_display)
      r.feedback.has_suggestions = r.feedback.suggestions.length > 0
      r.feedback_display = Mustache.render(feedback_tmpl, r.feedback)
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
        r.sequence_display = Mustache.render(props_tmpl, r)
        r.guess_times_display = Mustache.render(guess_times_tmpl, r.crack_times_display)
        r.feedback.has_suggestions = r.feedback.suggestions.length > 0
        r.feedback_display = Mustache.render(feedback_tmpl, r.feedback)
        results = {results: [r]}
        rendered = Mustache.render(results_tmpl, results)
        $('#search-results').html(rendered)

    setInterval _listener, 100
