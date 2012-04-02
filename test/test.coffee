
test_passwords = '''
zxcvbn
THEFUTUREISNOW
backtothefuture
correcthorsebatterystaple
coRrecth0rseba++ery9.23.2007staple$
tr0ub4d0ur&3

RAINBOWSHELL123698745

changeme83
sugarman4mayor
sugarman
password1
viking
thx1138
ScoRpi0ns

rianhunter2000
ryanhunter2000

asdfghju7654rewq
AOEUIDHG&*()LS_
do you know

12345678
defghi6789

D0g..................

rosebud
Rosebud
rosebuD
RosebuD
ROSEBUD
rosebud99
Rosebud99
rosebuD99
RosebuD99
roSebud99
r0s3bud99
r0$38ud99
R0$38uD99
R0$38UD99
r0$38UD99
r0$38Ud99

terrycrabtree
verlinealmajhoub

eheuczkqyq
jrfkfrgexjlt
hztuyuyktcjhfoc
jhynqzmmzumhihwegxyy

DCcqyDaBdz
issswmuZkNGM
yUUjdWVoJBtErrM
rWibMFACxAUGZmxhVncy

>XE<68L3ju
WABu99[BK#6M
GaGxt<2qp4u3<dN
BgbH88Ba9ZyTofv)vs$w
Ba9ZyWABu99[BK#6MBgbH88Tofv)vs$w
'''

results_tmpl = '''
<table>
  <tr>
    <th>password</th>
    <th>calc millis</th>
    <th>entropy</th>
    <th>crack time</th>
  </tr>
  {{#results}}
  <tr>
    <td>
      {{#match_sequence}}<span class="match" onclick="console.log('{{display}}')">{{token}}</span>{{/match_sequence}}
    </td>
    <td>{{calc_time}}</td>
    <td>{{entropy}}</td>
    <td>{{crack_time_display}}</td>
  </tr>
  {{/results}}
</table>
'''

zxcvbn_load_hook = ->
  $ ->
    results = {results: (zxcvbn(password) for password in test_passwords.split('\n') when password)}
    rendered = Mustache.render(results_tmpl, results)
    $('#results').html(rendered)

    last_q = ''
    _listener = ->
      current = $('#search').val().trim()
      if current and (current != last_q)
        last_q = current
        results = {results: [zxcvbn(current, ['dan', 'daniel', 'wheeler', 'dan@dropbox.com', 'dan.lowe.wheeler@gmail.com'])]}
        rendered = Mustache.render(results_tmpl, results)
        $('#search-results').html(rendered)

    setInterval _listener, 100
