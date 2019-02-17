#!/usr/bin/python

import sys
import os
import re
import operator
import datetime
import warnings
import multiprocessing
import time
import io

import nltk
from unidecode import unidecode

def usage():
    print('''
tokenize a directory of text and count unigrams.

usage:
%s input_dir ../data/english_wikipedia.txt

input_dir is the root directory where sentence files live. Each file should contain
one sentence per line, with punctuation. This script will walk the directory recursively,
looking for text files. For each text file, it will tokenize each sentence into words and
add them to a global unigram count, outputted to output.txt of the form:

word count
word count
...

in descending order of count.

For speed, tokenization is done w/ Penn Treebank regexes via nltk's port:
http://www.cis.upenn.edu/~treebank/tokenizer.sed
http://www.nltk.org/api/nltk.tokenize.html#module-nltk.tokenize.treebank

For input sentences, this script allows for the format output by WikiExtractor.py
https://github.com/attardi/wikiextractor

That is,
- lines starting with <doc... are ignored
- lines starting with </doc> are ignored
- blank lines are ignored

To obtain wikipedia dumps, visit: https://dumps.wikimedia.org/enwiki
And download the file ending in '-pages-articles.xml.bz2'. This includes wikipedia pages
and articles but not previous revisions, edit history, and metadata.

Then run:
./WikiExtractor.py -o en_sents --no-templates enwiki-20151002-pages-articles.xml.bz2

''' % sys.argv[0])


SENTENCES_PER_BATCH = 500000  # after each batch, delete all counts with count == 1 (hapax legomena)
PRE_SORT_CUTOFF = 300         # before sorting, discard all words with less than this count

ALL_NON_ALPHA = re.compile(r'^[\W\d]*$', re.UNICODE)
SOME_NON_ALPHA = re.compile(r'[\W\d]', re.UNICODE)


class TopTokenCounter(object):
    def __init__(self):
        self.count = {}
        self.legomena = set()
        self.discarded = set()

    def add_tokens(self, tokens, split_hyphens=True):
        for token in tokens:
            # add eg 'marxist-leninist' as two tokens instead of one
            if split_hyphens and token.count('-') in [1, 2]:
                for subtoken in token.split('-'):
                    self.add_token(subtoken)
            else:
                self.add_token(token)

    def add_token(self, token):
        if not self.should_include(token):
            self.discarded.add(token)
            return
        token = self.normalize(token)
        if token in self.count:
            self.legomena.discard(token)
            self.count[token] += 1
        else:
            self.legomena.add(token)
            self.count[token] = 1

    def should_include(self, token):
        if len(token) < 2:
            return False
        if len(token) <= 2 and SOME_NON_ALPHA.search(token):
            # B., '', (), ...
            return False
        if ALL_NON_ALPHA.match(token):
            # 1,000, <<>>, ...
            return False
        if token.startswith('/'):
            # eg //en.wikipedia.org/wiki, /doc
            return False
        if token.endswith('='):
            # id=, title=, ...
            return False
        return True

    def normalize(self, token):
        return token.lower()

    def batch_prune(self):
        for token in self.legomena:
            del self.count[token]
        self.legomena = set()

    def pre_sort_prune(self):
        under_cutoff = set()
        for token, count in self.count.items():
            if count < PRE_SORT_CUTOFF:
                under_cutoff.add(token)
        for token in under_cutoff:
            del self.count[token]
        self.legomena = set()

    def get_sorted_pairs(self):
        return sorted(self.count.items(), key=operator.itemgetter(1), reverse=True)

    def get_ts(self):
        return datetime.datetime.now().strftime("%b %d %Y %H:%M:%S")

    def get_stats(self):
        ts = self.get_ts()
        return "%s keys(count): %d" % (ts, len(self.count))

    def merge(self, other):
        self.discarded |= other.discarded
        self.legomena ^= other.legomena
        for token, num in other.count.items():
            if token in self.count:
                self.count[token] += num
            else:
                self.count[token] = num


def count_file(path):
    """
    Scan the file at given path, tokenize all lines and return the filled TopTokenCounter
    and the number of processed lines.
    """
    counter = TopTokenCounter()
    lines = 0
    for line in io.open(path, 'r', encoding='utf8'):
        with warnings.catch_warnings():
            # unidecode() occasionally (rarely but enough to clog terminal outout)
            # complains about surrogate characters in some wikipedia sentences.
            # ignore those warnings.
            warnings.simplefilter('ignore')
            line = unidecode(line)
        tokens = nltk.word_tokenize(line)
        counter.add_tokens(tokens)
        lines += 1
    return counter, lines


def main(input_dir_str, output_filename):
    counter = TopTokenCounter()
    print(counter.get_ts(), 'starting...')
    tic = time.time()
    pruned_lines = 0
    lines = 0
    files = 0
    process_pool = multiprocessing.Pool()
    # Some python iterator magic: Pool.imap() maps the given function over the iterable
    # using the process pool. The iterable is produced by creating the full path of every
    # file in every directory (thus, the nested generator expression).
    for fcounter, l in process_pool.imap(
            count_file, (os.path.join(root, fname)
                         for root, dirs, files in os.walk(input_dir_str, topdown=True)
                         if files
                         for fname in files), 4):
        lines += l
        files += 1
        counter.merge(fcounter)
        if (lines - pruned_lines) >= SENTENCES_PER_BATCH:
            counter.batch_prune()
            pruned_lines = lines
            print(counter.get_stats())

    toc = time.time()
    print("Finished reading input data. Read %d files with %d lines in %.2fs."
          % (files, lines, toc-tic))
    print(counter.get_stats())

    print('deleting tokens under cutoff of', PRE_SORT_CUTOFF)
    counter.pre_sort_prune()
    print('done')
    print(counter.get_stats())

    print(counter.get_ts(), 'sorting...')
    sorted_pairs = counter.get_sorted_pairs()
    print(counter.get_ts(), 'done')

    print('writing...')
    with io.open(output_filename, 'w', encoding='utf8') as f:
        for token, count in sorted_pairs:
            f.write('%-18s %d\n' % (token, count))
    sys.exit(0)


if __name__ == '__main__':
    if len(sys.argv) != 3:
        usage()
        sys.exit(0)
    else:
        main(*sys.argv[1:])

