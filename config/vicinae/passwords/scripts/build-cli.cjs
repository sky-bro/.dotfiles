const path = require("node:path");
require("esbuild").buildSync({
  entryPoints: [path.join(__dirname, "../src/cli.ts")],
  outfile: path.join(__dirname, "../assets/pass-cli.cjs"),
  platform: "node", target: "node22", format: "cjs", bundle: true,
});
