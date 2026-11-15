// Render pushed pages as independent React roots, matching Vicinae navigation.
// All credential services are fakes; no real vault, key or clipboard is used.
const assert = require("node:assert/strict");
const { test } = require("node:test");
const path = require("node:path");
const Module = require("node:module");
const React = require("react");
const { create, act } = require("react-test-renderer");
const { buildSync } = require("esbuild");

globalThis.IS_REACT_ACT_ENVIRONMENT = true;
let pushed;
let pops = 0;
const toasts = [];
const navigation = { push: (view) => { pushed = view; }, pop: () => { pops++; } };
globalThis.vicinae = {
  environ: { assetsPath: "/synthetic-assets", supportPath: "/synthetic-support", appearance: "light" },
  navigationContext: React.createContext(navigation),
  client: { UI: { showToast: async (id, title, message, style) => { toasts.push({ id, title, message, style }); }, popToRoot: async () => {}, hideToast: async () => {}, closeMainWindow: async () => {} } },
};
const rootDir = path.resolve(__dirname, "..");
const compiled = buildSync({
  stdin: { contents: 'export { AccessibilityRequiredError } from "./src/domain/errors.ts"; export { RuntimeContext } from "./src/ui/runtime.tsx"; export { PasswordApp } from "./src/ui/password-app.tsx";', resolveDir: rootDir, loader: "tsx" },
  platform: "node", target: "node22", format: "cjs", bundle: true, packages: "external", write: false,
}).outputFiles[0].text;
const fixtureModule = new Module(path.join(__dirname, "navigation-fixture.cjs"), module);
fixtureModule.paths = Module._nodeModulePaths(rootDir);
fixtureModule._compile(compiled, path.join(__dirname, "navigation-fixture.cjs"));
const { AccessibilityRequiredError, RuntimeContext, PasswordApp } = fixtureModule.exports;

const syntheticOtp = "otpauth://totp/Fixture:alice?secret=GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ&issuer=Fixture";
function services(record) {
  const saves = []; const typed = [];
  const entry = { name: "synthetic/example", version: "synthetic-version" };
  const runtime = {
    store: {
      list: async () => [entry],
      read: async () => record || ({ ...entry, password: "synthetic-password", details: "username: fixture\nurl: https://example.invalid", content: "synthetic-password\nusername: fixture\nurl: https://example.invalid" }),
      save: async (...args) => { saves.push(args); },
      generate: async () => {}, transfer: async () => {}, remove: async () => {}, restore: async () => {},
      history: async () => "synthetic Git history",
    },
    typer: { prepare: async () => ({ send: async (steps) => { typed.push(steps); } }) },
    qr: { read: async () => [{ secret: "GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ", issuer: "Fixture", account: "alice", algorithm: "SHA1", digits: "6", period: "30" }] },
    clipboard: { copy: async () => {} }, recent: { get: async () => undefined, record: async () => {} },
    settings: { defaultLength: "24", includeSymbols: true, defaultAction: "copy" },
    openTerminal: async () => {},
  };
  return { runtime, saves, typed };
}
async function openPage(title, record) {
  const fixture = services(record);
  let parent;
  await act(async () => { parent = create(React.createElement(RuntimeContext.Provider, { value: fixture.runtime }, React.createElement(PasswordApp))); });
  const action = parent.root.findAll((node) => node.type === "action" && node.props.title === title)[0];
  assert.ok(action, `Missing action: ${title}`);
  pushed = undefined;
  await act(async () => { action.props.onAction(); });
  assert.ok(pushed, `No page pushed: ${title}`);
  let page;
  // No provider from the parent root is inherited here. The navigation adapter
  // itself must carry the runtime into this new root, or useRuntime will throw.
  await act(async () => { page = create(pushed); });
  return { ...fixture, page, cleanup: async () => { await act(async () => { page.unmount(); parent.unmount(); }); } };
}
const findField = (page, id) => page.root.find((node) => typeof node.type === "string" && node.props.id === id);

test("New Password opens in an independent navigation root with protected fields", async () => {
  const { page, cleanup } = await openPage("New Password");
  try {
    assert.equal(page.root.findByType("form").props.enableDrafts, false);
    for (const id of ["name", "password", "confirmation", "username", "url", "details"]) assert.equal(findField(page, id).props.storeValue, false);
    assert.equal(findField(page, "password").type, "password-field");
    assert.equal(findField(page, "confirmation").type, "password-field");
  } finally { await cleanup(); }
});

test("New Password can accept and save synthetic form values after navigation", async () => {
  const { page, saves, cleanup } = await openPage("New Password");
  try {
    for (const [id, value] of Object.entries({ name: "synthetic/new", password: "synthetic-new-password", confirmation: "synthetic-new-password", username: "fixture" })) {
      await act(async () => { findField(page, id).props.onChange(value, 1); });
    }
    const before = pops;
    await act(async () => { await page.root.findAll((node) => node.type === "action" && node.props.title === "Save Entry")[0].props.onSubmit({}); });
    assert.equal(saves.length, 1);
    assert.equal(saves[0][0], "synthetic/new");
    assert.equal(saves[0][1], "synthetic-new-password\nusername: fixture");
    assert.equal(pops, before + 1);
  } finally { await cleanup(); }
});

for (const [action, expectedType] of [
  ["Generate New Password", "form"],
  ["View / Edit Entry", "form"],
  ["Rename / Move Entry", "form"],
  ["Duplicate Entry", "form"],
  ["Search Entry Contents", "form"],
  ["Browse Fields", "list"],
  ["Entry Git History", "detail"],
  ["Store Git History", "detail"],
]) test(`${action} receives runtime in its independent page root`, async () => {
  const { page, cleanup } = await openPage(action);
  try { assert.ok(page.root.findByType(expectedType)); }
  finally { await cleanup(); }
});

const changeField = async (page, id, value) => act(async () => { findField(page, id).props.onChange(value, 1); });
const save = async (page) => act(async () => { await page.root.findAll((node) => node.type === "action" && node.props.title === "Save Entry")[0].props.onSubmit({}); });

test("standalone TOTP can be created from a link without password fields", async () => {
  const { page, saves, cleanup } = await openPage("New Authenticator (TOTP)");
  try {
    assert.equal(page.root.findAll((node) => node.type === "password-field" && node.props.id === "password").length, 0);
    await changeField(page, "name", "otp/fixture/alice");
    await changeField(page, "totp-secret", syntheticOtp);
    assert.equal(findField(page, "totp-issuer").props.value.value, "Fixture");
    assert.equal(findField(page, "totp-secret").type, "password-field");
    await save(page);
    assert.equal(saves.length, 1); assert.match(saves[0][1], /^otpauth:\/\/totp\/Fixture:alice\?/);
  } finally { await cleanup(); }
});
test("new password can include a QR-imported authenticator", async () => {
  const { page, saves, cleanup } = await openPage("New Password");
  try {
    for (const [id,value] of Object.entries({ name: "synthetic/with-otp", password: "synthetic", confirmation: "synthetic", details: "keep notes" })) await changeField(page,id,value);
    await act(async () => { await page.root.findAll((node) => node.type === "action" && node.props.title === "Import TOTP QR from Clipboard")[0].props.onAction(); });
    assert.equal(findField(page,"totp-account").props.value.value,"alice");
    await save(page); assert.equal(saves.length,1);
    assert.match(saves[0][1], /^synthetic\nkeep notes\notpauth:\/\/totp\//);
  } finally { await cleanup(); }
});
test("attached TOTP is shown separately and a no-op edit preserves its exact URI", async () => {
  const record = { name: "synthetic/example", version: "synthetic-version", password: "synthetic-password", details: `username: fixture\notp: ${syntheticOtp}&custom=preserve\nunknown: keep` };
  const { page, saves, cleanup } = await openPage("View / Edit Entry", record);
  try {
    assert.equal(findField(page,"details").props.value.value,"username: fixture\nunknown: keep");
    assert.equal(findField(page,"totp-account").props.value.value,"alice");
    await save(page); assert.equal(saves.length,0);
    await changeField(page,"details","username: changed\nunknown: keep");
    await save(page); assert.equal(saves.length,1);
    assert.equal(saves[0][1], `synthetic-password\nusername: changed\notp: ${syntheticOtp}&custom=preserve\nunknown: keep`);
  } finally { await cleanup(); }
});
test("existing standalone TOTP opens the authenticator form", async () => {
  const { page, saves, cleanup } = await openPage("View / Edit Entry", { password: syntheticOtp, details: "keep notes" });
  try {
    assert.equal(findField(page,"totp-account").props.value.value,"alice");
    await changeField(page,"details","changed notes"); await save(page);
    assert.equal(saves[0][1], syntheticOtp + "\nchanged notes");
  } finally { await cleanup(); }
});
test("QR image picker uses the decoder and multiple accounts require explicit choice", async () => {
  const { page, runtime, saves, cleanup } = await openPage("New Authenticator (TOTP)");
  try {
    runtime.qr.read = async (source) => {
      assert.deepEqual(source,{ source:"file", path:"/synthetic/qr.png" });
      return ["alice","bob"].map(account => ({ secret:"GEZDGNBVGY3TQOJQGEZDGNBVGY3TQOJQ",issuer:"Fixture",account,algorithm:"SHA1",digits:"6",period:"30" }));
    };
    await changeField(page,"name","otp/fixture/bob");
    await changeField(page,"totp-qr",["/synthetic/qr.png"]);
    await save(page); assert.equal(saves.length,0);
    await changeField(page,"totp-candidate","2"); await save(page);
    assert.equal(saves.length,1); assert.match(saves[0][1],/Fixture:bob/);
  } finally { await cleanup(); }
});
test("unsupported or multiple existing authenticators remain in raw notes", async () => {
  const details = `otp: ${syntheticOtp}\nother: ${syntheticOtp}`;
  const { page, saves, cleanup } = await openPage("Set Up / Edit TOTP", { password:"synthetic-password", details });
  try {
    assert.equal(findField(page,"details").props.value.value,details);
    assert.equal(page.root.findAll(node => node.type === "password-field" && node.props.id === "totp-secret").length,0);
    await save(page); assert.equal(saves.length,0);
  } finally { await cleanup(); }
});
test("invalid TOTP key prevents saving without echoing the key in status", async () => {
  const { page, saves, cleanup } = await openPage("New Authenticator (TOTP)");
  try {
    await changeField(page,"name","otp/invalid"); await changeField(page,"totp-secret","sensitive-invalid-seed");
    await save(page); assert.equal(saves.length,0);
    const descriptions = page.root.findAll(node => node.type === "form-description");
    assert.ok(descriptions.every(node => !String(node.props.text).includes("sensitive-invalid-seed")));
  } finally { await cleanup(); }
});

async function inputRoot(defaultAction = "copy") {
  const fixture = services(); fixture.runtime.settings.defaultAction = defaultAction;
  let root;
  await act(async () => { root = create(React.createElement(RuntimeContext.Provider, { value: fixture.runtime }, React.createElement(PasswordApp))); });
  return { ...fixture, root, cleanup: async () => { await act(async () => { root.unmount(); }); } };
}
for (const [title, expected] of [
  ["Type Password / OTP", [{ text: "synthetic-password" }]],
  ["Type Username", [{ text: "fixture" }]],
  ["Type Username → Tab → Password", [{ text: "fixture" }, { key: "tab" }, { text: "synthetic-password" }]],
]) test(`${title} delivers the expected input sequence from the list`, async () => {
  const { root, typed, cleanup } = await inputRoot();
  try {
    await act(async () => { await root.root.findAll(node => node.type === "action" && node.props.title === title)[0].props.onAction(); });
    assert.deepEqual(typed, [expected]);
  } finally { await cleanup(); }
});
for (const [setting, title] of [["copy","Copy Password / OTP"],["type","Type Password / OTP"],["login","Type Username → Tab → Password"],["fields","Browse Fields"]]) test(`Enter preference ${setting} makes ${title} the first entry action`, async () => {
  const { root, cleanup } = await inputRoot(setting);
  try {
    const item = root.root.findAll(node => node.type === "list-item")[0];
    assert.equal(item.findAll(node => node.type === "action")[0].props.title,title);
  } finally { await cleanup(); }
});
test("field browser can type a selected field after independent-root navigation", async () => {
  const { page, typed, cleanup } = await openPage("Browse Fields");
  try {
    await act(async () => { await page.root.findAll(node => node.type === "action" && node.props.title === "Type Field")[0].props.onAction(); });
    assert.deepEqual(typed, [[{ text: "synthetic-password" }]]);
  } finally { await cleanup(); }
});
test("delivery failures are still reported after the launcher view closes", async () => {
  const { root, runtime, cleanup } = await inputRoot();
  let rejectDelivery;
  runtime.typer.prepare = async () => ({ send: () => new Promise((resolve,reject) => { rejectDelivery = reject; }) });
  const action = root.root.findAll(node => node.type === "action" && node.props.title === "Type Password / OTP")[0];
  let task;
  await act(async () => { task = action.props.onAction(); });
  await cleanup();
  const before = toasts.length;
  await act(async () => { rejectDelivery(new Error("synthetic-private-error")); await task; });
  assert.equal(toasts.length,before+1);
  assert.ok(!JSON.stringify(toasts.at(-1)).includes("synthetic-private-error"));
});

test("missing Accessibility shows a specific enable-Vicinae toast without decrypting", async () => {
  const { root, runtime, typed, cleanup } = await inputRoot(); let reads = 0;
  runtime.store.read = async () => { reads++; throw Error("Should not decrypt"); };
  runtime.typer.prepare = async () => { throw new AccessibilityRequiredError("Enable Vicinae in Accessibility settings."); };
  try {
    await act(async () => { await root.root.findAll(node => node.type === "action" && node.props.title === "Type Password / OTP")[0].props.onAction(); });
    assert.equal(reads,0); assert.equal(typed.length,0);
    assert.equal(toasts.at(-1).title,"Enable Vicinae Accessibility");
    assert.match(toasts.at(-1).message,/Vicinae/);
  } finally { await cleanup(); }
});

test("editing a password with only a TOTP detail and trailing newline is a no-op", async () => {
  const { page, saves, cleanup } = await openPage("View / Edit Entry", { password: "synthetic-password", details: syntheticOtp + "\n" });
  try { await save(page); assert.equal(saves.length, 0); }
  finally { await cleanup(); }
});
