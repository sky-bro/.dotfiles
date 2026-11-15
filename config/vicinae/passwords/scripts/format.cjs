// Use the project's TypeScript formatter, matching VS Code's built-in formatter.
const fs = require("node:fs");
const path = require("node:path");
const ts = require("typescript");
const root = path.resolve(__dirname, "..");
function collect(dir) {
  return fs.readdirSync(dir, { withFileTypes: true }).flatMap((item) => item.isDirectory()
    ? collect(path.join(dir, item.name)) : /\.tsx?$/.test(item.name) ? [path.join(dir, item.name)] : []);
}
const files = ["src", "tests"].flatMap((dir) => collect(path.join(root, dir)));
const service = ts.createLanguageService({
  getCompilationSettings: () => ({}),
  getScriptFileNames: () => files,
  getScriptVersion: () => "0",
  getScriptSnapshot: (file) => fs.existsSync(file) ? ts.ScriptSnapshot.fromString(fs.readFileSync(file, "utf8")) : undefined,
  getCurrentDirectory: () => root,
  getDefaultLibFileName: ts.getDefaultLibFilePath,
  fileExists: ts.sys.fileExists,
  readFile: ts.sys.readFile,
});
const options = { indentSize: 2, tabSize: 2, convertTabsToSpaces: true, newLineCharacter: "\n",
  insertSpaceAfterCommaDelimiter: true, insertSpaceAfterKeywordsInControlFlowStatements: true,
  insertSpaceBeforeAndAfterBinaryOperators: true, insertSpaceAfterSemicolonInForStatements: true };
let changed = false;
for (const file of files) {
  let text = fs.readFileSync(file, "utf8");
  const edits = service.getFormattingEditsForDocument(file, options).sort((a, b) => b.span.start - a.span.start);
  for (const edit of edits) text = text.slice(0, edit.span.start) + edit.newText + text.slice(edit.span.start + edit.span.length);
  text = text.split("\n").map((line) => line.trimEnd()).join("\n");
  if (text !== fs.readFileSync(file, "utf8")) {
    changed = true;
    if (process.argv.includes("--check")) console.error(`Needs formatting: ${path.relative(root, file)}`);
    else fs.writeFileSync(file, text);
  }
}
service.dispose();
if (changed && process.argv.includes("--check")) process.exitCode = 1;
