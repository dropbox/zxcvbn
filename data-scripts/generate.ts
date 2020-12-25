import { SimpleListGenerator } from "./_generators/SimpleListGenerator";
import { registerList, run } from "./_helpers/runtime";

registerList("en", "commonWords", "https://gist.githubusercontent.com/h3xx/1976236/raw", SimpleListGenerator);
registerList("en", "firstnames", "https://raw.githubusercontent.com/dominictarr/random-name/master/first-names.txt", SimpleListGenerator);
registerList("en", "lastnames", "https://raw.githubusercontent.com/arineng/arincli/master/lib/last-names.txt", SimpleListGenerator);

registerList("de", "commonWords", "http://pcai056.informatik.uni-leipzig.de/downloads/etc/legacy/Papers/top1000de.txt", SimpleListGenerator, { encoding: "iso-8859-1" });
registerList("de", "firstnames", "https://gist.githubusercontent.com/hrueger/2aa48086e9720ee9b87ec734889e1b15/raw", SimpleListGenerator);
registerList("de", "lastnames", "https://gist.githubusercontent.com/hrueger/6599d1ac1e03b4c3dc432d722ffcefd0/raw", SimpleListGenerator);

registerList("common", "passwords", "https://raw.githubusercontent.com/DavidWittman/wpxmlrpcbrute/master/wordlists/1000-most-common-passwords.txt", SimpleListGenerator);
run();