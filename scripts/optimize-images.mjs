#!/usr/bin/env node
// Regenerates web-optimized image assets from the source PNGs.
// Run: node scripts/optimize-images.mjs
import { readFile, writeFile, stat } from "node:fs/promises";
import path from "node:path";
import { fileURLToPath } from "node:url";
import sharp from "sharp";

const root = path.resolve(path.dirname(fileURLToPath(import.meta.url)), "..");

// width = target intrinsic px (≈ 2x the largest displayed CSS size for crispness on HiDPI)
const jobs = [
  // Square app icon: shown at 20–88px CSS → 192px covers HiDPI. 512 PNG kept for og:image/social + fallback.
  { src: "icon.png", out: "icon.webp", width: 192, height: 192, fit: "cover" },
  { src: "icon.png", out: "icon.png", width: 512, height: 512, fit: "cover" },
  // Hero wordmark: rendered up to 420px wide → 840px for HiDPI.
  { src: "logo.png", out: "logo.webp", width: 840 },
  { src: "logo.png", out: "logo.png", width: 840 },
  // Favicon + apple-touch are far larger than needed.
  { src: "favicon.png", out: "favicon.png", width: 64, height: 64, fit: "cover" },
  { src: "apple-touch-icon.png", out: "apple-touch-icon.png", width: 180, height: 180, fit: "cover" },
];

const fmt = (b) => `${(b / 1024).toFixed(1)} KiB`;

for (const job of jobs) {
  const srcPath = path.join(root, job.src);
  const outPath = path.join(root, job.out);
  const before = (await stat(srcPath)).size;
  // Read source into a buffer so we can safely write back to the same path.
  const input = await readFile(srcPath);

  let pipeline = sharp(input).resize({
    width: job.width,
    height: job.height,
    fit: job.fit ?? "inside",
    withoutEnlargement: true,
  });

  if (job.out.endsWith(".webp")) {
    pipeline = pipeline.webp({ quality: 82, effort: 6 });
  } else {
    pipeline = pipeline.png({ compressionLevel: 9, palette: true, quality: 90 });
  }

  const buf = await pipeline.toBuffer();
  await writeFile(outPath, buf);
  console.log(`${job.src} → ${job.out}  ${fmt(before)} → ${fmt(buf.length)}`);
}
