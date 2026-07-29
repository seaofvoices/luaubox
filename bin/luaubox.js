#!/usr/bin/env node
import { spawn } from "node:child_process";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

const scriptPath = resolve(__dirname, "../dist/luaubox.luau");

const child = spawn("lune", ["run", scriptPath, ...process.argv.slice(2)], {
  stdio: "inherit",
  shell: false,
});

child.on("exit", (code) => process.exit(code ?? 1));
