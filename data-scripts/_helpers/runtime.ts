import { IDataGenerator } from "data-scripts/_generators/IDataGenerator";
import * as fs from "fs";
import * as path from "path";

declare const global: any;

export type ListConfig = {
    language: string;
    filename: string;
    url: string;
    generator: IDataGenerator;
    options?: any;
};

export type GeneratorOptions = ListConfig[];

export function registerList(language: string, filename: string, url: string, generator: any, options?) {
    ensureGlobalLists();
    ensureGlobalCustomLists();
    global.lists.push({ language, filename, url, generator, options });
}

export function registerCustomList(language: string, filename: string, generator: any, options?) {
    ensureGlobalLists();
    ensureGlobalCustomLists();
    global.listsCustom.push({ language, filename, generator, options });
}

export async function run() {
    ensureGlobalLists();
    ensureGlobalCustomLists();
    await generateData();
    await generateIndices();

}

async function generateIndices() {
    const dataFolder = path.join(__dirname, "../../data/");
    for (const language of fs.readdirSync(dataFolder)) {
        const languageFolder = path.join(dataFolder, language);
        const files = fs.readdirSync(languageFolder).filter((f) => f.endsWith(".json"));
        fs.writeFileSync(path.join(languageFolder, "index.js"),
`${files.map((f) => `import ${f.replace(".json", "")} from "./${f}"`).join("\n")}

export default {
    ${files.map((f) => f.replace(".json", "")).join(",\n    ")}
}`);
    }
}

async function generateData() {
    for (const g of global.lists) {
        const generator = new (g.generator)(g.url, g.options);
        console.info(`----------- Starting ${g.language} ${g.filename} -----------`)
        const folder = path.join(__dirname, "../../data/", g.language);
        if (!fs.existsSync(folder)) {
            fs.mkdirSync(folder, { recursive: true });
        }
        fs.writeFileSync(path.join(folder, `${g.filename}.json`), JSON.stringify(await generator.run()));
        console.info(`----------- Finished ${g.language} ${g.filename} -----------`)
    }
    for (const g of global.listsCustom) {
        const generator = new (g.generator)(g.options);
        const folder = path.join(__dirname, "../../data/", g.language);
        if (!fs.existsSync(folder)) {
            fs.mkdirSync(folder, { recursive: true });
        }
        await generator.run(path.join(folder, `${g.filename}`))
    }
}

function ensureGlobalLists() {
    if (!Array.isArray(global.lists)) {
        global.lists = [];
    }
}

function ensureGlobalCustomLists() {
    if (!Array.isArray(global.listsCustom)) {
        global.listsCustom = [];
    }
}
