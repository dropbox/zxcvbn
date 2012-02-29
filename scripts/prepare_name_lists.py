
import os
import codecs
import simplejson

def main():
    '''
    takes name lists from the the 2000 us census, prepares as a json array in order of frequency (most common names first).

    more info:
    http://www.census.gov/genealogy/www/data/2000surnames/index.html

    files in data are downloaded copies of:
    http://www.census.gov/genealogy/names/dist.all.last
    http://www.census.gov/genealogy/names/dist.male.first
    http://www.census.gov/genealogy/names/dist.female.first
    '''
    FILE_TMPL = '../data/us_census_2000_%s.txt'
    lists = ['surnames', 'male_first', 'female_first']
    with codecs.open('names.js', 'w', 'utf8') as f:
        for list_name in lists:
            json = to_js_obj(FILE_TMPL % list_name, list_name)
            f.write(json)
            f.write('\n')

def to_js_obj(path, obj_name):
    names = []
    for line in codecs.open(path, 'r', 'utf8'):
        name = line.split()[0].lower()
        names.append(name)
    return 'var %s = %s;\n' % (obj_name, simplejson.dumps(names, indent=2))

if __name__ == '__main__':
    if os.path.basename(os.getcwd()) != 'scripts':
        print 'run this from the scripts directory'
        exit(1)
    main()
