export const meta = {
  name: 'tsuri-quest-ui-quality-uplift',
  description: 'Investigate how to raise the fishing-JRPG UI to the reference mockup quality (retro pixel + JRPG UI + bright sea) in Godot 4.7 gl_compatibility, and produce a concrete per-screen build plan',
  phases: [
    { title: 'Reference', detail: 'best-effort extraction of the 3 concept mockups' },
    { title: 'Audit', detail: 'diagnose current code-driven UI per cluster' },
    { title: 'Techniques', detail: 'Godot 4.7 gl_compat techniques to hit target quality' },
    { title: 'Gap & Plan', detail: 'per-screen gap analysis + concrete build plan' },
  ],
}

// ---- Inlined inputs (args global proved unreliable in this harness) ----
const ctx = [
  'PROJECT: 釣りクエスト ～海釣り編〜 — 2D海釣りRPG. Godot 4.7, GDScript, renderer = GL COMPATIBILITY, base resolution 1280x720 16:9, macOS target. window stretch mode = canvas_items, aspect = expand.',
  '',
  'STATED ART DIRECTION (docs/00): 明るい海、レトロなピクセルアート、和製RPG風UI = BRIGHT SEA + RETRO PIXEL ART + JRPG-STYLE UI. Inspiration lineage: GBA/SNES-era fishing JRPGs (e.g. Legend of the River King / 川のぬし) — warm ornate menus, pixel sprites, cheerful bright ocean. This is the quality bar.',
  '',
  'THE reference/ FOLDER holds 3 concept mockups (企画用モックアップ, NOT imported by the game): 01 surface fishing, 02 underwater fight (the signature/看板 screen), 03 cooking/meal/level-up. Per docs/03 §6 and docs/08: the images define LAYOUT + MOOD only — final art must be ORIGINAL (do NOT copy any existing game pixel-for-pixel; make fish/backgrounds/frames/icons from scratch).',
  '',
  'CURRENT STATE (all code-driven UI; screens built in GDScript _build_screen(), only main.tscn is a trivial Control+script):',
  '- src/ui/ui_theme.gd: StyleBoxFlat Theme — parchment #f3e8cd panels, brown #6e5635 borders, wood-tone buttons (#8a5428 normal -> #a66831 hover), gold accents, system font (Hiragino Maru Gothic ProN). Has soft drop shadows + rounded corners + gradient ProgressBar fills. Type variations: DarkPanel (#12283f), BluePanel (#173b61).',
  '- src/ui/screen_base.gd: helpers — add_gradient_background (vertical GradientTexture2D), make_label/make_body_label (outline support), make_button, make_panel(dark), make_header (dark panel + title 28px gold + subtitle).',
  '- src/ui/components/gauge_bar.gd: custom _draw Control — gradient fill, rounded ends, drop shadow, track groove, top highlight line, value text with outline.',
  '- src/ui/components/underwater_view.gd (425 lines, the visual centerpiece): custom _draw — 20-strip depth-graded water, light shafts, surface waves, depth-scale panel with markers, seabed (sand polygon, rocks, seaweed, pebbles), background fish, bubbles, fishing line+bait, a fairly detailed target fish (banded-ellipse gradient body, fins, scales, highlighted eye, mouth, gills), fight overlay (fish-name badge w/ gold border, distance meter).',
  '- Screens: title, harbor, fishing(=underwater fight), cooking, market, shop, status. core/fishing_simulator.gd drives the fight state machine.',
  '',
  'GAP SIGNAL: the current art is SMOOTH VECTOR / painterly (gradients, ellipses, StyleBoxFlat) — NOT retro pixel art, and the UI is parchment/wood rather than a distinctly JRPG window-skin. So the biggest gaps are likely: (a) no pixel-art pipeline, (b) UI not using JRPG ornate 9-slice frames / bitmap fonts, (c) atmosphere & juice below mockup polish.',
  '',
  'GOAL: raise overall UI/visual quality to the reference mockups level. Find the concrete gap and HOW to close it with Godot 4.7 gl_compatibility techniques.',
].join('\n')

const refs = {
  surface: { path: '/Users/ryukouokumura/Desktop/tsuri_quest_umi_mvp/reference/01_surface_fishing_mockup.png', url: 'https://maas-log-prod.cn-wlcb.ufileos.com/anthropic/518eb8f4-dd11-446a-8666-95219560891a/01_surface_fishing_mockup.png?UCloudPublicKey=TOKEN_e15ba47a-d098-4fbd-9afc-a0dcf0e4e621&Expires=1782252830&Signature=j2G59Llt4hyeyzqDdgdqhwGIaNk=' },
  underwater: { path: '/Users/ryukouokumura/Desktop/tsuri_quest_umi_mvp/reference/02_underwater_fight_mockup.png', url: 'https://maas-log-prod.cn-wlcb.ufileos.com/anthropic/518eb8f4-dd11-446a-8666-95219560891a/02_underwater_fight_mockup.png?UCloudPublicKey=TOKEN_e15ba47a-d098-4fbd-9afc-a0dcf0e4e621&Expires=1782252845&Signature=caZh7jBJBg71U9CICVOxH/Oours=' },
  cooking: { path: '/Users/ryukouokumura/Desktop/tsuri_quest_umi_mvp/reference/03_cooking_levelup_mockup.png', url: 'https://maas-log-prod.cn-wlcb.ufileos.com/anthropic/518eb8f4-dd11-446a-8666-95219560891a/03_cooking_levelup_mockup.png?UCloudPublicKey=TOKEN_e15ba47a-d098-4fbd-9afc-a0dcf0e4e621&Expires=1782252865&Signature=uRLgl31AFwnr3n3LUuULgGdT+tg=' },
}

const REFERENCE_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    screen: { type: 'string' },
    imageReadSuccess: { type: 'string', enum: ['yes', 'partial', 'failed'] },
    confidence: { type: 'string' },
    overallArtDirection: { type: 'string' },
    composition: { type: 'string' },
    colorPalette: { type: 'array', items: { type: 'object', additionalProperties: false, properties: { role: { type: 'string' }, hex: { type: 'string' }, note: { type: 'string' } }, required: ['role', 'hex'] } },
    keyElements: { type: 'array', items: { type: 'object', additionalProperties: false, properties: { name: { type: 'string' }, description: { type: 'string' }, rendering: { type: 'string' } }, required: ['name', 'description'] } },
    typography: { type: 'string' },
    atmosphereAndLighting: { type: 'string' },
    polishSignals: { type: 'array', items: { type: 'string' } },
    uncertainties: { type: 'array', items: { type: 'string' } },
  },
  required: ['screen', 'imageReadSuccess', 'overallArtDirection', 'composition', 'colorPalette', 'keyElements', 'polishSignals'],
}

const AUDIT_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    cluster: { type: 'string' },
    filesReviewed: { type: 'array', items: { type: 'string' } },
    currentApproach: { type: 'string' },
    techniquesUsed: { type: 'array', items: { type: 'string' } },
    strengths: { type: 'array', items: { type: 'string' } },
    weaknesses: { type: 'array', items: { type: 'string' } },
    gapVsTarget: { type: 'array', items: { type: 'object', additionalProperties: false, properties: { aspect: { type: 'string' }, current: { type: 'string' }, target: { type: 'string' }, severity: { type: 'string', enum: ['high', 'med', 'low'] } }, required: ['aspect', 'current', 'target', 'severity'] } },
  },
  required: ['cluster', 'currentApproach', 'strengths', 'weaknesses', 'gapVsTarget'],
}

const TECHNIQUE_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    domain: { type: 'string' },
    summary: { type: 'string' },
    techniques: { type: 'array', items: { type: 'object', additionalProperties: false, properties: {
      name: { type: 'string' }, what: { type: 'string' }, how: { type: 'string' },
      godotApiOrNodes: { type: 'string' }, codeOrShaderSnippet: { type: 'string' },
      glCompatNotes: { type: 'string' }, effort: { type: 'string', enum: ['S', 'M', 'L'] } },
      required: ['name', 'what', 'how'] } },
    topRecommendations: { type: 'array', items: { type: 'string' } },
    pitfalls: { type: 'array', items: { type: 'string' } },
  },
  required: ['domain', 'techniques', 'topRecommendations'],
}

const GAPPLAN_SCHEMA = {
  type: 'object', additionalProperties: false,
  properties: {
    screen: { type: 'string' },
    targetVision: { type: 'string' },
    gaps: { type: 'array', items: { type: 'object', additionalProperties: false, properties: {
      gap: { type: 'string' }, severity: { type: 'string', enum: ['high', 'med', 'low'] },
      fix: { type: 'string' }, assetsNeeded: { type: 'array', items: { type: 'string' } },
      filesToChange: { type: 'array', items: { type: 'string' } }, techniqueRefs: { type: 'array', items: { type: 'string' } } },
      required: ['gap', 'severity', 'fix'] } },
    newAssets: { type: 'array', items: { type: 'object', additionalProperties: false, properties: { name: { type: 'string' }, purpose: { type: 'string' }, spec: { type: 'string' } }, required: ['name', 'purpose'] } },
    codePatterns: { type: 'array', items: { type: 'string' } },
    priorityOrder: { type: 'array', items: { type: 'string' } },
  },
  required: ['screen', 'targetVision', 'gaps', 'priorityOrder'],
}

// ---------- PHASE 1: Reference extraction ----------
phase('Reference')
log('Extracting the 3 reference mockups (best-effort; image tool is unreliable, so cross-check against stated art direction)')
const refScreens = [
  { key: 'surface', title: '01 水上の釣り画面 (surface fishing / cast)', path: refs.surface.path, url: refs.surface.url },
  { key: 'underwater', title: '02 水中ファイト画面 (underwater fight — signature/看板 screen)', path: refs.underwater.path, url: refs.underwater.url },
  { key: 'cooking', title: '03 調理・食事・レベルアップ画面 (cooking / meal / level-up)', path: refs.cooking.path, url: refs.cooking.url },
]
const referenceSpecs = (await parallel(refScreens.map(function (s) { return function () {
  return agent(
    'You are a senior game art director + UI engineer analyzing ONE reference mockup for a Godot 4.7 fishing JRPG.\n\n' +
    'MOCKUP: ' + s.title + '\n' +
    '- Local file path: ' + s.path + '\n' +
    '- CDN URL for the analyze_image MCP tool: ' + s.url + '\n\n' +
    'PROJECT DESIGN CONTEXT:\n' + ctx + '\n\n' +
    'TASK:\n' +
    '1. TRY TO ACTUALLY SEE THE IMAGE. Call the MCP image-analysis tool named "analyze_image" with imageSource = the CDN URL above. If it returns an error, retry ONCE with a shorter prompt. If it still fails, try Read on the local path. Record imageReadSuccess honestly (yes / partial / failed).\n' +
    '2. CRITICAL — the image tool sometimes HALLUCINATES (it may invent a GBA-isometric scene with fake specifics). Cross-check every extracted detail against the STATED art direction above (retro pixel art + JRPG-style UI + bright sea, GBA/SNES fishing-JRPG lineage like Legend of the River King). If a detail seems inconsistent with a fishing-JRPG mockup or you are unsure, put it in "uncertainties" instead of inventing precise hex values. Do NOT fabricate specificity.\n' +
    '3. Produce a structured spec: overall art direction & mood; composition/layout (where panels, gauges, fish, HUD sit); color palette (role + best-guess hex + note); every key element (background/sea, sky, fish, gauges, frames/panels, buttons, icons, HUD numbers) with HOW it is rendered (pixel? cel? gradient? ornamented frame?); typography (pixel/bitmap vs smooth, weight, outline/shadow); atmosphere & lighting (god-rays, vignette, particles, glow); and the specific POLISH SIGNALS that make it look professional (this is the quality bar we must hit).\n' +
    'Return ONLY the structured object.',
    { label: 'ref:' + s.key, phase: 'Reference', schema: REFERENCE_SCHEMA, effort: 'high' }
  )
} }))).filter(Boolean)

// ---------- PHASE 2: Current code audit ----------
phase('Audit')
log('Auditing current code-driven UI per cluster (diagnose, do not fix yet)')
const auditClusters = [
  { key: 'fight', title: '水中ファイト (signature screen)', files: ['src/ui/fishing_screen.gd', 'src/ui/components/underwater_view.gd', 'src/ui/components/gauge_bar.gd'] },
  { key: 'shell', title: 'シェル/テーマ (title, harbor, nav, theme)', files: ['src/ui/title_screen.gd', 'src/ui/harbor_screen.gd', 'src/main.gd', 'src/ui/ui_theme.gd', 'src/ui/screen_base.gd'] },
  { key: 'cooking_status', title: '調理・図鑑 (cooking, status)', files: ['src/ui/cooking_screen.gd', 'src/ui/status_screen.gd'] },
  { key: 'commerce', title: '市場・釣具店 (market, shop)', files: ['src/ui/market_screen.gd', 'src/ui/shop_screen.gd'] },
]
const audits = (await parallel(auditClusters.map(function (c) { return function () {
  return agent(
    'You are auditing the CURRENT implementation of a Godot 4.7 fishing-JRPG UI cluster to find what limits its visual quality.\n\n' +
    'CLUSTER: ' + c.title + '\n' +
    'FILES (read each with Read): ' + c.files.join(', ') + '\n\n' +
    'PROJECT DESIGN CONTEXT:\n' + ctx + '\n\n' +
    'TASK:\n' +
    'Read every file. Summarize: currentApproach (how it builds visuals today — note the StyleBox/gradient/_draw patterns), techniquesUsed, strengths, weaknesses, and gapVsTarget. For gapVsTarget, go aspect-by-aspect (art style & "pixel-ness", JRPG UI grammar/frames, color & palette, typography, atmosphere/lighting, animation/feedback, asset quality) and state current vs the TARGET (retro pixel + JRPG UI + bright sea at reference-mockup quality) with severity. Reference specific files/APIs/lines. Do NOT propose fixes here — just diagnose accurately.\n' +
    'Return ONLY the structured object.',
    { label: 'audit:' + c.key, phase: 'Audit', schema: AUDIT_SCHEMA, effort: 'medium' }
  )
} }))).filter(Boolean)

// ---------- PHASE 3: Godot technique research ----------
phase('Techniques')
log('Researching Godot 4.7 gl_compatibility techniques to reach target quality (verify APIs via WebSearch)')
const techDomains = [
  { key: 'pixelart', title: 'Retro pixel-art rendering pipeline', focus: 'Nearest-neighbor texture filtering, snap-to-pixel / canvas_items snapping, rendering at a low INTERNAL resolution then upscaling crisp (SubViewport + TextureRect, or low base resolution + stretch), project + .import presets, consistent pixel density at 1280x720, retro palettes, eliminating pixel shimmer on movement. Explain how to retrofit onto an existing smooth-vector game.' },
  { key: 'jrpgui', title: 'JRPG-style UI system', focus: '9-slice / StyleBoxTexture ornate panel frames & window-skin, a rich shared Theme resource, decorative borders / gold accents / corner ornaments / dividers / ribbons, pixel/bitmap fonts with outline + drop shadow, icon sets, hover/press/disabled feedback, consistent panel grammar across all menus. How to migrate the current StyleBoxFlat parchment theme to a textured JRPG window-skin.' },
  { key: 'canvasdraw', title: 'Hand-drawn canvas atmosphere (_draw + shaders)', focus: 'Gradients, fake glow/bloom, vignette, god-rays / light shafts, water shimmer & caustics, particles (bubbles, sparkles, steam, debris), CanvasItemMaterial blend modes, BackBufferCopy, and which 2D canvas-item shaders actually work under gl_compatibility. How to upgrade the existing underwater_view.gd _draw to look cinematic without breaking perf.' },
  { key: 'motionjuice', title: 'Game feel & feedback (juice)', focus: 'Tweens with easing, screen shake, hit-stop, squash & stretch, floating damage / number popups, gauge fill lerp + pulse, level-up burst, button press/anticipation feedback, syncing tween timing to audio. Make the fight & level-up feel alive.' },
  { key: 'assets', title: 'Original asset production & licensing pipeline', focus: 'Aseprite / retro-pixel workflow for fish, backgrounds, UI frames, icons; spritesheets & atlases; import settings; scaling rules at 1280x720; making fish readable & charming; replacing the current code-drawn vector fish/backgrounds; licensing ledger per docs/08 (original art only, no copying existing works pixel-for-pixel).' },
]
const techniques = (await parallel(techDomains.map(function (d) { return function () {
  return agent(
    'You are a Godot 4.7 expert. Specify HOW to achieve top-tier visual quality in this domain for a 2D fishing JRPG running on the GL COMPATIBILITY renderer at 1280x720, code-driven UI (GDScript).\n\n' +
    'DOMAIN: ' + d.title + '\n' +
    'FOCUS: ' + d.focus + '\n\n' +
    'HARD CONSTRAINTS: Godot 4.7, rendering_method = gl_compatibility (explicitly call out which advanced features are UNAVAILABLE — e.g. limited 2D HDR, no 2D screen-space reflections, some 2D shader features restricted — and what IS available, e.g. canvas-item shaders). GDScript. macOS target.\n\n' +
    'TASK:\n' +
    'Use WebSearch to VERIFY current Godot 4.x best practices and exact API/class/method/property names — do NOT use Godot 3 APIs (use Godot 4 names like TextureRect, SubViewport, StyleBoxTexture, CanvasItemMaterial, GPUParticles2D, Tween created via create_tween()). For each technique give: name, what it achieves, how (step-by-step), exact Godot nodes/classes/APIs/shader uniforms, a SHORT copy-pasteable code or shader snippet, gl_compatibility caveats, and effort (S/M/L). End with topRecommendations (3-5 highest-ROI moves in this domain) and pitfalls.\n' +
    'Return ONLY the structured object.',
    { label: 'tech:' + d.key, phase: 'Techniques', schema: TECHNIQUE_SCHEMA, effort: 'high' }
  )
} }))).filter(Boolean)

// ---------- PHASE 4: Gap + plan per screen ----------
phase('Gap & Plan')
log('Synthesizing per-screen gap analysis + concrete build plan from the three upstream phases')
const refSummary = JSON.stringify(referenceSpecs)
const auditSummary = JSON.stringify(audits)
const techSummary = JSON.stringify(techniques)
const planScreens = [
  { key: 'underwater', title: '水中ファイト画面 (signature)', note: 'Current: src/ui/fishing_screen.gd + src/ui/components/underwater_view.gd + gauge_bar.gd. Highest priority — this is the 看板 screen.' },
  { key: 'surface', title: '水上の釣り/キャスト画面', note: 'Current fishing screen jumps straight to underwater; reference shows a surface casting view. Plan how to add a surface-cast phase or materially enrich the READY/BITE states.' },
  { key: 'cooking', title: '調理・食事・レベルアップ画面', note: 'Current: src/ui/cooking_screen.gd (+ status_screen.gd for 図鑑). Includes the level-up flourish (docs/03 §5).' },
  { key: 'shell', title: '全体シェル・共通テーマ・デザイントークン', note: 'title_screen, harbor_screen, main.gd, ui_theme.gd, screen_base.gd. Establishes the global JRPG look + pixel pipeline shared by all screens.' },
]
const plans = (await parallel(planScreens.map(function (p) { return function () {
  return agent(
    'You are the lead engineer turning diagnosis into a concrete build plan for ONE screen of a Godot 4.7 fishing JRPG.\n\n' +
    'SCREEN: ' + p.title + '\n' +
    'NOTE: ' + p.note + '\n' +
    'TARGET ART DIRECTION: retro pixel art + JRPG-style UI + bright sea, at reference-mockup quality, ORIGINAL art only (no copying existing works pixel-for-pixel).\n\n' +
    'UPSTREAM INPUTS (JSON — read carefully and cite technique names in techniqueRefs):\n' +
    'REFERENCE EXTRACTS: ' + refSummary + '\n' +
    'CURRENT AUDITS: ' + auditSummary + '\n' +
    'GODOT TECHNIQUES: ' + techSummary + '\n\n' +
    'TASK:\n' +
    '1. targetVision: 2-4 sentences describing what this screen should look & feel like at target quality.\n' +
    '2. gaps: each with gap, severity, a CONCRETE fix (not vague), assetsNeeded, filesToChange, techniqueRefs (names from the techniques domain). Prefer closing gaps by upgrading SHARED components (ui_theme.gd, screen_base.gd, gauge_bar.gd, underwater_view.gd) so all screens benefit.\n' +
    '3. newAssets: each original asset needed (name, purpose, spec: resolution, palette, frames if animated).\n' +
    '4. codePatterns: reusable GDScript patterns this screen needs.\n' +
    '5. priorityOrder: ordered list of what to do first (highest ROI / lowest risk / unblocks others).\n' +
    'Be concrete and Godot-4.7/gl_compat-specific. Where the reference extract was uncertain, lean on the stated art direction and mark assumptions.\n' +
    'Return ONLY the structured object.',
    { label: 'plan:' + p.key, phase: 'Gap & Plan', schema: GAPPLAN_SCHEMA, effort: 'high' }
  )
} }))).filter(Boolean)

log('Done. reference=' + referenceSpecs.length + ' audits=' + audits.length + ' techniques=' + techniques.length + ' plans=' + plans.length)
return { referenceSpecs: referenceSpecs, audits: audits, techniques: techniques, plans: plans }
