const testPasswords = `\
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
Ba9ZyWABu99[BK#6MBgbH88Tofv)vs$w\
`;

const resultsTmpl = `\
{{#results}}
<table class="result">
  <tr>
    <td>password: </td>
    <td colspan="2"><strong>{{password}}</strong></td>
  </tr>
  <tr>
    <td>guessesLog10: </td>
    <td colspan="2">{{guessesLog10}}</td>
  </tr>
  <tr>
    <td>score: </td>
    <td>{{score}} / 4</td>
  <tr>
    <td>function runtime (ms): </td>
    <td colspan="2">{{calcTime}}</td>
  </tr>
  <tr>
    <td colspan="3">guess times:</td>
  </tr>
  {{& guessTimesDisplay}}
  {{& feedbackDisplay }}
  <tr>
    <td colspan="3"><strong>match sequence:</strong></td>
  </tr>
</table>
{{& sequenceDisplay}}
{{/results}}\
`;

const guessTimesTmpl = `\
<tr>
  <td>100 / hour:</td>
  <td>{{onlineThrottling100PerHour}}</td>
  <td> (throttled online attack)</td>
</tr>
<tr>
  <td>10&nbsp; / second:</td>
  <td>{{onlineNoThrottling10PerSecond}}</td>
  <td> (unthrottled online attack)</td>
</tr>
<tr>
  <td>10k / second:</td>
  <td>{{offlineSlowHashing1e4PerSecond}}</td>
  <td> (offline attack, slow hash, many cores)</td>
<tr>
  <td>10B / second:</td>
  <td>{{offlineFastHashing1e10PerSecond}}</td>
  <td> (offline attack, fast hash, many cores)</td>
</tr>\
`;

const feedbackTmpl = `\
{{#warning}}
<tr>
  <td>warning: </td>
  <td colspan="2">{{warning}}</td>
</tr>
{{/warning}}
{{#hasSuggestions}}
<tr>
  <td style="vertical-align: top">suggestions:</td>
  <td colspan="2">
    {{#suggestions}}
    - {{.}} <br />
    {{/suggestions}}
  </td>
</tr>
{{/hasSuggestions}}\
`;

const propsTmpl = `\
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
    <td>guessesLog10:</td>
    <td>{{guessesLog10}}</td>
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
    <td>dictionaryName:</td>
    <td>{{dictionaryName}}</td>
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
    <td>{{subDisplay}}</td>
  </tr>
  <tr>
    <td>un-l33ted:</td>
    <td>{{matchedWord}}</td>
  </tr>
  {{/l33t}}
  <tr>
    <td>base-guesses:</td>
    <td>{{baseGuesses}}</td>
  </tr>
  <tr>
    <td>uppercase-variations:</td>
    <td>{{uppercaseVariations}}</td>
  </tr>
  <tr>
    <td>l33t-variations:</td>
    <td>{{l33tVariations}}</td>
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
    <td>{{shiftedCount}}</td>
  </tr>
  {{/graph}}
  {{#baseToken}}
  <tr>
    <td>baseToken:</td>
    <td>'{{baseToken}}'</td>
  </tr>
  <tr>
    <td>guesses:</td>
    <td>{{guesses}}</td>
  </tr>
  <tr>
    <td>numRepeats:</td>
    <td>{{repeatCount}}</td>
  </tr>
  {{/baseToken}}
  {{#sequenceName}}
  <tr>
    <td>sequence-name:</td>
    <td>{{sequenceName}}</td>
  </tr>
  <tr>
    <td>sequence-size</td>
    <td>{{sequenceSpace}}</td>
  </tr>
  <tr>
    <td>ascending:</td>
    <td>{{ascending}}</td>
  </tr>
  {{/sequenceName}}
  {{#regexName}}
  <tr>
    <td>regexName:</td>
    <td>{{regexName}}</td>
  </tr>
  {{/regexName}}
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
</div>\
`;

const roundToXDigits = (n, x) => Math.round(n * Math.pow(10, x)) / Math.pow(10, x);

const roundLogs = function(r) {
    r.guessesLog10 = roundToXDigits(r.guessesLog10, 5);
    return Array.from(r.sequence).map((m) =>
        (m.guessesLog10 = roundToXDigits(m.guessesLog10, 5)));
};

$(function() {
    console.log(zxcvbn);
    let r;
    window.zxcvbn = zxcvbn;
    const resultsLst = [];
    for (let password of testPasswords.split('\n')) {
        if (password) {
          r = zxcvbn(password);
            console.log(r);
            roundLogs(r);
            r.sequenceDisplay = Mustache.render(propsTmpl, r);
            r.guessTimesDisplay = Mustache.render(guessTimesTmpl, r.crackTimesDisplay);
            r.feedback.hasSuggestions = r.feedback.suggestions.length > 0;
            r.feedbackDisplay = Mustache.render(feedbackTmpl, r.feedback);
            resultsLst.push(r);
        }
    }

    let rendered = Mustache.render(resultsTmpl, {
        results: resultsLst,
    });
    $('#results').html(rendered);

    let lastQ = '';
    const _listener = function() {
        const current = $('#search-bar').val();
        if (!current) {
            $('#search-results').html('');
            return;
        }
        if (current !== lastQ) {
            lastQ = current;
            r = zxcvbn(current);
            roundLogs(r);
            r.sequenceDisplay = Mustache.render(propsTmpl, r);
            r.guessTimesDisplay = Mustache.render(guessTimesTmpl, r.crackTimesDisplay);
            r.feedback.hasSuggestions = r.feedback.suggestions.length > 0;
            r.feedbackDisplay = Mustache.render(feedbackTmpl, r.feedback);
            const results = { results: [r] };
            rendered = Mustache.render(resultsTmpl, results);
            return $('#search-results').html(rendered);
        }
    };

    return setInterval(_listener, 100);
});