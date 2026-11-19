const CLEAR = "backgroundColor=00000000";

export const STYLES = {
  "voxel-bot": {
    options: `flip=horizontal&${CLEAR}&bodyColor=e9ecef,aeb8c2,b6a6f5,74c0fc&screenColor=07070a&glowColor=3bc9db,69db7c,ffd43b,e599f7`,
    body: ["#e9ecef", "#aeb8c2", "#b6a6f5", "#74c0fc"],
    accent: "eyes",
    fit: { scale: 0.92, top: 5 },
  },
  "voxel-art": { options: CLEAR, body: "outfit", fit: { scale: 0.78, top: 16 } },
  personas: { options: CLEAR, body: "clothes", fit: { scale: 0.72, top: 17 } },
  "pixel-art": { options: CLEAR, body: "clothes", fit: { scale: 0.66, top: 19 } },
  "toon-head": { options: CLEAR, body: "clothes", fit: { scale: 0.72, top: 16 } },
  avataaars: { options: CLEAR, body: "clothes", fit: { scale: 0.7, top: 17 } },
};

export const DEFAULT_STYLE = "voxel-bot";
export const Z_COLOR = "#69db7c";

const BED = '<path d="M2 14h10v100H2Z" fill="#5f3820"/><path d="M10 18h116v92H10Z" fill="#7a4a2d"/><path d="M14 22h109v84H14Z" fill="#d8c9a3"/><path d="M17 25h28v78H17Z" fill="#f5efe0"/><path d="M17 97h28v6H17Z" fill="#000000" fill-opacity=".12"/>';
const PLAIN = new Set(["#000000", "#ffffff"]);

const channels = (hex) => [1, 3, 5].map((i) => parseInt(hex.slice(i, i + 2), 16));
const toHex = (values) => `#${values.map((v) => Math.round(v).toString(16).padStart(2, "0")).join("")}`;
const shade = (hex, by) => toHex(channels(hex).map((v) => v * (1 - by)));
const tint = (hex, by) => toHex(channels(hex).map((v) => v + (255 - v) * by));
const blend = (a, b) => toHex(channels(a).map((v, i) => (v + channels(b)[i]) / 2));

function colorOf(text, part) {
  const from = part ? text.indexOf(`id="${part}-`) : -1;
  if (from < 0) return null;
  const until = text.indexOf("</g>", from);
  for (const [, color] of text.slice(from, until < 0 ? undefined : until).matchAll(/fill="(#[0-9a-f]{6})"/gi)) {
    if (!PLAIN.has(color.toLowerCase())) return color.toLowerCase();
  }
  return null;
}

const styleOf = (name) => STYLES[name] ?? STYLES[DEFAULT_STYLE];
const SHEET = "#8a93a0";
const listed = (text, colors) => colors.find((color) => text.toLowerCase().includes(`fill="${color}"`)) ?? colors[0];
const bodyColor = (text, style) => (Array.isArray(style.body) ? listed(text, style.body) : colorOf(text, style.body)) ?? SHEET;

export const styleName = (name) => (STYLES[name] ? name : DEFAULT_STYLE);
export const avatarUrl = (name, options) => `https://api.dicebear.com/10.x/${styleName(name)}/svg?${styleOf(name).options}${options ? `&${options}` : ""}&seed=`;
export const accentColor = (text, name) => colorOf(text, styleOf(name).accent) ?? tint(bodyColor(text, styleOf(name)), 0.35);

const sheet = (body, accent) => `<path d="M84 22h39v84H84Z" fill="${shade(body, 0.3)}"/><path d="M84 98h39v8H84Z" fill="#000000" fill-opacity=".22"/><path d="M97 22v84M110 22v84" stroke="#000000" stroke-opacity=".14" stroke-width="1.5"/><path d="M77 22h9v84h-9Z" fill="${blend(accent, shade(body, 0.3))}"/><path d="M77 98h9v8h-9Z" fill="#000000" fill-opacity=".14"/>`;

export function tuckIn(text, name) {
  const style = styleOf(name);
  const open = text.indexOf(">") + 1, close = text.lastIndexOf("</svg>");
  const head = text.slice(0, open);
  const width = Number(head.match(/viewBox="[\d.]+ [\d.]+ ([\d.]+)/)?.[1]) || 128;
  const crisp = head.match(/shape-rendering="([^"]+)"/)?.[1] ?? "auto";
  const { scale, top } = style.fit;
  const left = (128 - 128 * scale) / 2;
  const place = `rotate(270, 64, 64) translate(${left}, ${top}) scale(${(128 / width) * scale})`;
  return `<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 128 128" fill="none">${BED}<g transform="${place}" shape-rendering="${crisp}">${text.slice(open, close)}</g>${sheet(bodyColor(text, style), accentColor(text, name))}</svg>`;
}
