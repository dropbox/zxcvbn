
import os
import time
import codecs
import urllib
import simplejson
import urllib2

from pprint import pprint

SLEEP_TIME = 10 # seconds

def main():
    '''
    wikitionary has a list of ~40k English words, ranked by frequency of occurance in TV and movie transcripts.
    more details at:
    http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/TV/2006/explanation

    the list is separated into pages of 1000 or 2000 terms each.
    * the first 10k words are separated into pages of 1000 terms each.
    * the remainder is separated into pages of 2000 terms each:
    urls look like this:

    http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/TV/2006/1-1000
    http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/TV/2006/1001-2000
    http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/TV/2006/2001-3000
    ...
    http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/TV/2006/9001-10000
    http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/TV/2006/10001-12000
    http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/TV/2006/12001-14000
    ...
    http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/TV/2006/38001-40000
    http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/TV/2006/40001-41284
    '''

    URL_TMPL = 'http://en.wiktionary.org/wiki/Wiktionary:Frequency_lists/TV/2006/%s'
    urls = []
    for i in xrange(10):
        freq_range = "%d-%d" % (i * 1000 + 1, (i+1) * 1000)
        urls.append(URL_TMPL % freq_range)

    for i in xrange(0,15):
        freq_range = "%d-%d" % (10000 + 2 * i * 1000 + 1, 10000 + (2 * i + 2) * 1000)
        urls.append(URL_TMPL % freq_range)

    urls.append(URL_TMPL % '40001-41284')

    ranked_terms = [] # ordered by rank, in decreasing frequency.
    for url in urls:
        html, cached = download(url)
        if not cached:
            time.sleep(SLEEP_TIME)
        new_terms = parse_terms(html)
        ranked_terms.extend(new_terms)

    with codecs.open('words.js', 'w', 'utf8') as f:
        f.write('var word_rank_lookup = ' + simplejson.dumps(ranked_terms, indent=2) + ';\n');

def download(url):
    '''
    scrape friendly: sleep 10 seconds between each request, cache each result.
    '''
    DOWNLOAD_TMPL = '../data/tv_and_movie_freqlist%s.html'
    freq_range = url[url.rindex('/')+1:]

    tmp_path = DOWNLOAD_TMPL % freq_range
    if os.path.exists(tmp_path):
        print 'cached........', url
        with codecs.open(tmp_path, 'r', 'utf8') as f:
            return f.read(), True
    with codecs.open(tmp_path, 'w', 'utf8') as f:
        print 'downloading...', url
        req = urllib2.Request(url, headers={
                'User-Agent': 'zxcvbn'
                })
        response = urllib2.urlopen(req)
        result = response.read().decode('utf8')
        f.write(result)
        return result, False

def parse_terms(doc):
    '''super fragile hax but checks the result at the end'''
    results = []
    last3 = ['', '', '']
    header = True
    for line in doc.split('\n'):
        last3.pop(0)
        last3.append(line.strip())
        if all(s.startswith('<td>') and not s == '<td></td>' for s in last3):
            if header:
                header = False
                continue
            last3 = [s.replace('<td>', '').replace('</td>', '').strip() for s in last3]
            rank, term, count = last3
            rank = int(rank.split()[0])
            term = term.replace('</a>', '')
            term = term[term.index('>')+1:]
            results.append(term)
    assert len(results) in [1000, 2000, 1284] # early docs have 1k entries, later have 2k, last doc has 1284
    return results

if __name__ == '__main__':
    if os.path.basename(os.getcwd()) != 'scripts':
        print 'run this from the scripts directory'
        exit(1)
    main()
