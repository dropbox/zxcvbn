/*
 * decaffeinate suggestions:
 * DS101: Remove unnecessary use of Array.from
 * DS102: Remove unnecessary code created because of implicit returns
 * DS202: Simplify dynamic range loops
 * DS205: Consider reworking code to avoid use of IIFEs
 * Full docs: https://github.com/decaffeinate/decaffeinate/blob/master/docs/suggestions.md
 */
const matching = require('../lib/matching');
const scoring = require('../lib/scoring');

const fs = require('fs');
const byline = require('byline');
const { sprintf } = require('sprintf-js');


const check_usage = function() {
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
  let valid = process.argv.length === 5;
  valid = valid && (process.argv[0] === 'coffee') && ['--nodejs', '-n'].includes(process.argv[2]);
  valid = valid && (__dirname.split('/').slice(-1)[0] === 'data-scripts');
  if (!valid) {
    console.log(usage);
    return process.exit(0);
  }
};

// after all passwords are counted, discard pws with counts <= COUNTS
const CUTOFF = 10;

// to save memory, after every batch of size BATCH_SIZE, go through counts and delete
// long tail of entries with only one count.
const BATCH_SIZE = 1000000;

const counts = {};       // maps pw -> count
let skipped_lines = 0; // skipped lines in xato file -- lines w/o two tokens
let line_count = 0;    // current number of lines processed

const normalize = token => token.toLowerCase();

const should_include = function(password, xato_rank) {
  let i;
  let asc, end;
  for (i = 0, end = password.length, asc = 0 <= end; asc ? i < end : i > end; asc ? i++ : i--) {
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
    matches.push.apply(matches, matcher.call(matching, password));
  }
  matches = matches.filter(match =>
    // only keep matches that span full password
    (match.i === 0) && (match.j === (password.length - 1))
  );
  for (let match of Array.from(matches)) {
    if (scoring.estimate_guesses(match, password) < xato_rank) {
      // filter out this entry: non-dictionary matching will assign
      // a lower guess estimate.
      return false;
    }
  }
  return true;
};

const prune = counts =>
  (() => {
    const result = [];
    for (let pw in counts) {
      const count = counts[pw];
      if (count === 1) {
        result.push(delete counts[pw]);
      } else {
        result.push(undefined);
      }
    }
    return result;
  })()
;

const main = function(xato_filename, output_filename) {
  const stream = byline.createStream(fs.createReadStream(xato_filename, {encoding: 'utf8'}));
  stream.on('readable', () =>
    (() => {
      let line;
      const result = [];
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
        let [username, password] = Array.from(tokens.slice(0, 2));
        password = normalize(password);
        if (password in counts) {
          result.push(counts[password] += 1);
        } else {
          result.push(counts[password] = 1);
        }
      }
      return result;
    })()
  );
  return stream.on('end', function() {
    let count;
    console.log('skipped lines:', skipped_lines);
    let pairs = [];
    console.log('copying to tuples');
    for (var pw in counts) {
      count = counts[pw];
      if (count > CUTOFF) {
        pairs.push([pw, count]);
      }
      delete counts[pw];
    } // save memory to avoid v8 1GB limit
    console.log('sorting');
    pairs.sort((p1, p2) =>
      // sort by count. higher counts go first.
      p2[1] - p1[1]);
    console.log('filtering');
    pairs = pairs.filter(function(pair, i) {
      const rank = i + 1;
      [pw, count] = Array.from(pair);
      return should_include(pw, rank);
    });
    const output_stream = fs.createWriteStream(output_filename, {encoding: 'utf8'});
    for (let pair of Array.from(pairs)) {
      [pw, count] = Array.from(pair);
      output_stream.write(sprintf("%-15s %d\n", pw, count));
    }
    return output_stream.end();
  });
};

check_usage();
main(process.argv[3], process.argv[4]);
