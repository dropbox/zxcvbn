const matching = require('../lib/matching');
const scoring = require('../lib/scoring');

const fs = require('fs');
const byline = require('byline');
const { sprintf } = require('sprintf-js');


function check_usage() {
  const usage = `\

Run a frequency count on the raw 10M xato password set and keep counts over CUTOFF in
descending frequency. That file can be found by googling around for:
"xato 10-million-combos.txt"

Passwords that both:
-- fully match according to zxcvbn's date, year, repeat, sequence or keyboard matching algs
-- have a higher rank than the corresponding match guess number

are excluded from the final password set, since zxcvbn would score them lower through
other means anyhow. in practice this rules out dates and years most often and makes room
for more useful data.

To use, first run from zxcvbn base dir:

npm run build

then change into data-scripts directory and run:

coffee count_xato.coffee --nodejs xato_file.txt ../data/passwords.txt
\
`;
  const valid =
    process.argv.length === 5
    && (process.argv[0] === 'coffee') && ['--nodejs', '-n'].includes(process.argv[2])
    && (__dirname.split('/').slice(-1)[0] === 'data-scripts');

  if (!valid) {
    console.log(usage);
    process.exit(0);
  }
}

// after all passwords are counted, discard pws with counts <= COUNTS
const CUTOFF = 10;

// to save memory, after every batch of size BATCH_SIZE, go through counts and delete
// long tail of entries with only one count.
const BATCH_SIZE = 1000000;

function normalize(token) {
  return token.toLowerCase();
}

function should_include(password, xato_rank) {
  for (let i = 0, end = password.length; i < end; i++) {
    if (password.charCodeAt(i) > 127) {
      // xato mostly contains ascii-only passwords, so in practice
      // this will only skip one or two top passwords over the cutoff.
      // were that not the case / were this used on a different data source, consider using
      // a unidecode-like library instead, similar to count_wikipedia / count_wiktionary
      console.log(`SKIPPING non-ascii password=${password}, rank=${xato_rank}`);
      return false;
    }
  }
  let matches = [];
  for (let matcher of [
    matching.spatial_match,
    matching.repeat_match,
    matching.sequence_match,
    matching.regex_match,
    matching.date_match
    ]) {
    matches.push(...matcher.call(matching, password));
  }
  matches = matches.filter(match =>
    // only keep matches that span full password
    (match.i === 0) && (match.j === (password.length - 1))
  );
  for (let match of matches) {
    if (scoring.estimate_guesses(match, password) < xato_rank) {
      // filter out this entry: non-dictionary matching will assign
      // a lower guess estimate.
      return false;
    }
  }
  return true;
}

function prune(counts) {
  for (const [pw, count] of counts) {
    if (count === 1) {
      counts.delete(pw);
    }
  }
}

function main(xato_filename, output_filename) {
  const counts = new Map();  // maps pw -> count
  let skipped_lines = 0;     // skipped lines in xato file -- lines w/o two tokens
  let line_count = 0;        // current number of lines processed
  const stream = byline.createStream(fs.createReadStream(xato_filename, {encoding: 'utf8'}));
  stream.on('readable', () => {
    let line;
    while (null !== (line = stream.read())) {
      line_count += 1;
      if ((line_count % BATCH_SIZE) === 0) {
        console.log('counting tokens:', line_count);
        prune(counts);
      }
      const tokens = line.trim().split(/\s+/);
      if (tokens.length !== 2) {
        skipped_lines += 1;
        continue;
      }
      let [username, password] = tokens.slice(0, 2);
      password = normalize(password);
      if (counts.has(password)) {
        counts.set(password, counts.get(password) + 1);
      } else {
        counts.set(password, 1);
      }
    }
  });
  stream.on('end', function() {
    console.log('skipped lines:', skipped_lines);
    let pairs = [];
    console.log('copying to tuples');
    for (const [pw, count] of counts) {
      if (count > CUTOFF) {
        pairs.push([pw, count]);
      }
      // save memory to avoid v8 1GB limit
      counts.delete(pw);
    }
    console.log('sorting');
    // sort by count DESC, password ASC
    pairs.sort(([password1, count1], [password2, count2]) => {
      const diff = count2 - count1;
      if (diff === 0) {
        return password1.localeCompare(password2);
      } else {
        return diff;
      }
    });
    console.log('filtering');
    pairs = pairs.filter(([pw, _], i) => should_include(pw, i + 1));
    const output_stream = fs.createWriteStream(output_filename, {encoding: 'utf8'});
    for (let [pw, count] of pairs) {
      output_stream.write(sprintf("%-15s %d\n", pw, count));
    }
    output_stream.end();
  });
}

check_usage();
main(process.argv[3], process.argv[4]);
