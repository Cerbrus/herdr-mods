import { mkdir, writeFile } from "node:fs/promises";
import { join, resolve } from "node:path";
import { pathToFileURL } from "node:url";

const [mod = "mods/agent-cards", out = "styles-preview"] = process.argv.slice(2);
const { STYLES, avatarUrl, tuckIn } = await import(pathToFileURL(resolve(mod, "avatars.js")).href);

const TITLES = { "voxel-bot": "Voxel Bot", "voxel-art": "Voxel Art", personas: "Personas", "pixel-art": "Pixel Art", "toon-head": "Toon Head", avataaars: "Avataaars" };
const SEEDS = ["acme-api", "acme-web", "acme-docs", "acme-app"];

await mkdir(out, { recursive: true });
const rows = [];
for (const name of Object.keys(STYLES)) {
  const cells = [];
  for (const seed of SEEDS) {
    const response = await fetch(`${avatarUrl(name)}${seed}`);
    if (!response.ok) throw new Error(`${name} ${seed}: ${response.status}`);
    const text = await response.text();
    await writeFile(join(out, `${name}-${seed}.svg`), text);
    await writeFile(join(out, `${name}-${seed}-asleep.svg`), tuckIn(text, name));
    cells.push(`<img src="${name}-${seed}.svg"><img class="asleep" src="${name}-${seed}-asleep.svg">`);
  }
  rows.push(`<section><h2>${TITLES[name] ?? name} <code>${name}</code></h2><div>${cells.join("")}</div></section>`);
}

await writeFile(join(out, "index.html"), `<!doctype html><meta charset="utf-8"><title>Avatar styles</title><style>
body { background: #121216; color: #d0d0d6; font: 14px "Segoe UI", sans-serif; margin: 0; padding: 20px 24px; width: 852px; }
h2 { font-size: 15px; font-weight: 600; margin: 14px 0 8px; }
code { color: #85858f; font-size: 12px; margin-left: 6px; }
div { display: flex; gap: 8px; }
img { width: 96px; height: 96px; background: #1b1b21; border-radius: 8px; }
.asleep { margin-right: 12px; }
</style>${rows.join("")}`);
console.log(join(resolve(out), "index.html"));
