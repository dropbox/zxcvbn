import { IDataGenerator } from "./IDataGenerator";
import axios from "axios";
import iconv from "iconv-lite";

type Options = {
    splitter: string,
    commentPrefixes: string[],
    removeDuplicates: boolean,
    trimWhitespaces: boolean,
    toLowerCase: boolean,
    encoding?: string,
};

const defaultOptions: Options = {
    splitter: "\n",
    commentPrefixes: ["#", "//"],
    removeDuplicates: true,
    trimWhitespaces: true,
    toLowerCase: true,
}

export class SimpleListGenerator implements IDataGenerator {
    public data: any = [];
    private url: string;
    private options: Options;

    constructor(url: string, options: any) {
        this.url = url;
        this.options = Object.assign({}, defaultOptions);
        Object.assign(this.options, options);
    }

    public async run(): Promise<string[]> {
        console.log("Downloading");
        const data = (await axios.get(this.url, {
            responseType: this.options.encoding ? "arraybuffer" : undefined,
        })).data;
        if (this.options.encoding) {
            console.log(this.options.encoding)
            this.data = iconv.decode(data, this.options.encoding);
        } else {
            this.data = data;
        }
        this.data = this.data.split(this.options.splitter);
        if (Array.isArray(this.options.commentPrefixes)) {
            console.log("Filtering comments");
            for (const p of this.options.commentPrefixes) {
                this.data = this.data.filter((l) => !l.startsWith(p));
            }
        }
        if (this.options.trimWhitespaces) {
            console.log("Filtering whitespaces");
            this.data = this.data.map((l) => l.trim());
        }
        if (this.options.toLowerCase) {
            console.log("Converting to lowercase");
            this.data = this.data.map((l) => l.toLowerCase());
        }
        if (this.options.removeDuplicates) {
            console.log("Filtering duplicates");
            this.data = this.data.filter((item, pos) => {
                return this.data.indexOf(item) == pos;
            });
        }
        return this.data;
    }
}