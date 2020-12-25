export interface IDataGenerator {
    // constructor(url: string, options: any): void;
    run(): Promise<string[]>;
}