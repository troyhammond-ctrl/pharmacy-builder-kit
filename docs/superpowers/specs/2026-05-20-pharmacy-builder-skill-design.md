# Pharmacy Builder Skill — Design Spec

**Date:** 2026-05-20
**Owner:** Troy Hammond
**Status:** Approved for implementation planning
**Artifact:** `SKILL.md` at the root of `pharmacy-builder-kit/`

## Problem

Lumistry receives build folders for new pharmacy websites. Each folder contains a structured build sheet (`.docx`), the pharmacy's logo, and optional supporting docs (curated content, QA notes, pre-written SEO meta tags). The current process is human-driven and uneven across pharmacies.

We want one canonical, stack-agnostic skill that any Replit Agent (or Claude) can follow to produce a clean, modern, unique, accessible, factually faithful pharmacy website from a build folder — without inventing facts, leaking PHI, or drifting in voice.

## Shape decisions (from brainstorming)

| Decision | Choice |
|---|---|
| Artifact | A single `SKILL.md` markdown file at the repo root. Pasted into Replit Agent as the system prompt, or referenced directly. |
| Stack prescription | **None.** Skill is stack-agnostic. Replit Agent picks Astro/Next/HTML/whatever; the skill enforces the output contract. |
| Source-site scrape | Skill instructs Replit Agent to scrape the live source URL into `/scraped/`. No human pre-scrape. |
| Input bundle | Required: build sheet + logo. Optional and auto-detected: `Website content.docx`, `QA *.docx`, `SEO_META_Tags_*.docx`, extra images/PDFs. |
| File organization | **Approach B: Reference + Process.** Half of `SKILL.md` is the contract (Inputs / Outputs / Pages / Sections / Voice / Guardrails / A11y / SEO / Schema). The other half is the 5-step build process, each step referencing the contract sections. |

## Section 1 — Skeleton & input contract

### Skill file shape
Single `SKILL.md` at the repo root. Standard skill frontmatter (`name`, `description`). The `description` includes trigger phrases: "build pharmacy site," "build pharmacy website," "pharmacy build sheet," "Lumistry pharmacy build," and the known template labels (e.g., "Longhorn"). No per-pharmacy account names — the skill is generic across pharmacies.

### Invocation contract
One input: a path to a build folder. Operator runs the skill with that path; the skill's first job is to scan and resolve the folder.

### Input folder layout

| File | Required? | Discovery rule |
|---|---|---|
| Build sheet (`.docx`) | **Required** | Filename contains `Build Sheet` |
| Logo (PNG/JPG/SVG) | **Required** | Image in folder root, or fetched from build sheet's `Logo:` URL |
| `Website content.docx` | Optional | Filename matches `*content*.docx` |
| `QA *.docx` | Optional | Filename matches `QA *.docx` |
| `SEO_META_Tags_*.docx` | Optional | Filename matches `SEO_META*.docx` |
| Extra images, PDFs, videos | Optional | Any other media in folder; cataloged for possible reuse |
| Word lockfiles (`~$*.docx`) | Ignored | Skipped entirely |

### Fields the skill must extract from the build sheet
Pharmacy name, address, hours, phone, fax, email, source website URL, new website URL, Google Map URL, refill portal URL, transfer-form requirement (yes/no), mobile-app-page flag (yes/no), GA ID, head JS snippet, brand color (hex), logo URL, package label, template label, services topics (deeper treatment), services list (shallow card), per-service description copy, immunization options, year opened, tagline, about copy, pickup methods, additional-locations flag, social links if present.

### Conditional flags the skill must respect
- `Requires Mobile App Page: Yes` → build the `/app/` page with real Apple/Google badges.
- `Requires refill portal button` (URL present) → wire Refill CTA to that URL.
- `Requires transfer form page` → add `/transfer/` page as CTA-only (no PHI form — see §4).
- `Pickup Methods` → drives `/refill/` copy.
- `Additional locations? Yes` → drives `/locations/` index + per-location pages.

### "Template: Longhorn" handling
Treated as a label/hint only — not a binding template directive. Recorded in build metadata; the skill produces a clean, modern, unique design regardless.

### Output of this step
A single `build/context.json` consolidating every parsed field with explicit `null` for absent fields and a `provenance` annotation per field (`build_sheet | content_doc | qa_doc | seo_doc | scrape`). This is the single source of truth all later steps quote from.

## Section 2 — Scrape step

### Goal
Mirror the build sheet's `Website URL` (the pharmacy's existing live site) to a local `/scraped/` folder so the build can pull facts, copy, and assets without re-fetching. The scrape is a **fact source**, not a **design source** — the new site doesn't have to look like the old one.

### Mechanics
The skill prescribes a Node script (`tools/scrape.mjs`) Replit Agent writes and runs. Skill specifies the contract; agent owns the implementation:

- **Seed:** the build sheet's `Website URL` field (existing site, not the staging URL).
- **Crawl rules:** same-origin only, depth ≤ 3, max 200 pages, 1 req/sec, descriptive User-Agent. Respects source's `robots.txt`. Skips `mailto:`, `tel:`, anchor-only links, tracker/CDN hosts.
- **Asset capture:** every `<img src>`, `<source>`, `<video>`, and any `<a href>` pointing to `.pdf`/`.docx`/`.mp4`/`.webm`/image extensions. Downloaded to `/scraped/assets/` with collision-safe original filenames.
- **Content capture:** each page saved as raw HTML (`/scraped/raw/<slug>.html`) plus a readable extraction (`/scraped/text/<slug>.md`) for LLM consumption.
- **Manifest:** `/scraped/manifest.json` — every URL with status, final URL, title, h1, word count, referenced assets, outbound internal links.

### Failure handling
If source is unreachable (DNS fail, 403, robots-blocked): log it to `/build/log.md` and continue with build-sheet-only content. **No silent fallback.**

### Allowed uses of scraped content
- Source of fact (services actually claimed, awards, staff names, hours phrasing) — every claim still satisfies the factual-guardrails section.
- PDFs (forms, brochures) linked from the new site if relevant.
- Storefront/team/product images, with generated alt text.

### Disallowed uses
- **Overriding the build sheet on conflict.** Build sheet is canonical; conflicts logged.
- **Carrying over PHI** (patient testimonials with full names + conditions, etc.) — redact.
- **Carrying over marketing hyperbole, comparative claims, clinical claims, unverified credentials** — filtered per §4.

### Handoff to next step
`/scraped/manifest.json` (structured index) + `/scraped/text/*.md` (readable corpus).

## Section 3 — Output contract: required pages & sections

### Required pages (always)

| Page | URL | Purpose |
|---|---|---|
| Home | `/` | Hero, services, trust, testimonials, hours, CTAs |
| About | `/about/` | Pharmacy story, year opened, tagline, independence |
| Contact | `/contact/` | Address, phone, fax, email, map + directions link, hours |
| Services index | `/services/` | All services grid with links to per-service pages |
| Per-service | `/services/<slug>/` | One page per Topic in build sheet (deeper treatment); shallow card-only for List items |
| Refill | `/refill/` | Wires refill portal URL; describes pickup methods |
| Transfer | `/transfer/` | Outbound link / CTA only — **no PHI form** |
| FAQ | `/faq/` | Site-wide FAQs, expandable + `FAQPage` schema |

### Conditionally built

| Condition | Page |
|---|---|
| `Requires Mobile App Page: Yes` | `/app/` with real Apple App Store + Google Play badges |
| `Additional locations? Yes` | `/locations/` index + `/locations/<slug>/` per location |
| Scrape discovers a page with ≥ 150 substantive words not covered above | `/<slug>/` |

### Required sections — every page
- Sticky header (logo, primary nav with **services dropdown**, three CTAs: Refill / Transfer / Patient Portal).
- Top bar above header: address, phone, hours, **open-now indicator** computed in the browser from the build sheet's `Hours:` and local TZ. Falls back to "Open/Closed unavailable" if JS disabled. Never invents.
- FAQs near the bottom with `FAQPage` JSON-LD.
- Footer: address, phone, hours, social (only if scraped), NPI/licenses (only if found in source), copyright, accessibility statement, sitemap link.

### Home-only sections
- Hero (build-sheet tagline + primary CTA).
- Services grid with **unique iconography** (line SVGs, single icon set, brand-colored via `currentColor`). Same icon set reused in the services dropdown.
- Hours of operation block (semantic table).
- Trust / why-independent callouts (from build sheet + scrape; no comparative claims).
- Testimonials (only if found in source; **never fabricated**; omitted if absent).
- App download row (only if mobile app page is enabled).

### Contact-only sections
- Address/phone/fax/email blocks (semantic, each clickable).
- Map embed using build sheet `Google Map URL`; "Get directions" link opens Google Maps. **No form.**
- Hours of operation.
- FAQs.

### Per-service-page sections
- H1 = service name.
- Verbatim description from build sheet + scraped detail if available.
- For Immunizations: list `Immunization Options` from build sheet exactly — never extend.
- CTA appropriate to the service.
- FAQs scoped to the service.

### Iconography rule
One coherent icon set, line style, ~24×24 viewBox, single-stroke, recolorable via `currentColor`. Same set on home services grid AND in header dropdown. Agent picks one set (Lucide / Heroicons / Phosphor) and commits to it.

### Section omission rule
Any required section whose content can't be sourced is **omitted, not stubbed.** No "Lorem ipsum," no "Coming soon," no fake content.

## Section 4 — Voice & content guardrails

### Voice
- Plain language, ~8th-grade reading level (Flesch-Kincaid ≥ 70 target).
- Short sentences. Active voice. Second person ("you can…") not third.
- Warm but not casual. Friendly, not flippant.
- Practical: tell the patient what to do, where to go, what to expect.
- Local references (community, neighborhood, family-owned, independent) **only if backed by build sheet or scrape.** A claim like "independent" is fine only when the build sheet or scrape supports it; "family-owned" is not writable unless the source explicitly says so. Apply this same test to every local-color claim.

### Banned phrasings (explicit greppable list)
- "revolutionary," "world-class," "best-in-class," "cutting-edge," "state-of-the-art," "industry-leading," "premier," "award-winning" (unless source confirms), "voted #1," "top-rated"
- "proven to," "cures," "guarantees," "safest," "fastest"
- "all insurance," "any insurance," "every insurance"
- "24-hour," "24/7," "same-day delivery," "free delivery" — banned unless the exact claim appears verbatim in the build sheet or scrape (e.g., a build sheet that explicitly says "FREE local delivery" unlocks that phrasing for that pharmacy only)
- "board-certified," "PharmD," "RPh," and any other credential — unless found verbatim in source
- Any sentence naming a competing pharmacy ("unlike CVS")
- Any clinical-advice sentence pattern ("you should take…")

### Factual guardrails (never invent)
Hours, address, phone, fax, email, staff names, credentials, residencies, board certifications, awards, licenses, NPI, NCPDP, DEA, services offered, insurance plans, years in business, refill/transfer/portal URLs, any legal claim. If not in build sheet or scrape, the corresponding section is **omitted.**

### PHI rules
- Site must never collect, request, store, or output PHI.
- Banned on public forms: full names + medications/conditions, DOB, MRN, Rx number, diagnosis, insurance member IDs.
- Transfer page = **CTA + outbound link only.** No fields. If scraped source has a PHI form, do not port it — replace with "Call us at `<phone>` to transfer."
- Contact page has no form (already settled in §3).
- **PHI scanner step** runs over every generated HTML before declaring done: greps for `name="dob"`, `name="rx_number"`, `name="member_id"`, `name="medication"`, date inputs inside forms, and bare `<form>` elements that aren't external links → **fail build** on hit.

### Clinical advice
- Never tell a patient what to take, when to stop, what a symptom means.
- For emergencies, **only** allowed phrase: "Call 911 or go to the nearest emergency room." Nothing else.

### Verification mechanism
`tools/validate-content.mjs` — scans all generated HTML, fails on banned phrasings, non-sourced factual claims, PHI-shaped form inputs, clinical patterns. Output: pass/fail with line-numbered evidence to `/build/log.md`.

## Section 5 — A11y, SEO, schema baselines

### Accessibility (WCAG 2.2 AA)

**Structural**
- Exactly one `<h1>` per page. Heading levels never skip.
- `<header>`/`<nav>`/`<main>`/`<footer>` landmarks every page. Skip-link first focusable element.
- Real `<button>`/`<a>` — never `<div onclick>`. Tab order matches visual order. Esc closes dropdowns. Enter/Space activates buttons.
- Visible focus state: ≥ 2px outline, ≥ 3:1 contrast against adjacent colors. Never `outline: none` unbalanced.
- Sticky header doesn't trap focus.

**Content**
- Every `<img>` has `alt`. Substantive images: object + context (e.g., "Pharmacist counseling a patient at the pharmacy counter"). Decorative images: `alt=""`. Logo alt: `<Pharmacy Name> logo`.
- No image-only text for substantive content.
- Icons in services grid/dropdown: `aria-hidden="true"` (text label adjacent).
- `<html lang="en">` always.

**Contrast**
- Body text on background: ≥ 4.5:1.
- Large text (≥ 18pt or 14pt bold): ≥ 3:1.
- Brand color (build sheet hex) used for accents. Skill auto-darkens the brand color if it can't reach 4.5:1 against white for body text; body text falls back to `#111111`. Brand stays accent-only.
- Contrast check script: `axe-core` or equivalent.

**Open-now indicator a11y**
- Both color cue AND text label ("Open" / "Closed").
- `aria-live="polite"` announces value when first computed.
- Never color-only.

### SEO (every page)

**Required `<head>` elements**
- `<title>` — pattern: `<page> | <Pharmacy Name>` (or `<Pharmacy Name> | <Tagline>` for home). ≤ 60 chars. If `SEO_META_Tags_*.docx` is present and supplies per-page titles, use them verbatim and skip the pattern.
- `<meta name="description">` — 140–160 chars. No banned phrasing.
- `<link rel="canonical" href="<absolute>">` — root = build sheet `New Website URL`.
- Exactly one `<h1>`.
- Open Graph: `og:title`, `og:description`, `og:url`, `og:type` (`website` / `business.business`), `og:image` (1200×630 PNG generated from logo + brand color + page title).
- Twitter card: `twitter:card=summary_large_image`, `twitter:title`, `twitter:description`, `twitter:image`.
- Viewport, charset, `theme-color` = brand color.

**Site-wide files**
- `/robots.txt` — allows all, references sitemap.
- `/sitemap.xml` — every generated page; `lastmod` = build date; `priority` 1.0 home / 0.8 top-level / 0.6 deep.
- `/llms.txt` — markdown index per llms.txt spec: `# <Pharmacy Name>`, short description, sectioned link lists (Pages, Services, About).

### JSON-LD schema (must validate against schema.org)

**Every page**
- `Pharmacy` (extends `LocalBusiness`) with `name`, `image`, `logo`, `address` (`PostalAddress`), `telephone`, `email`, `url`, `openingHoursSpecification` (parsed from build sheet hours), `geo` (lat/lng only if already present in source HTML or scraped metadata — no external geocoding API; omit otherwise), `sameAs` (social URLs from scrape only).
- `WebPage` with `name`, `description`, `url`, `inLanguage=en`, `isPartOf` → WebSite.
- `BreadcrumbList` on any non-home page.
- `FAQPage` for the page's FAQ section. Questions from build sheet/scrape/QA doc; never invented.

**Page-specific**
- Home: `WebSite` with `potentialAction` `SearchAction` only if on-site search exists.
- Per-service: `Service` with `provider` → Pharmacy, `serviceType`, `areaServed`, `description`.
- Contact: explicit `ContactPoint` array.
- App page (when present): `MobileApplication` with real App Store + Google Play URLs from build sheet.

**Validation**
`tools/validate-schema.mjs`:
- Extracts every `<script type="application/ld+json">` block.
- Parses each; fails on parse error.
- Validates required properties against a schema map the skill includes.
- Posts to Google's Rich Results test only if `--online` flag set. **Default: offline.**
- Pass/fail → `/build/log.md`.

### Open-now indicator note
Browser-runtime feature. Underlying truth (`openingHoursSpecification`) lives in JSON-LD so search engines see correct hours regardless of what the badge shows in any moment.

## Section 6 — Process half + QA self-validation

### The 5-step process

**Step 1 — Discover.**
- Input: build folder path.
- Action: scan folder, identify build sheet + logo + optional docs (per §1). Parse build sheet into `build/context.json`. Parse `Website content.docx` / `QA *.docx` / `SEO_META_Tags_*.docx` if present; merge into context with provenance labels.
- Exit criteria: `context.json` written; every required field populated or marked `null` with a `nullReason`.
- Hard fail: build sheet missing.
- Warning + continue: logo missing.

**Step 2 — Scrape.**
- Input: source URL from build sheet.
- Action: run `tools/scrape.mjs` per §2. Write `/scraped/manifest.json` + `/scraped/text/*.md` + `/scraped/assets/*`.
- Exit criteria: manifest written; either ≥ 1 page successfully fetched OR `scrape_status: "unreachable"` logged.
- Failure mode: unreachable source → continue with build-sheet-only content; never silently substitute.

**Step 3 — Plan.**
- Input: `context.json` + `manifest.json`.
- Action: Replit Agent produces `/build/page-plan.json` — every page it will generate, annotated with sections (per §3), source contributions, and JSON-LD blocks (per §5).
- Exit criteria: every required page from §3 in the plan; conditional pages have triggers documented.
- Hard fail: required page missing from plan.

**Step 4 — Generate.**
- Input: page plan + context + scraped corpus.
- Action: Replit Agent picks a stack, scaffolds the project, generates each page from the plan, writes `robots.txt` / `sitemap.xml` / `llms.txt` (§5), generates icon set + derived palette (§3, §5), wires head JS snippet + GA ID into `<head>`, wires Refill / Transfer / Patient Portal CTAs to build sheet URLs.
- Exit criteria: project builds; every page in the plan is emitted; SEO/schema/landmark/skip-link contracts present per page.
- Failure mode: build error → fix and retry; never silently skip a page.

**Step 5 — Validate.**
- Input: generated project.
- Action: run three validators:
  1. `tools/validate-content.mjs` — banned phrasings, non-sourced facts, clinical patterns, PHI form scanner (per §4).
  2. `tools/validate-a11y.mjs` — landmarks, heading order, alt text, focus styles, contrast, keyboard reachability of services dropdown (per §5 a11y).
  3. `tools/validate-schema.mjs` — JSON-LD parse + required properties; offline by default (per §5 schema).
- Plus structural check: required pages exist, required sections per page, `<title>`/`description`/`canonical`/single-H1/OG present per page, `robots.txt` + `sitemap.xml` + `llms.txt` exist.
- Exit criteria: all validators PASS; `/build/log.md` is a clean PASS report with version + timestamp.
- Failure mode: any validator FAIL → list offending lines/files, halt, do not declare done. No "mostly passing" outcomes.

### QA self-validation checklist (closing contract)

Literal checklist at the bottom of `SKILL.md`. Replit Agent must reproduce it in `/build/log.md` with each item checked off:

```
INPUTS
[ ] Build sheet parsed; all enumerated fields captured or marked null
[ ] Logo present and used; alt="<Pharmacy Name> logo"
[ ] Supporting docs (content/QA/SEO meta) merged with provenance
SCRAPE
[ ] Source site mirrored or "unreachable" logged; no silent fallback
[ ] Build sheet wins on conflict; conflicts logged
PAGES
[ ] Home, About, Contact, Services index, Per-service, Refill, Transfer, FAQ
[ ] App page iff Requires Mobile App Page = Yes
[ ] Locations iff Additional Locations = Yes
[ ] No stubbed sections — anything unsourced is omitted
HEADER / SITE-WIDE SECTIONS
[ ] Sticky header with logo, services dropdown, 3 CTAs
[ ] Top bar with address, phone, hours, open-now indicator (text + color)
[ ] Footer with address/phone/hours, accessibility statement, sitemap link
[ ] Services grid + dropdown use ONE icon set, brand-colored via currentColor
A11Y (WCAG 2.2 AA)
[ ] Single H1 per page; no skipped heading levels
[ ] Landmarks, skip-link, visible focus, keyboard-operable dropdown
[ ] All images have alt; decorative images have alt=""
[ ] Contrast >= 4.5:1 body, >= 3:1 large; brand auto-darkened if needed
SEO + SCHEMA
[ ] Title, description, canonical, og:*, twitter:*, single H1 per page
[ ] robots.txt, sitemap.xml, llms.txt generated
[ ] Pharmacy/LocalBusiness JSON-LD on every page
[ ] FAQPage JSON-LD wherever FAQs appear
[ ] BreadcrumbList on non-home pages
[ ] Service JSON-LD per service page
[ ] MobileApplication JSON-LD only when app page exists
[ ] Schema validates (parse + required props)
CONTENT GUARDRAILS
[ ] Banned phrasing scan: zero hits
[ ] No non-sourced factual claims (services, insurance, awards, credentials)
[ ] No PHI form fields; transfer page is CTA-only
[ ] Emergency copy = exact mandated phrase, nowhere else
[ ] No clinical advice patterns
WIRING
[ ] Refill CTA -> build sheet refill portal URL
[ ] Transfer CTA -> build sheet transfer destination (no PHI form)
[ ] Patient Portal CTA -> build sheet portal URL
[ ] Head JS snippet present verbatim in <head>
[ ] GA ID wired
[ ] Brand color from build sheet drives accents
RESULT
[ ] All three validators PASS
```

Replit Agent cannot declare the build complete without producing this filled-in checklist in `/build/log.md`. Any unchecked box = build not done.

## What this spec does NOT cover (out of scope for SKILL.md itself)

- The implementation of the three validator scripts (`validate-content.mjs`, `validate-a11y.mjs`, `validate-schema.mjs`). The skill prescribes their contract; implementation belongs to the plan that follows this spec.
- The implementation of `tools/scrape.mjs`. Same — contract here, implementation in the plan.
- A reference implementation of an output build (i.e., an actual generated pharmacy site). Out of scope; the skill is the artifact.
- Deployment to Replit, GoDaddy, etc. Out of scope.
- A UI for invoking the skill. Operator pastes/references the SKILL.md directly.

## Next step

Hand off to `superpowers:writing-plans` to produce an implementation plan for the `SKILL.md` itself and the prescribed tooling.
