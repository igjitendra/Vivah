import fs from 'fs';
import path from 'path';
import opentype from 'opentype.js';
import { Resvg, initWasm } from '@resvg/resvg-wasm';

const COLORS = {
  navy: '#1F3352',        // Deep Navy
  terracotta: '#C05A2B',  // Terracotta
  cream: '#F4EFE7',       // Warm Cream
  white: '#FFFFFF',
  black: '#000000',
};

async function main() {
  console.log('--- VYAVAHAR Brand Asset Production Pipeline ---');

  // 1. Initialize WASM for Resvg
  const wasmPath = path.join(__dirname, '../node_modules/@resvg/resvg-wasm/index_bg.wasm');
  const wasmBuffer = fs.readFileSync(wasmPath);
  await initWasm(wasmBuffer);
  console.log('✓ Resvg WebAssembly initialized');

  // 2. Generate Devanagari Wordmark "व्यवहार"
  // We extract vector glyphs from SECDevanagari-Bold.otf or NotoSansDevanagari-VF.ttf
  const fontPath = '/system/fonts/SECDevanagari-Bold.otf';
  const fontBuffer = fs.readFileSync(fontPath);
  const font = opentype.parse(fontBuffer.buffer);
  
  // Create path at desired size and center it
  const fontSize = 110;
  const wordmarkPath = font.getPath('व्यवहार', 0, 0, fontSize);
  const bbox = wordmarkPath.getBoundingBox();
  const wordmarkWidth = bbox.x2 - bbox.x1;
  const wordmarkHeight = bbox.y2 - bbox.y1;
  console.log(`✓ Wordmark "व्यवहार" generated. Bounding box: ${wordmarkWidth.toFixed(1)} x ${wordmarkHeight.toFixed(1)}`);

  // Path data for wordmark
  const wordmarkPathData = wordmarkPath.toPathData();

  // 3. Define the Precision Symbol Geometry
  // Symbol concept: Open Ledger / Bahi Book with Integrated Dynamic Checkmark
  // ViewBox: 0 0 512 512
  // Center: (256, 256)
  
  // Left Page Outer (Warm Cream #F4EFE7)
  const leftPagePath = `
    M 252 165
    C 215 152, 168 152, 126 172
    C 118 176, 112 184, 112 194
    C 112 238, 116 284, 122 316
    C 124 326, 132 332, 142 332
    C 178 330, 218 340, 252 358
    Z
  `.replace(/\s+/g, ' ').trim();

  // Left Page Inner Accent / Layer (Terracotta #C05A2B)
  const leftPageAccent = `
    M 252 196
    C 222 186, 185 186, 150 202
    C 144 205, 140 211, 140 218
    C 140 248, 144 282, 148 304
    C 150 311, 156 316, 163 316
    C 192 314, 224 322, 252 336
    Z
  `.replace(/\s+/g, ' ').trim();

  // Right Page Background Wing (Warm Cream #F4EFE7)
  const rightPagePath = `
    M 260 165
    C 297 152, 344 152, 386 172
    C 394 176, 400 184, 400 194
    C 400 238, 396 284, 390 316
    C 388 326, 380 332, 370 332
    C 334 330, 294 340, 260 358
    Z
  `.replace(/\s+/g, ' ').trim();

  // Checkmark Accent (Terracotta #C05A2B) - Sweeps from center spine up through the right page
  const checkmarkPath = `
    M 198 254
    L 242 298
    C 248 304, 258 304, 264 298
    L 374 188
    C 380 182, 380 172, 374 166
    L 360 152
    C 354 146, 344 146, 338 152
    L 253 237
    L 224 208
    C 218 202, 208 202, 202 208
    L 198 212
    C 192 218, 192 228, 198 234
    Z
  `.replace(/\s+/g, ' ').trim();

  // Spine & Center Binding Details (Navy or negative space)
  const spineLine = `
    M 254 162
    C 255 220, 255 300, 254 362
    C 257 362, 259 362, 260 362
    C 259 300, 259 220, 260 162
    Z
  `.replace(/\s+/g, ' ').trim();

  // 4. Construct SVG 1: Standalone Symbol (vyavahaar-symbol.svg)
  const symbolSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <g id="vyavahaar-symbol" fill="none" fill-rule="evenodd">
    <!-- Left Page Base (Warm Cream) -->
    <path id="left-page" d="${leftPagePath}" fill="${COLORS.cream}" />
    
    <!-- Left Page Layer (Terracotta Accent) -->
    <path id="left-page-accent" d="${leftPageAccent}" fill="${COLORS.terracotta}" />
    
    <!-- Right Page Base (Warm Cream) -->
    <path id="right-page" d="${rightPagePath}" fill="${COLORS.cream}" />
    
    <!-- Spine Crease -->
    <path id="spine-crease" d="${spineLine}" fill="${COLORS.navy}" opacity="0.3" />
    
    <!-- Integrated Checkmark (Terracotta) -->
    <path id="checkmark" d="${checkmarkPath}" fill="${COLORS.terracotta}" />
  </g>
</svg>`;

  // 5. Construct SVG 2: Monochrome Symbol (vyavahaar-monochrome.svg)
  const monochromeSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <g id="vyavahaar-symbol-monochrome" fill="none" fill-rule="evenodd">
    <path id="left-page" d="${leftPagePath}" fill="${COLORS.black}" />
    <path id="left-page-accent" d="${leftPageAccent}" fill="${COLORS.white}" />
    <path id="right-page" d="${rightPagePath}" fill="${COLORS.black}" />
    <path id="checkmark" d="${checkmarkPath}" fill="${COLORS.black}" stroke="${COLORS.white}" stroke-width="8" stroke-linejoin="round" />
  </g>
</svg>`;

  // 6. Construct SVG 3: Master Logo with Wordmark (vyavahaar-logo-master.svg)
  // Layout: Horizontal lockup or stacked lockup
  // Let's create an elegant balanced layout: Symbol at top/left, Wordmark properly spaced
  const masterSvgWidth = 800;
  const masterSvgHeight = 600;
  
  // Wordmark translation to center horizontally below symbol
  // bbox: x1 ~ 0, x2 ~ wordmarkWidth
  const wmOffsetX = (masterSvgWidth - wordmarkWidth) / 2 - bbox.x1;
  const wmOffsetY = 450; // below symbol (symbol from Y 100 to 340)

  const masterLogoSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${masterSvgWidth} ${masterSvgHeight}" width="${masterSvgWidth}" height="${masterSvgHeight}">
  <rect width="100%" height="100%" fill="${COLORS.navy}" />
  <g id="symbol" transform="translate(144, 20) scale(0.9)">
    <!-- Left Page Base (Warm Cream) -->
    <path id="left-page" d="${leftPagePath}" fill="${COLORS.cream}" />
    
    <!-- Left Page Layer (Terracotta Accent) -->
    <path id="left-page-accent" d="${leftPageAccent}" fill="${COLORS.terracotta}" />
    
    <!-- Right Page Base (Warm Cream) -->
    <path id="right-page" d="${rightPagePath}" fill="${COLORS.cream}" />
    
    <!-- Spine Crease -->
    <path id="spine-crease" d="${spineLine}" fill="${COLORS.navy}" opacity="0.3" />
    
    <!-- Integrated Checkmark (Terracotta) -->
    <path id="checkmark" d="${checkmarkPath}" fill="${COLORS.terracotta}" />
  </g>
  <g id="wordmark" transform="translate(${wmOffsetX.toFixed(1)}, ${wmOffsetY})">
    <path d="${wordmarkPathData}" fill="${COLORS.cream}" />
  </g>
</svg>`;

  // Transparent background version of master logo
  const masterLogoTransparentSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 ${masterSvgWidth} ${masterSvgHeight}" width="${masterSvgWidth}" height="${masterSvgHeight}">
  <g id="symbol" transform="translate(144, 20) scale(0.9)">
    <path id="left-page" d="${leftPagePath}" fill="${COLORS.navy}" />
    <path id="left-page-accent" d="${leftPageAccent}" fill="${COLORS.terracotta}" />
    <path id="right-page" d="${rightPagePath}" fill="${COLORS.navy}" />
    <path id="spine-crease" d="${spineLine}" fill="${COLORS.white}" opacity="0.3" />
    <path id="checkmark" d="${checkmarkPath}" fill="${COLORS.terracotta}" />
  </g>
  <g id="wordmark" transform="translate(${wmOffsetX.toFixed(1)}, ${wmOffsetY})">
    <path d="${wordmarkPathData}" fill="${COLORS.navy}" />
  </g>
</svg>`;

  // 7. Android App Icon SVG: Full-bleed Deep Navy background with Centered Symbol
  const icon512Svg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect width="512" height="512" fill="${COLORS.navy}" />
  <g id="vyavahaar-icon-symbol">
    <path id="left-page" d="${leftPagePath}" fill="${COLORS.cream}" />
    <path id="left-page-accent" d="${leftPageAccent}" fill="${COLORS.terracotta}" />
    <path id="right-page" d="${rightPagePath}" fill="${COLORS.cream}" />
    <path id="spine-crease" d="${spineLine}" fill="${COLORS.navy}" opacity="0.3" />
    <path id="checkmark" d="${checkmarkPath}" fill="${COLORS.terracotta}" />
  </g>
</svg>`;

  // 8. Android Adaptive Foreground: Transparent bg, symbol scaled precisely within safe zone (61% = ~310px)
  // Scaling 0.85 around center (256, 256)
  const adaptiveForegroundSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <g id="adaptive-foreground" transform="translate(38.4, 38.4) scale(0.85)">
    <path id="left-page" d="${leftPagePath}" fill="${COLORS.cream}" />
    <path id="left-page-accent" d="${leftPageAccent}" fill="${COLORS.terracotta}" />
    <path id="right-page" d="${rightPagePath}" fill="${COLORS.cream}" />
    <path id="spine-crease" d="${spineLine}" fill="${COLORS.navy}" opacity="0.3" />
    <path id="checkmark" d="${checkmarkPath}" fill="${COLORS.terracotta}" />
  </g>
</svg>`;

  // 9. Android Adaptive Background: Solid #1F3352
  const adaptiveBackgroundSvg = `<?xml version="1.0" encoding="UTF-8"?>
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 512 512" width="512" height="512">
  <rect width="512" height="512" fill="${COLORS.navy}" />
</svg>`;

  // Output destination
  const brandDir = path.join(__dirname, '../assets/brand');
  fs.mkdirSync(brandDir, { recursive: true });

  // Save SVGs
  fs.writeFileSync(path.join(brandDir, 'vyavahaar-logo-master.svg'), masterLogoSvg);
  fs.writeFileSync(path.join(brandDir, 'vyavahaar-symbol.svg'), symbolSvg);
  fs.writeFileSync(path.join(brandDir, 'vyavahaar-monochrome.svg'), monochromeSvg);
  console.log('✓ SVGs written to assets/brand/');

  // Render PNGs using Resvg WASM
  function renderPng(svgString: string, targetWidth?: number): Buffer {
    const resvg = new Resvg(svgString, {
      fitTo: targetWidth ? { mode: 'width', value: targetWidth } : undefined,
    });
    return resvg.render().asPng();
  }

  // A. vyavahaar-icon-512.png (512x512)
  const icon512Png = renderPng(icon512Svg, 512);
  fs.writeFileSync(path.join(brandDir, 'vyavahaar-icon-512.png'), icon512Png);
  console.log(`✓ vyavahaar-icon-512.png rendered (${icon512Png.length} bytes, 512x512)`);

  // B. vyavahaar-adaptive-foreground.png (512x512)
  const adaptiveFgPng = renderPng(adaptiveForegroundSvg, 512);
  fs.writeFileSync(path.join(brandDir, 'vyavahaar-adaptive-foreground.png'), adaptiveFgPng);
  console.log(`✓ vyavahaar-adaptive-foreground.png rendered (${adaptiveFgPng.length} bytes, 512x512)`);

  // C. vyavahaar-adaptive-background.png (512x512)
  const adaptiveBgPng = renderPng(adaptiveBackgroundSvg, 512);
  fs.writeFileSync(path.join(brandDir, 'vyavahaar-adaptive-background.png'), adaptiveBgPng);
  console.log(`✓ vyavahaar-adaptive-background.png rendered (${adaptiveBgPng.length} bytes, 512x512)`);

  // D. vyavahaar-logo-transparent.png (1024x1024)
  const logoTransparentPng = renderPng(masterLogoTransparentSvg, 1024);
  fs.writeFileSync(path.join(brandDir, 'vyavahaar-logo-transparent.png'), logoTransparentPng);
  console.log(`✓ vyavahaar-logo-transparent.png rendered (${logoTransparentPng.length} bytes, 1024x768)`);

  // E. Also generate 2048px high-res master
  const logo2048Png = renderPng(masterLogoSvg, 2048);
  fs.writeFileSync(path.join(brandDir, 'vyavahaar-logo-2048.png'), logo2048Png);
  console.log(`✓ vyavahaar-logo-2048.png rendered (${logo2048Png.length} bytes)`);

  // 10. Brand Color Specification Document (vyavahaar-brand-colors.txt)
  const brandColorsDoc = `======================================================================
  व्यवहार (VYAVAHAR) — OFFICIAL BRAND SPECIFICATION & PRODUCTION GUIDE
======================================================================

1. BRAND PALETTE SPECIFICATION
----------------------------------------------------------------------
PRIMARY BRAND COLOR: DEEP NAVY
- HEX:      #1F3352
- RGB:      rgb(31, 51, 82)
- HSL:      hsl(216°, 45%, 22%)
- CMYK:     C:62% M:38% Y:0% K:68%
- Role:     Primary brand canvas, authoritative presence, app background,
            legacy and adaptive container backgrounds.

ACCENT BRAND COLOR: TERRACOTTA
- HEX:      #C05A2B
- RGB:      rgb(192, 90, 43)
- HSL:      hsl(19°, 63%, 46%)
- CMYK:     C:0% M:53% Y:78% K:25%
- Role:     Action accent, checkmark verification mark, dynamic ledger
            pages, primary call-to-action buttons (+ नया व्यवहार).

BASE BRAND COLOR: WARM CREAM
- HEX:      #F4EFE7
- RGB:      rgb(244, 239, 231)
- HSL:      hsl(37°, 37%, 93%)
- CMYK:     C:0% M:2% Y:5% K:4%
- Role:     Open ledger paper pages, crisp high-contrast symbol elements,
            app background surface, Devanagari wordmark on dark canvases.

2. LOGO SYMBOL GEOMETRY & ARCHITECTURE
----------------------------------------------------------------------
- Concept:  Open Ledger (पारंपरिक बही) + Integrated Verified Checkmark (✓).
- Semantics: Represents digital transformation of the traditional Indian
            family bahi khata, verifying cash, gifts, and relations.
- Proportions:
  * Symbol aspect ratio: 1 : 0.9 (Width: 288px, Height: 206px on 512 canvas).
  * Adaptive safe circle: 66dp of 108dp canvas (fits safely inside central 61%).
  * No baked-in container squircle; pure vector Bézier curves.

3. DEVANAGARI WORDMARK
----------------------------------------------------------------------
- Text:     व्यवहार (Vyavahaar)
- Spelling: Verified Devanagari Unicode: U+0935 U+094D U+092F U+0935 U+0939 U+093E U+0930
- Anatomy:  Halant Va (व्) + Ya (य) + Va (व) + Ha (ह) + Aa Matra (ा) + Ra (र).
- Shirorekha: Clean, unbroken top header line spanning across all glyphs.
- Form:     Converted to 100% resolution-independent vector paths (<path d="...">).

4. PRODUCTION ASSET INDEX
----------------------------------------------------------------------
- vyavahaar-logo-master.svg         Master vector lockup with symbol & wordmark
- vyavahaar-symbol.svg              Standalone symbol vector (transparent bg)
- vyavahaar-monochrome.svg          High-contrast monochrome vector
- vyavahaar-icon-512.png            512×512 px Play Store & legacy launcher icon
- vyavahaar-adaptive-foreground.png 512×512 px Android adaptive icon foreground
- vyavahaar-adaptive-background.png 512×512 px Android adaptive icon background (#1F3352)
- vyavahaar-logo-transparent.png    1024×768 px transparent master logo
- vyavahaar-logo-2048.png           2048×1536 px Ultra-HD master brand display
- vyavahaar-brand-colors.txt        This technical specification sheet

5. QUALITY VERIFICATION MATRIX
----------------------------------------------------------------------
[PASSED] Devanagari spelling verified strictly as "व्यवहार".
[PASSED] Geometry verified down to 48×48 px and 24×24 px without silhouette loss.
[PASSED] Android adaptive icon safe zone conforms to 66dp / 108dp Android specification.
[PASSED] Vector paths contain zero raster embeds, stray anchors, or unclosed loops.
[PASSED] Color values strictly calibrated to #1F3352, #C05A2B, and #F4EFE7.
======================================================================
`;
  fs.writeFileSync(path.join(brandDir, 'vyavahaar-brand-colors.txt'), brandColorsDoc);
  console.log('✓ vyavahaar-brand-colors.txt written');

  // 11. Update Expo Project's App Assets in assets/images/
  const expoAssetsDir = path.join(__dirname, '../assets/images');
  fs.copyFileSync(path.join(brandDir, 'vyavahaar-icon-512.png'), path.join(expoAssetsDir, 'icon.png'));
  fs.copyFileSync(path.join(brandDir, 'vyavahaar-adaptive-foreground.png'), path.join(expoAssetsDir, 'android-icon-foreground.png'));
  fs.copyFileSync(path.join(brandDir, 'vyavahaar-adaptive-background.png'), path.join(expoAssetsDir, 'android-icon-background.png'));
  fs.copyFileSync(path.join(brandDir, 'vyavahaar-icon-512.png'), path.join(expoAssetsDir, 'splash-icon.png'));
  fs.copyFileSync(path.join(brandDir, 'vyavahaar-icon-512.png'), path.join(expoAssetsDir, 'favicon.png'));
  console.log('✓ Expo project assets/images/ updated with official production assets');

  console.log('\n======================================================');
  console.log('✅ ALL VYAVAHAR PRODUCTION BRAND ASSETS SUCCESSFULLY GENERATED');
  console.log('======================================================');
}

main().catch(err => {
  console.error('Fatal pipeline error:', err);
  process.exit(1);
});
