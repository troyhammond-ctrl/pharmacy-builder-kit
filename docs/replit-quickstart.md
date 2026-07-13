# Using pharmacy-builder-kit in Replit

This guide walks an operator through running the pharmacy-builder skill inside a Replit project, from blank slate to deployed site. End to end, a build takes 20–40 minutes of operator time and ~30–60 minutes of Replit Agent work.

> If you've never used Replit Agent before, the short version: it's an AI assistant inside Replit that can read files, write code, run commands, and iterate. This skill (`SKILL.md`) is a system-prompt-style instruction document that tells the agent exactly what to build and what the output must satisfy.

---

## What you need before you start

1. **A Replit account.** The free plan works for development; you'll need the Core or Teams plan if you want to use Replit Deployments to host the finished site.
2. **The build folder.** A directory containing at minimum:
   - A build sheet (`.docx`) whose filename contains `Build Sheet`.
   - A logo file (PNG / JPG / SVG) — either in the folder root or referenced via a `Logo:` URL inside the build sheet.
   - Optionally: `Website content*.docx`, `QA *.docx`, `SEO_META_Tags_*.docx`, plus any additional photos / PDFs / videos.
3. **The pharmacy's existing website URL.** Required for the scrape step (referenced by the `Website URL` field of the build sheet).
4. **No PHI in the folder.** Strip patient identifiers, prescription numbers, DOBs, etc. before uploading.

---

## Path A — Recommended: import this repo as the project

The fastest way. The skill, tests, and docs come with the project.

### 1. Import the repo

In Replit:

1. Click **Create Repl** → **Import from GitHub**.
2. Paste `https://github.com/troyhammond-ctrl/pharmacy-builder-kit`.
3. Pick a language template — choose **HTML, CSS, JS** as a safe default; Replit Agent will reshape it to whatever stack it picks during scaffolding.
4. Click **Import from GitHub**.

You now have a Repl containing `SKILL.md`, the tests, the README, the design spec, and the implementation plan.

### 2. Add the build folder

In Replit's file pane:

1. Create a new folder at the project root named after the pharmacy — for example `_build-input/`.
2. Drag and drop the build sheet `.docx`, the logo, and any supporting docs into `_build-input/`.

Replit will upload the binary files; you'll see them appear in the tree.

### 3. Open Replit Agent and load the skill

1. Click the **Agent** icon (top-right sidebar — looks like a chat bubble).
2. In Agent's settings, look for a **System prompt** or **Custom instructions** field. If your Replit plan exposes it, paste the entire contents of `SKILL.md` there.
3. If your plan doesn't expose a system prompt slot, instead paste this into the first agent message:

   > Read `SKILL.md` in this project and treat it as your binding instructions for the entire conversation. Then read this message:
   >
   > Build a pharmacy site from the build folder at `./_build-input/`. Follow the five-step Process in SKILL.md (Discover → Scrape → Plan → Generate → Validate). Stop and ask before you start Step 4 if any required field is missing from `build/context.json`.

### 4. Start the build

Type into the agent chat:

> Begin Step 1 — Discover. Parse the build folder at `./_build-input/` and write `build/context.json`. Stop when context.json is complete and tell me what was extracted and what was marked null.

Replit Agent will read the build sheet, extract every field listed in `SKILL.md` § Inputs, and write `build/context.json`. Inspect the file — every required field should be present, with `null` + `nullReason` for anything missing.

### 5. Continue through the remaining steps

After Discover passes, prompt:

> Begin Step 2 — Scrape. Write and run `tools/scrape.mjs` against the build-sheet `Website URL`. Halt if the site is unreachable and log it.

Then Step 3 — Plan, Step 4 — Generate, Step 5 — Validate. After each step, inspect the artifact (`/scraped/manifest.json`, `/build/page-plan.json`, generated pages, `/build/log.md`) before moving on.

### 6. Verify

Run the structural test harness from the Shell tab:

```sh
bash tests/run.sh
```

You should see 17 green test suites. These verify SKILL.md hasn't drifted — they do NOT verify the generated site. The generated site is verified by `/build/log.md` and the three validator scripts the agent ran in Step 5.

---

## Path B — Paste SKILL.md as a system prompt into a fresh Repl

Use this when you don't want the kit's tests/docs in the project — only the generated pharmacy site.

1. Create a new Repl with the **HTML, CSS, JS** template (or whichever stack you prefer).
2. Upload the build folder as `_build-input/` (as in Path A step 2).
3. Open Replit Agent.
4. Paste the entire contents of `SKILL.md` (copy from [GitHub](https://github.com/troyhammond-ctrl/pharmacy-builder-kit/blob/main/SKILL.md)) as the agent's system prompt or first message.
5. Follow Path A steps 4–5 to drive the five-step build.

You'll lose the structural-test harness but the agent still has the full contract.

---

## What you should see at each step

| Step | Artifact | What to inspect |
|---|---|---|
| 1 Discover | `build/context.json` | Every required field present; absent fields = `null` with a `nullReason`; `provenance` annotations correct |
| 2 Scrape | `/scraped/manifest.json`, `/scraped/text/*.md`, `/scraped/assets/*` | Manifest has page entries OR `scrape_status: "unreachable"`; assets downloaded |
| 3 Plan | `/build/page-plan.json` | Eight always-built pages + conditional pages per build-sheet flags; each entry has URL, title, description, H1, sections |
| 4 Generate | `index.html` and the rest of the site; `robots.txt`, `sitemap.xml`, `llms.txt` | Pages render; site-wide files are valid (see Validation below) |
| 5 Validate | `/build/log.md` | The closing QA checklist is reproduced with every box checked |

---

## Validating the build before declaring done

Replit Agent must run three validators in Step 5:

```sh
node tools/validate-content.mjs   # banned phrasings, PHI scan, clinical patterns
node tools/validate-a11y.mjs       # WCAG 2.2 AA structural checks
node tools/validate-schema.mjs     # JSON-LD parse + required properties
```

After all three pass, the agent runs a manual structural verification (file presence, page count, head elements). The closing checklist in `/build/log.md` must have **every box checked**. An unchecked box = build not done.

Also worth running manually:

```sh
# Sitemap well-formedness — should output the XML, not a parse error
xmllint --noout sitemap.xml && echo "✓ sitemap.xml is well-formed"

# Robots syntax check (Google's robots.txt tester is the authoritative check)
curl -fsS http://localhost:<port>/robots.txt | head

# llms.txt presence
test -f llms.txt && echo "✓ llms.txt exists"
```

---

## Previewing the site

Replit auto-serves the project on a preview URL. Use that to spot-check:

1. **Mobile preview.** Open Chrome DevTools (or use Replit's mobile preview toggle) and verify:
   - The mobile menu opens with the hamburger button (≥ 44×44 tap target).
   - The drawer traps focus and Esc closes it.
   - The sticky bottom CTA bar appears below the hero with Call + Refill.
   - Above the fold: name, tagline, Refill CTA, phone link, open-now indicator — all visible without scroll.
2. **Desktop.** Sticky header doesn't wrap; services dropdown opens on hover/focus; CTAs in order (Refill, Transfer, Patient Portal).
3. **Click-to-call.** Tap the phone number on a real phone (use Replit's QR code preview); it should launch the dialer with the correct number.
4. **Open-now indicator.** It should match real time at the pharmacy's location, not yours.
5. **Map.** Loads on the contact page and the "Get directions" link opens Google Maps.

---

## Running the QA skill as an independent audit

The builder's Step 5 — Validate runs three validators against its own output. For an independent second opinion (recommended before deploy), invoke the sibling [`QA-SKILL.md`](../QA-SKILL.md) against the built site.

In Replit Agent:

> Read `QA-SKILL.md` in this project and treat it as your binding instructions. Audit the site at `http://localhost:<port>` (or the deployed URL). Run all twelve audit dimensions and emit `audit/report.md` plus `audit/report.json`. Cross-reference findings against `build/context.json` when checking factual claims.

The auditor will:

1. **Resolve** the URL / path, discover pages via `sitemap.xml`, write `audit/scope.json`.
2. **Fetch** every page (raw HTML + rendered DOM + network metrics).
3. **Check** twelve dimensions: pages & structure, accessibility (WCAG 2.2 AA), SEO metadata, schema (JSON-LD), site-wide files (robots/sitemap/llms validity), mobile UX (drawer / sticky bottom bar / tap targets), conversion patterns, content guardrails (banned phrasings / PHI scan / clinical advice / fabricated facts), voice & readability, visual quality, performance, security & privacy.
4. **Render** the report at `audit/report.md` and `audit/report.json`.
5. **Verdict** — PASS, PASS WITH WARNINGS, or FAIL.

Treat a FAIL verdict as blocking. Treat PASS WITH WARNINGS as a punch list to work through before launch. Inspect `audit/findings.jsonl` for the full structured findings.

## Deploying

Replit Deployments serves static sites well:

1. Click **Deploy** in the top-right sidebar.
2. Choose **Static deployment**.
3. Set the build command if the agent picked a build-step stack (e.g., `npm run build` for Vite/Next/Astro); for plain HTML/CSS/JS, leave empty.
4. Set the public directory:
   - Vite: `dist/`
   - Next.js (static export): `out/`
   - Astro: `dist/`
   - Plain HTML: `.` (project root)
5. Set the custom domain to the build sheet's `New Website URL` host once DNS is in place.
6. Click **Deploy**.

Replit gives you a `*.replit.app` URL immediately. Verify the live site by running the validators against it — for example, fetch `/robots.txt`, `/sitemap.xml`, and `/llms.txt` and re-check.

---

## Iterating on design

Design is a **single generation pass** — the skill deliberately does not chain external design-agent skills. That keeps the build fast and cheap while still hitting the professional bar via the recommended stack (React + Tailwind + shadcn/ui via the shadcn MCP) and the constraint set in §Visual design.

If you want to iterate on visuals after the initial build:

> Do a second design pass on the rendered output. Keep §Visual design constraints (brand color canonical, WCAG 2.2 AA wins, one icon set, no ornamental display fonts, no horizontal scroll at 320px) and §Conversion contracts intact. Focus on: <specific area — e.g., "hero visual weight," "service card hierarchy," "footer density">. Re-run the accessibility validator and content validator after changes.

The agent runs a single-pass second iteration only when you explicitly ask, so cost stays bounded by intent. If you want the free lunch of "make it look better," the agent will still avoid the expensive multi-skill review loops the earlier version of this skill invoked.

Design is done when: the a11y validator passes, the content validator passes, and you've eyeballed the mobile + desktop preview.

---

## Common failure modes

**"Build sheet missing"**
The discovery rule looks for a filename containing `Build Sheet`. Rename your file accordingly (e.g., `Build Sheet — Acme Pharmacy.docx`) and re-run Step 1.

**"Scrape unreachable"**
The pharmacy's live site is down, blocking the User-Agent, or returns 403 on `robots.txt`. This is a soft fail — the agent should log it to `/build/log.md` and continue with build-sheet-only content. If the resulting site lacks scraped content (testimonials, images), that's expected.

**"Validator failed: banned phrasing"**
The agent generated copy containing a banned marketing phrase (e.g., "industry-leading"). The agent should regenerate the offending block. If a banned phrase legitimately appears verbatim in the build sheet (e.g., "FREE local delivery"), the agent should keep it — the validator allows source-verified exact matches.

**"Validator failed: PHI scan hit"**
A form field named `dob`, `rx_number`, `member_id`, `medication`, `mrn`, or `diagnosis` was generated, or a date input appears inside a `<form>`. Remove the field. Transfer page should be CTA-only — replace any form with "Call us at `<phone>` to transfer."

**"sitemap.xml is invalid"**
Common causes: BOM at the start, missing namespace, missing `<lastmod>`/`<changefreq>`/`<priority>` sub-elements, unescaped `&` in URLs. The agent should regenerate. Run `xmllint --noout sitemap.xml` to confirm.

**"Mobile menu doesn't trap focus"**
Implement the focus trap explicitly. A common cause is using `display: none` on the drawer instead of `visibility: hidden`; the former removes elements from the tab order in a way that confuses some screen readers.

**"Open-now indicator shows wrong status"**
The agent likely used the visitor's browser timezone instead of the pharmacy's. The `Intl.DateTimeFormat` call must pass the pharmacy's IANA timezone (e.g., `America/Los_Angeles`) as the `timeZone` argument — derived from the build-sheet address, not from `navigator.languages` or visitor location.

---

## What this skill will NOT do

- **Collect PHI.** No forms request DOB, medications, conditions, Rx numbers, MRN, diagnosis, or insurance member IDs. Transfer is a CTA + outbound link only.
- **Fabricate facts.** Hours, address, phone, credentials, awards, licenses, services, insurance plans — if it's not in the build sheet or the scrape, the corresponding section is omitted, not stubbed.
- **Give medical advice.** No clinical recommendations. Emergency mentions use only the literal phrase "Call 911 or go to the nearest emergency room."
- **Use marketing hyperbole.** No "revolutionary," "best-in-class," "industry-leading," "cutting-edge," "award-winning" (unless an award is in the source), or comparative claims about other pharmacies.
- **Add on-site search.** No `/search` route, no search input in markup, no `SearchAction` JSON-LD.

---

## Where to learn more

- [`SKILL.md`](../SKILL.md) — the full contract.
- [`docs/superpowers/specs/2026-05-20-pharmacy-builder-skill-design.md`](superpowers/specs/2026-05-20-pharmacy-builder-skill-design.md) — design spec.
- [`docs/superpowers/plans/2026-05-20-pharmacy-builder-skill-plan.md`](superpowers/plans/2026-05-20-pharmacy-builder-skill-plan.md) — implementation plan that built `SKILL.md`.
- [`README.md`](../README.md) — kit overview.
