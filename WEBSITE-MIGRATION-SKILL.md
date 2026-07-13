---
name: website-migration
description: Migrate or rebuild an existing pharmacy website onto a modern, accessible, factually faithful stack. Use when the user asks to "migrate a pharmacy site," "rebuild a pharmacy website," "port the existing pharmacy site," "modernize [pharmacy]'s website," "website migration," or "site rebuild." The input is an **input folder produced upstream by Replit** containing a `manifest.json` (structured extraction of pharmacy facts + per-page records) and a `scraped/` directory (raw HTML, reader-mode text, and downloaded assets from the pharmacy's existing live site). There is no jotform build sheet and no separate logo file — the scraped manifest is the sole source of pharmacy facts. Same output contract as the pharmacy-builder skill (required pages, WCAG 2.2 AA accessibility, SEO + JSON-LD schema, voice and PHI guardrails, `size-report.json`, etc.), and the §Content variation policy is skipped for rebuilds. Stack-agnostic — the agent picks the framework. This skill and the pharmacy-builder skill share the same body from `## Required pages` onward, byte-identical; only the frontmatter, H1, §Inputs, and §Scrape sections differ so the input contract fits the pre-scraped migration flow.
---

# Website Migration Skill

## Inputs

You are given a path to an input folder. The folder contains a scraped manifest and the mirrored assets of the pharmacy's existing live website, produced upstream by Replit **before this skill runs**. This skill consumes the scrape — it does not re-crawl the source site, and there is no build sheet or separate logo file to parse.

### Input folder layout

| File / Path | Required? | Purpose |
|---|---|---|
| `manifest.json` | **Required** | Structured extraction of pharmacy facts plus a per-page record for every crawled URL |
| `scraped/raw/*.html` | **Required** | Raw HTML of every crawled source-site page |
| `scraped/text/*.md` | **Required** | Reader-mode markdown extraction of every crawled page (for LLM consumption) |
| `scraped/assets/**` | **Required** | Downloaded images, PDFs, videos, and the pharmacy's logo — every binary the source site referenced |

Hard fail if `manifest.json` is missing or unreadable. Log and continue if an individual asset referenced by the manifest is missing from `scraped/assets/` — the corresponding image slot on the new site falls back per §Image policy.

### Manifest fields to extract

The manifest is the single source of truth for pharmacy facts. Extract every field listed below into `build/context.json`. Mark absent fields `null` with a `nullReason`. Do not invent values.

- **Pharmacy name**
- **address** (street, city, state, ZIP)
- **hours** (all open days and times, as extracted from the source site)
- **phone**
- **fax**
- **email**
- **Original URL** (the pharmacy's existing live site — recorded in `sameAs` and internal provenance)
- **New URL** (the target base URL for the rebuild; canonical for the new site)
- **Google Map URL**
- **refill portal** URL
- **Patient Portal URL** (wired to the Patient Portal CTA across the site; if absent, the Patient Portal CTA is omitted from the sticky header per §Section omission rule — never invent or substitute another URL)
- **Transfer destination URL** (the outbound URL the `/transfer/` CTA links to when the source site exposes a transfer flow; never collect PHI on the new site itself)
- **App Store URL** and **Google Play URL** (paired signal — both present means "has native app"; both absent means no `/app/` page is built)
- **GA ID** (Google Analytics measurement ID)
- **head JS** snippet (verbatim; wired into `<head>` during generation)
- **brand color** (hex value; inferred from the source site's primary color if a canonical hex was not published on the source)
- **Logo** (path within `scraped/assets/` — the scraped logo is used verbatim; never regenerate, retint, or replace)
- **services topics** (services identified on the source site as deeper-treatment; each gets its own page)
- **services list** (services identified as shallow-card; listed on the services index only)
- **Per-service description copy** for each Topic entry (extracted from the source site's per-service pages, subject to §Factual guardrails and §Voice)
- **immunization options** (list exactly as extracted; never extend or supplement)
- **year opened**
- **tagline**
- **about** copy (extracted from the source site's About page, subject to §Factual guardrails and §Voice)
- **pickup methods** (drives `/refill/` copy)
- **Social links** (list of `sameAs` URLs from the source site's header/footer)
- **Reviews URL** (Google Business Profile review-submission URL, Yelp review URL, Healthgrades review URL, or equivalent — powers the home page "Leave a Review" CTA per §Required sections › Home only)
- **Additional locations** (list of location objects, each with name/address/hours/phone; may be empty)
- **App-vs-Portal directive** (optional free-text field in the manifest; resolves the App-vs-Patient-Portal rule when both options would otherwise apply)

Every field in `build/context.json` must carry a `provenance` annotation: either a source-site URL (from the manifest's per-page records) or the string `manifest` (for facts asserted at the manifest root). Absent fields must appear explicitly as `null` with a `nullReason` string — never omit them silently.

### Conditional flags

Respect the following conditions exactly; do not activate conditional pages or features without a matching signal in the manifest:

- **App Store URL AND Google Play URL both present** → build the `/app/` page with real Apple App Store and Google Play badges wired to those URLs.
- **Refill portal URL present** → wire the Refill CTA to that URL across the site.
- **Transfer destination URL present** → wire the `/transfer/` page's CTA / outbound link to that URL. The `/transfer/` page itself is always built (see §Required pages); this signal controls its wiring, never its existence. Still no PHI form.
- **Non-empty `pickup methods`** → drive the copy on `/refill/` from that list.
- **Non-empty `Additional locations`** → build a `/locations/` index page plus a `/locations/<slug>/` page per location.

### Content variation policy — not applicable

The §Content variation policy in the shared body applies **only** to jotform-driven new builds (`Build origin: new`). For migration/rebuild, the source site is the authoritative source of copy — every field is treated as fully edited content and used verbatim, subject to §Factual guardrails, §PHI rules, §Banned phrasings, and §Voice. Skip §Content variation policy entirely; do not run an AI variation pass on any field.

### Provenance mapping for the shared body

The shared body of this skill (from §Required pages onward) is byte-identical to `SKILL.md` and references "the build sheet" and specific build-sheet field names throughout. In the migration flow, every such reference maps to the scraped manifest as follows:

| Shared-body reference | Migration equivalent |
|---|---|
| "the build sheet" | the manifest (`manifest.json`) |
| "the build-sheet `X:` field" | the manifest field `X` |
| "sourced from the build sheet or scrape" | sourced from the manifest / scraped text corpus |
| "the build sheet supplies…" | the manifest supplies… |
| "the build-sheet directive in Additional Site Notes" | the App-vs-Portal directive in the manifest |
| "`Requires Mobile App Page: Yes`" | App Store URL AND Google Play URL both present in the manifest |
| "`Requires transfer form page`" | Transfer destination URL present in the manifest |
| "`Additional locations: Yes`" | non-empty `Additional locations` array in the manifest |
| "`New Website URL`" (canonical base) | the manifest field `New URL` |
| "`Website URL`" (existing live site) | the manifest field `Original URL` |

Every other rule in the shared body — §Factual guardrails, §PHI rules, §Banned phrasings, §Voice, §Accessibility, §SEO, §Schema, section omission when a field is absent — applies identically to the migration flow. Only the source of each field changes.

### Output of this step

Write a single `build/context.json` that consolidates every parsed manifest field. Each field must carry its `provenance` annotation. Absent fields must appear explicitly as `null` with a `nullReason` string. This file is the single source of truth that all later steps quote from.

## Scrape

### Goal

The scrape is done upstream by Replit before this skill runs. Its output is the `manifest.json` + `scraped/` folder described in §Inputs. This skill's job is to **consume the scrape as a fact source** — not to re-crawl the source site.

### Consumption rules

- **Fact source only.** The manifest plus the reader-mode text extractions in `scraped/text/` are the sole source of pharmacy facts. Every fact used on the new site must appear in the manifest or be verifiably present in the scraped text. No external lookups — no geocoding APIs, no Google Places API, no third-party enrichment.
- **Pharmacy imagery classification.** The manifest classifies every captured image as `interior`, `exterior`, `team`, `product`, `logo`, or `other`. These classifications drive §Image policy's sourcing priority and the "exterior shots must be real" rule.
- **PDFs** captured to `scraped/assets/` (forms, brochures) may be linked from the new site when relevant.
- **Storefront, team, and product images** may be used with generated alt text.

### Disallowed uses

- **Fabrication when a field is absent.** If a fact is not in the manifest and not verifiable from `scraped/text/`, mark it `null` and log to `/build/log.md` — never invent.
- **Carrying over PHI** (patient testimonials with full names paired with conditions, Rx numbers, DOB, etc.) — redact per §PHI rules.
- **Carrying over marketing hyperbole, comparative claims, clinical claims, or unverified credentials** — filter per §Banned phrasings and §Factual guardrails.

### Failure handling

- **`manifest.json` missing or unreadable** → hard fail with an actionable error before scaffolding anything.
- **Manifest schema invalid** (required root fields missing — pharmacy name, address, hours, phone) → hard fail; log which fields are missing to stderr and exit non-zero.
- **Individual asset missing from `scraped/assets/`** → log the missing asset to `/build/log.md` and continue; the corresponding image slot on the new site falls back per §Image policy.

There is no silent fallback — every skipped or missing input is logged explicitly so downstream steps know what was substituted.

## Required pages

### Always-built pages

Every build must produce the following nine pages regardless of build-sheet flags:

| URL | Page | Purpose |
|---|---|---|
| `/` | Home | Hero, tagline, services grid, hours, trust callouts, testimonials, CTAs |
| `/about/` | About | Pharmacy story, year opened, tagline, independence |
| `/contact/` | Contact | Address, hours, phone, fax, email, map embed, directions link |
| `/services/` | Services index | Cards for every service (Topics deep + List shallow) |
| `/services/<slug>/` | Per-service detail | One page per "Topics" entry; deep treatment with copy |
| `/refill/` | Refill | Refill portal CTA wired to build-sheet URL; pickup methods copy |
| `/transfer/` | Transfer | CTA + outbound link only — no PHI form |
| `/faq/` | FAQ | Site-wide FAQs (expandable accordion); FAQPage JSON-LD schema |
| `/privacy/` | Privacy | Notice of Privacy Practices (HIPAA-required) |

**`/privacy/` page requirements (HIPAA Notice of Privacy Practices):**

- Heading "Notice of Privacy Practices" (exactly this phrase, as `<h1>`).
- Effective date, sourced from build sheet or set to the build date.
- Pharmacy's Privacy Officer name (or "Privacy Contact") + phone + email — sourced from build sheet only; if absent, omit the name and use the pharmacy's main phone + email.
- Sections covering: how PHI is used and disclosed (treatment, payment, healthcare operations); patient rights (inspect/copy record, request amendments, request restrictions, accounting of disclosures, confidential communications, file a complaint); pharmacy's right to amend the notice and how patients will be notified; how to file a complaint with the pharmacy AND with the U.S. Department of Health and Human Services Office for Civil Rights.
- A working link to `https://www.hhs.gov/ocr/privacy/hipaa/complaints/` (verify HTTP 200 from the build environment if reachable; otherwise log the link as unverified to `/build/log.md`).
- Plain language per §Voice — no banned phrasings.
- Linked from the footer of every page with visible text containing "Privacy Policy" or "Notice of Privacy Practices."

> **Transfer page is CTA + outbound link only — no PHI form.** Do not add any form that collects patient health information on the `/transfer/` page.

**Per-service page depth:**
- **Topics entries** → deep treatment: full descriptive copy, benefits list, JSON-LD, internal links.
- **List entries** → shallow card only on the `/services/` index; no dedicated detail page.

### Conditionally built pages

| Condition | Pages built |
|---|---|
| `Requires Mobile App Page: Yes` | `/app/` — includes real Apple App Store badge and Google Play badge (correct artwork per each store's brand guidelines) |
| `Additional locations: Yes` | `/locations/` index + `/locations/<slug>/` per location |
| Scrape-discovered page with ≥ 150 substantive words, not a contact/hours rehash | `/<slug>/` — one page per qualifying scrape discovery |

**Scrape-discovery rule:** include a scraped page only when it contains at least 150 substantive words AND its content is not a rehash of the contact page or hours information. Drop it otherwise.

## Required sections

### Every page

Every page carries four structural zones in this order: top bar, sticky header, page body, footer.

**Top bar** — a slim bar above the header. Display the pharmacy address, phone number, and hours summary. Include an open-now indicator: derive the pharmacy's IANA timezone (e.g., `America/Los_Angeles`) from the build-sheet address (city and state) — not from the visitor's browser. Use `Intl.DateTimeFormat` with that explicit `timeZone` argument to convert `Date.now()` into the pharmacy's local time, then compare against the open hours parsed from the build-sheet `Hours:` field. Never use the visitor's browser timezone as a proxy for the pharmacy's time, and never hard-code UTC offsets. If JavaScript is disabled the indicator falls back to the text "Open/Closed unavailable" — it never invents a status it cannot confirm.

**Sticky header** — fixed to the top of the viewport on scroll. Contains: logo (linked to `/` — this IS the home link, so the primary nav never includes a separate "Home" item), primary nav (About, Services dropdown, Contact, FAQ — never "Home"), and three primary CTAs. The third CTA is determined by the App-vs-Portal rule below; the order is always Refill, Transfer, then either Mobile App or Patient Portal. The header never wraps to a second row at desktop widths. **The header collapses to a mobile menu below the `1024px` breakpoint (Tailwind `lg`) — see §Required sections › Mobile navigation for the drawer contract.**

**App vs Patient Portal — pick exactly one (never both).** The build sheet drives the choice. Apply this rule across the entire site (sticky header CTA, mobile drawer CTA, sticky bottom mobile CTA bar, footer, llms.txt, schema):

- If `Requires Mobile App Page: Yes` → the third CTA is "Get the App" linking to `/app/`. The site does NOT surface a Patient Portal CTA anywhere, even if a `Patient Portal URL` is present in the build sheet (the field is recorded in context.json but unused for CTA wiring). The `/app/` page is built.
- If `Requires Mobile App Page: No` AND `Patient Portal URL` is present → the third CTA is "Patient Portal" linking to that URL. The `/app/` page is NOT built and Apple/Google badges do NOT appear anywhere.
- If both `Requires Mobile App Page: Yes` AND the build sheet contains an explicit "show portal" or "show app" directive in the Additional Site Notes / Instructions field → follow the build-sheet directive verbatim; log the resolution to `/build/log.md`.
- If neither is provided → the site has only Refill + Transfer CTAs; no third CTA is invented. Log the omission.

**Logo specification.**

- **Format:** SVG preferred (scales without loss). PNG with transparent background acceptable. JPG only if no transparent-background source exists; place against a brand-color or white background.
- **Header logo:** rendered at minimum 32px tall and maximum 64px tall, scaled proportionally. If the supplied logo is below 32px even at its native size, scale up with crisp rendering (`image-rendering: -webkit-optimize-contrast`) and log a quality warning.
- **Footer logo:** ALWAYS renders on every page. Minimum 24px tall, maximum 48px tall. Footer logo must never be omitted, even when the page is content-sparse. If the logo image fails to load (404, broken file), the footer falls back to the pharmacy name rendered in the brand color at the same baseline size — never an empty placeholder.
- **Alt text:** matches the §Accessibility pattern `<Pharmacy Name> logo`.
- **Brand-color preservation:** never recolor or filter the logo. If the build sheet supplies a single logo file that doesn't work against the chosen header/footer background, request a variant or use the supplied logo with a thin padded container — do not tint or invert the artwork.

**Footer** — contains: pharmacy logo (always renders per the Logo specification above), full address, phone, fax, email, business hours, social links (only if scraped or present in build sheet), NPI and license numbers (only if found in source material — never fabricated), copyright line, accessibility statement link, privacy policy link, and a sitemap link. Omit any footer field whose value is not available in the build context, EXCEPT the logo, which always renders (falling back to the pharmacy name in brand color if the image fails).

**FAQs** — every page includes a FAQ section near the bottom, scoped to the page's topic, drawn from the build sheet and scrape corpus. Include a `FAQPage` JSON-LD block for each FAQ section — see §Schema (JSON-LD).

### Home only

The home page body contains the following sections in order:

1. **Hero** — full-width banner using the build-sheet tagline and a primary CTA (Refill or Transfer, whichever is primary per the build sheet). **The hero image must depict a pharmacist serving a patient** — a person in a pharmacist's coat handing a prescription bag, counseling a patient at the counter, administering an immunization, or a similar trust-building, patient-centered scene. Background image sourcing follows §Image policy: real photo from the build folder or scrape preferred; if none, an AI-generated representative image is acceptable (because it is a generic patient-care scene, not an exterior shot). Never use a generic "happy stock person" photo, a pile of pills, or an exterior storefront in the hero.
2. **Services grid** — card grid for every service (Topics + List). Each card has its own icon drawn from a single coherent icon set, line style, approximately 24×24 px, single-stroke, and recolorable via `currentColor`. The same icon set is reused in the header services dropdown — never mix sets.
3. **Hours of operation** — a semantic `<table>` listing every open day and its hours. Format hours as `9:00 AM – 5:00 PM` (12-hour clock with leading zeros on minutes, uppercase `AM`/`PM` with no periods, en-dash or hyphen separator surrounded by single spaces). Never abbreviate to `9 AM – 5 PM`, never use `a.m.` / `p.m.` with periods, never use 24-hour format. Closed days render as "Closed" — not blank or "—".
4. **Trust callouts** — brief value statements (locally owned, years in business, etc.). No comparative claims ("best," "only," "most").
5. **Reviews** — 3 to 6 review cards sourced from Google Reviews, Yelp, Healthgrades, or the build sheet's review-platform field. Each card shows the reviewer's first name + last initial (e.g., "Maria S."), star rating (only if real), date if present, and the review text. Card style is consistent with the visual design. Below the cards, render a CTA **"Leave a Review"** linking to the pharmacy's Google Business Profile / Yelp / Healthgrades review-submission URL (sourced from the build sheet's `Reviews URL` / `Google Review URL` field). If no review-platform URL is in the build sheet, the CTA falls back to "Call us at `<phone>` to share your experience" linking via `tel:`. If no real review data exists, omit the cards but keep the "Leave a Review" CTA — never fabricate reviews.
6. **Testimonials** — short patient or customer quotes from the build sheet or scrape (distinct from platform-sourced reviews). Each is a `<blockquote>` with `<cite>` for attribution. First name + last initial only. Omitted if no source material exists — never fabricated. Redact any PHI.
7. **App download row** — only if `Requires Mobile App Page: Yes` is set in the build sheet AND the App-vs-Portal rule selects the app. Include real Apple App Store and Google Play badges wired to the URLs from the build sheet. If the App-vs-Portal rule selected Patient Portal, this row is omitted entirely.

### Contact only

The contact page body contains:

- Clickable address (links to the Google Maps entry), clickable phone, fax, and email.
- Map embed: construct the embed URL from the build sheet `Google Map URL` field. Render a "Get directions" link that opens the Google Maps URL in a new tab (`target="_blank" rel="noopener noreferrer"`).
- **No contact form by default.** The contact page does not collect any patient data. Do not add a form, even a "name + email + message" form, unless the build sheet explicitly requests one with a non-PHI purpose (e.g., a B2B vendor inquiry form). When the build sheet does request one, the form must satisfy: no PHI fields (no DOB, Rx number, medications, conditions, MRN, member ID); a visible HIPAA disclaimer above the submit control with the exact text "Do not submit Protected Health Information through this form. For prescription transfers, refills, or anything involving your medications, call us at `<phone>`."; bot protection (hCaptcha / reCAPTCHA / Cloudflare Turnstile invisible or honeypot); accessible labels per §Accessibility.
- Full hours of operation table (same as home, same `9:00 AM – 5:00 PM` format).
- FAQs scoped to location and access questions.

### Per-service page

Each per-service detail page (one per Topics entry) follows this structure:

- **H1 = service name** — exactly as written in the build sheet Topics list; do not rename or abbreviate.
- **A header image is required on every service page.** Image sourcing priority per §Image policy: 1) build folder image whose filename references the service; 2) scraped image classified as relevant to the service; 3) AI-generated representative image (interior/clinical/product scenes only — never an exterior shot); 4) stock photo from Unsplash, downloaded locally per §Image policy. Image is displayed at the top of the page above the H1 or as a hero band behind the H1, with object-fit cover, accessible alt text describing the service action (e.g., "Pharmacist administering a flu shot").
- Verbatim build-sheet description copy followed by any additional detail sourced from the scrape.
- For the Immunizations service: include a list labeled **Immunization Options** reproducing the build sheet `immunization options` field exactly — never extend or supplement this list with vaccines not explicitly listed in the build sheet.
- A CTA appropriate to the service (e.g., "Schedule Now," "Request a Refill") — wire to the correct portal URL.
- FAQs scoped to that service's topic.

### Image policy

Every page must use real-looking, brand-appropriate imagery. The site never ships with empty image placeholders, broken images, or obviously generic stock-photo clichés.

**Sourcing priority (apply in order; use the first source that produces a usable image):**

1. **Build folder.** Any image file in the build folder whose name or context references the page's subject.
2. **Scrape.** Images captured during §Scrape from the pharmacy's existing live site or its Google Business Profile / Maps listing (when reachable from the build-sheet `Google Map URL`). Real interior, staff, and exterior photos take priority over generic banner art.
3. **AI-generated.** Acceptable for representative scenes (pharmacist counseling a patient, a hand passing a prescription, an immunization shot, an interior counter view) — **never** for an exterior storefront of THIS pharmacy, which is misleading. When an AI image is used, log the prompt and the model to `/build/log.md` so the image's provenance is auditable.
4. **Unsplash (stock).** Acceptable as the last fallback for service pages and supporting imagery. **Download every Unsplash image locally** — do not hotlink. Save the file under `public/images/stock/<slug>.<ext>` (or the project's static directory) and reference the local path. Per Unsplash license, include the photographer attribution either in the page footer ("Photo by `<photographer>` on Unsplash") or in the image's `alt` / `figcaption` if used in editorial context. Never use Unsplash images of identifiable individuals as if they were the pharmacy's staff.

**Hard rules across all sources:**

- **Hero on the home page must depict a pharmacist serving a patient.** Not a pile of pills, not an empty pharmacy interior, not a generic "happy senior couple," not the storefront. The hero is the trust-establishing image of the whole site.
- **Exterior shots must be real.** If the page or section uses an exterior shot of the pharmacy, it must come from the build folder or the scrape — never AI-generated, never stock. An AI-generated or stock "exterior" of a fictional pharmacy misrepresents the actual location.
- **No image-only text** for substantive content (per §Accessibility).
- **Alt text** follows the object + context pattern (per §Accessibility) and describes the scene, not the source ("Pharmacist counseling a patient at the pharmacy counter" — not "Stock photo of a pharmacist").
- **File format and weight:** AVIF or WebP preferred with a JPG fallback; ≤ 200 KB per hero image, ≤ 100 KB per service-page header image. Explicit `width` and `height` to prevent layout shift (per §Visual design responsive constraint).
- **Catalog every image** the build uses, with its source (`build_folder | scrape | ai_generated | unsplash`), local path, alt text, and (for Unsplash) the photographer credit, to `/build/image-manifest.json`. This is the audit trail.

### Iconography rule

Use one coherent icon set across the entire site (e.g., Lucide, Heroicons, or Phosphor). Pick one set and commit to it. The same icon set appears in the services grid cards and the header services dropdown — never mix two icon families. All icons must be rendered at a consistent size (approximately 24×24 px), use a single-stroke line style, and accept brand-color theming via `currentColor` so they inherit the text color of their container without hardcoded fill values.

### Cookie consent banner (external drop-in)

**Not built by this skill.** The operator provides a drop-in cookie consent widget — external code loaded via a `<script>` tag or a small HTML snippet. The builder does NOT generate a banner, does NOT wire consent gating around analytics, and does NOT persist consent state. Those concerns belong to the drop-in widget.

**Required in the base template:** leave a clear insertion point so the operator can drop the widget in without hunting through markup. Choose ONE of:

- An empty mount element immediately before `</body>`: `<div id="cookie-consent-mount"></div>` with a comment `<!-- Operator: replace or hydrate this element with your cookie consent widget. Loading order matters — do not defer this below the fold. -->`
- OR a documented placeholder comment in `<head>`: `<!-- COOKIE_CONSENT_SCRIPT: operator injects their consent widget script here -->`

Log which convention was chosen to `/build/log.md`. Do not block the build if the placeholder is empty — that's the operator's responsibility to fill.

**Analytics wiring in the presence of external consent.** Because the widget owns consent state, wire the build-sheet `head JS snippet` and `GA ID` such that the widget's `window.dataLayer` or equivalent consent-mode API can gate them. When Google Consent Mode v2 is in use (common with drop-in widgets), set the default consent state to `denied` for analytics/ad storage in the initial `gtag('consent', 'default', ...)` call, and let the widget flip it to `granted` on user acceptance. Do not hard-code `granted` — that defeats the widget.

No newsletter pop-ups, no exit-intent modals, no promotional interstitials — see §Conversion. The cookie widget is the only banner-style overlay allowed.

### Mobile navigation

Below the `1024px` breakpoint (Tailwind `lg`), the sticky header collapses to a mobile menu. The header itself still shows: logo, click-to-call phone link, and the hamburger trigger — nothing else. The open-now indicator and full phone number remain in the top bar above the header so the "Call us" path is one tap from any screen.

Drawer contract:

- **Trigger.** A hamburger button (three lines, no labels needed visually but `aria-label="Open menu"`) in the top-right of the header. Tap target ≥ 44×44 CSS pixels. The button has `aria-expanded="true|false"` reflecting drawer state and `aria-controls` pointing to the drawer's `id`. When the drawer is open, change the label to `aria-label="Close menu"`.
- **Drawer element.** `role="dialog"`, `aria-modal="true"`, `aria-labelledby` pointing to the drawer's heading. Slides in from the right; full-width on phones (< 640px), 360–420px wide panel on small tablets.
- **Backdrop.** Semi-transparent backdrop (≈ 50% opacity) behind the drawer. Tapping the backdrop closes the drawer. Backdrop has `aria-hidden="true"`.
- **Contents, in this order:**
  1. A close button (X icon, `aria-label="Close menu"`, ≥ 44×44 tap target) as the **first focusable element** in the drawer.
  2. Logo and pharmacy name (linked to `/`).
  3. Primary nav links (About, Contact, FAQ — **never "Home"**; the logo at the top of the drawer is the home link). Each link is a full-width row, ≥ 48px tall, with 12px+ vertical padding for comfortable tap targets.
  4. Services subnav as an **expandable disclosure group** (a heading "Services" + a button that toggles a nested list with `aria-expanded`) — NEVER a hover dropdown. Each service is a full-width row.
  5. The three primary CTAs (Refill, Transfer, and then EITHER "Get the App" linking to `/app/` OR "Patient Portal" linking to the portal URL — never both, per the App-vs-Portal rule above) styled as full-width filled buttons stacked vertically with 8–12px spacing between.
  6. Click-to-call phone CTA: `<a href="tel:+1<10digits>">Call (XXX) XXX-XXXX</a>` styled as a full-width outlined button.
  7. Hours summary block (today's hours, the open-now indicator state).
- **Focus management.** When the drawer opens, focus moves to the close button. Tab cycles within the drawer (focus trap — implement with a sentinel or a focus-trap library). Esc closes the drawer and returns focus to the hamburger.
- **Body scroll lock.** When the drawer is open, set `overflow: hidden` on `<body>` and `<html>` so background content doesn't scroll. Also handle iOS rubber-band by setting `position: fixed; width: 100%; top: -<scrollY>px` then restoring on close. Restore the previous scroll position on close.
- **Animation.** Slide-in 200ms `ease-out`, backdrop fade 150ms. If `prefers-reduced-motion: reduce` is set, skip the animation and toggle visibility instantly.
- **Anti-patterns banned.** No `:hover`-only interactions (touch devices have no hover). No nested multi-level dropdowns. No drawer that doesn't trap focus. No drawer that lets background scroll. No drawer without a backdrop. No drawer that doesn't close on Esc or on backdrop tap.

### Section omission rule

Any required section whose content cannot be sourced from the build sheet, supporting docs, or scrape corpus is omitted, not stubbed. Do not insert placeholder text. Specifically:

- No "Lorem ipsum" — never use filler Latin text.
- No "Coming soon" — never stub a section with a coming-soon notice.
- No fake content of any kind. If the data isn't there, the section isn't there.

## Conversion

This is a high-trust, local-action site. Patients convert by calling, walking in, refilling, or transferring — rarely by submitting forms (which we don't collect anyway). The design must make those actions immediate and obvious on every screen size.

### Primary actions

The patient actions, in priority order:

1. **Call** — a `tel:` link with the visible phone number in the top bar, in the mobile menu drawer, in the footer, and on the contact page. On mobile, calling outranks every other action.
2. **Refill** — primary CTA in the home hero, primary CTA on every service page where refilling is in scope, and one of the three sticky-header CTAs site-wide.
3. **Transfer** — secondary CTA in the home hero and present in the sticky header. Outbound link only (no PHI form per §PHI rules).
4. **Mobile App OR Patient Portal** (exactly one — see §Required sections › Sticky header › App vs Patient Portal). Present in the sticky header but visually secondary; useful for returning patients, not for first-time acquisition. The site never surfaces both; the build sheet determines which one renders.

### Above-the-fold (mobile and desktop)

A first-time visitor on a phone must see **without scrolling**: pharmacy name, tagline, one primary CTA (Refill), a click-to-call link with the visible phone number, and the "Open now" / "Closed" indicator. If any of these are missing above the fold, the hero is failing — revise.

### Sticky bottom CTA bar (mobile only)

On screens narrower than `1024px`, render a sticky bottom bar 60–72px tall containing **two equal-width buttons**: "Call" (`tel:` link to the build-sheet phone) and "Refill" (links to the refill portal URL). Rules:

- Appears once the user has scrolled past the hero (use `IntersectionObserver` watching the hero element).
- Hidden when the mobile menu drawer is open.
- Respects `safe-area-inset-bottom` on iOS (use `env(safe-area-inset-bottom)` in CSS padding).
- Backdrop-blurred or solid background with sufficient contrast against the page content beneath.
- Each button is ≥ 44×44 tap target with a clear icon + label.
- Hidden entirely on desktop (≥ 1024px) — desktop users have the sticky header.

### Trust signals (above the fold or in the first viewport of scroll)

Render all of these where the visitor can see them without effort:

- "Open now" / "Closed" indicator (live, computed per §Required sections › Top bar).
- Visible phone number with `tel:` link.
- Address line linked to the Google Maps URL ("Get directions").
- Independence / years-in-business callout — only if sourced from build sheet (e.g., "Independent pharmacy serving the community since 2022"). Omit if not sourced.
- One testimonial or rating callout if real review data exists in build sheet or scrape. Never fabricate.

### Testimonials placement

Testimonials live in their own home-page section between Services and FAQ. Use first name + last initial only (e.g., "Maria S.") — never include condition, medication, Rx number, or any other PHI. Each testimonial is a `<blockquote>` with `<cite>` for the attribution. Emit `Review` JSON-LD nested inside the `Pharmacy` node ONLY if the source confirms a rating value; otherwise omit ratings. Never fabricate stars, never round up.

### Click-to-call wiring

Every visible phone number on the site is wrapped in `<a href="tel:+1<10digits>">…</a>`. The `+1` country code prefix is required for reliable iOS handling. Strip formatting from the `href` only; keep formatting in the visible text:

```html
<a href="tel:+19515551234">(951) 555-1234</a>
```

Every email is wrapped in `<a href="mailto:…">…</a>`. Every address is linked to the Google Maps URL from the build sheet.

### CTA copy rules

Every CTA names the action. Banned labels: "Click here," "Learn more," "Submit," "Continue." Required pattern: verb + object.

- ✓ "Refill a prescription"
- ✓ "Transfer your prescription"
- ✓ "Call us today"
- ✓ "Get directions"
- ✗ "Click here"
- ✗ "Learn more"

### Local SEO conversion signals

- Embed the Google Map on the contact page (already required) AND link the top-bar address to the same map URL.
- `LocalBusiness` / `Pharmacy` schema includes `geo` only if scraped/sourced (no external geocoding per §Schema). `openingHoursSpecification` is parsed from build-sheet hours.
- Add `aggregateRating` to the `Pharmacy` node only if the build sheet or scrape contains real, verifiable review data. Never invent ratings.

### Anti-patterns (banned, enforced by content validator)

- Pop-up newsletter signups, exit-intent modals, interstitials of any kind on first-page load.
- Auto-play video or audio.
- Cookie banners that block scrolling or that block content interaction. If a banner is legally required, render a compact dismissible bottom notice that does not modal-block the page.
- "Limited time" / fake-scarcity language (also caught by §Banned phrasings).
- Phone numbers rendered as plain text (no `tel:` link).
- Email addresses rendered as plain text (no `mailto:` link).
- CTA labels that don't name the action (see CTA copy rules).
- Carousel hero on mobile (one hero message, no rotation — rotating heroes destroy mobile conversion).

## Visual design

The site must look professional, modern, and trustworthy. The skill is stack-agnostic, but the **recommended stack for cost and speed is React + Tailwind + shadcn/ui via the shadcn MCP**. Do not invoke external design-agent skills — the constraints below plus the shadcn component library produce a professional result in a single generation pass. No design review pass is required beyond the §Accessibility and content validators.

**Style direction.** Clean, modern, professional. Prefer minimalism or flat design with subtle depth. On the home page a restrained bento grid layout is acceptable. Avoid brutalism, claymorphism, heavy neumorphism, and anything that reads "trendy" rather than "trustworthy."

**Design constraints — these are the whole contract. Any stylistic choice that violates one of them is wrong regardless of aesthetic preference.**

- **Brand color is canonical.** The hex from the build sheet is the primary accent. Neutral shades and one or two complementary accents are fine. If the brand hex cannot reach 4.5:1 against white for body text, body text falls back to `#111111` and the brand color stays accent-only per §Accessibility.
- **Accessibility, Voice, Required sections, Conversion, and PHI wins on conflict.** No visual choice overrides §Accessibility, §Voice, §Banned phrasings, §Required sections, §Conversion, or §PHI rules.
- **Iconography.** One coherent icon set (Lucide recommended for shadcn integration; Heroicons or Phosphor acceptable). Never mix families.
- **Typography.** A single well-supported font pairing — Inter as body and Inter or Poppins as display is a safe default. Body font-size ≥ 16px on mobile (iOS auto-zooms inputs below 16px). No ornamental display fonts for body content.
- **Responsive.** CSS must include a global `*, *::before, *::after { box-sizing: border-box; }` reset; at least one `@media` query (mobile-first breakpoints at 640px, 768px, 1024px, 1280px is a reasonable set); explicit `width` and `height` (or aspect-ratio) on every image; no horizontal scroll at 320px viewport.
- **Dark mode.** Ship only if the brand color can reach WCAG AA on a dark background. Otherwise ship light mode only and log the decision in `/build/log.md`. Never ship a degraded dark mode.

**Cost note.** Single-pass generation with the constraints above is the default. Do not schedule additional review or refinement rounds beyond the mandatory §Accessibility and content validators. If the operator explicitly requests a second design pass, log the request and iterate — but do not do so implicitly.

## Voice

- Write in plain language targeting an 8th-grade reading level. Target a Flesch-Kincaid readability score of ≥ 70.
- Use short sentences. Active voice only — never passive construction when active is possible.
- Second person throughout: address the patient as "you" ("you can get your refill"), never third person ("patients can…").
- Warm but not casual. Friendly, not flippant. Professional tone that reassures; never breezy, sarcastic, or colloquial.
- Practical: tell the patient what to do, where to go, and what to expect. Every paragraph should answer one of: what is this, how do I get it, what happens next.
- local-color claims — community, neighborhood, family-owned, independent — are allowed only if backed by the build sheet or scrape corpus. Apply the same test to every local-color claim: if there is no source, omit the claim.

## Content variation policy

This policy applies only to **new builds** (`Build origin: new` — operator submitted a jotform build sheet). **Rebuilds** (`Build origin: rebuild` — input is a scrape of an existing live site) skip this policy entirely; the live site is the source of truth and is treated as fully edited content.

**The problem this solves.** The jotform build sheet ships with default template text in the About, Hero tagline, per-service description, and FAQ fields. Many operators submit without customizing those defaults. If the agent uses the default text verbatim across multiple pharmacies, every site reads identically — bad for SEO (duplicate-content penalties), bad for trust (the copy doesn't sound like the pharmacy), and bad for the operator.

### Detecting edited vs unedited content

For each section field, treat the content as **unedited (default)** when ANY of these is true:

- The build sheet's section-specific edited flag is set to `no` (`About content edited: No`, `Hero tagline edited: No`, etc.).
- The section-specific flag is absent AND the global `Content edited (overall)` flag is `no`.
- All flags are absent AND the submitted text exactly matches a known jotform default-template phrase (the agent maintains a small list of known defaults in `tools/default-templates.json` for comparison — every phrase added to the jotform default text should be appended here).

Treat as **edited (operator-written)** otherwise — including when the operator wrote text that is similar but not identical to a default template phrase. When in doubt, default to edited.

### Behavior

- **Edited content:** use verbatim. Do not paraphrase, do not "improve" the prose. Pass through `tools/validate-content.mjs` for guardrails (banned phrasings, PHI, clinical advice, factual fabrication) and §Voice (readability target). Operator-written content that fails validation is logged to `/build/log.md` and the operator is asked to revise — never silently rewrite operator copy.
- **Unedited content (use AI variation):** pass the default source text plus the build sheet's facts (pharmacy name, city, services, hours, year opened, etc.) to an AI variation step. The variation produces unique, voice-compliant copy for THIS pharmacy that satisfies every rule below.

### AI variation rules

A generated variation MUST satisfy ALL of:

- **Facts come from source only.** Every claim in the variation traces to the build sheet, supporting docs, or scrape — never invented. The variation may rephrase but not introduce new factual content.
- **Same factual content as the source.** Hours phrased per §Required sections › Home only › Hours of operation format, services list unchanged, year opened unchanged, immunization options unchanged.
- **§Voice rules:** plain language, 8th-grade reading level (Flesch-Kincaid ≥ 70), short active-voice sentences, second-person, warm-not-casual, practical.
- **§Banned phrasings:** zero hits.
- **§Factual guardrails:** no fabricated credentials, awards, service claims, comparative claims, clinical claims.
- **§PHI rules:** no PHI ever.
- **Length:** within ±20% of the default source length. The variation rephrases, it doesn't pad.
- **Uniqueness across pharmacies.** Maintain `.history/variation-hashes.json` at the repo root — a JSON object mapping SHA-256 hashes of published variations to the build identifier. Before publishing a variation, compute its hash and check the registry. If the hash exists, retry generation with a higher temperature or with a different lead sentence until the hash is unique. Add successful variations to the registry on completion.
- **Variation prompt template** (used by the AI variation step):

  > Rewrite the following pharmacy section for "<Pharmacy Name>" in "<City, State>". Keep all facts identical to the source. Use 8th-grade reading level, active voice, second person ("you"). Warm but not casual. No marketing hyperbole. No clinical advice. Output length: within ±20% of the source word count. Source: "<default text>". Pharmacy facts: <relevant fields from build/context.json>.

### Verification

Every AI-generated variation passes through `tools/validate-content.mjs` exactly like operator-written content. Variations are not exempt from any rule. Log the per-section source (`operator_edited | ai_variation_of_default | scrape_for_rebuild`) to `/build/log.md` AND to `build/content-provenance.json`.

### Audit trail

`build/content-provenance.json` records, per section: source label, the original default text (when AI-varied), the AI prompt used, the final published text, the SHA-256 hash of the published text, and the validate-content.mjs result. This file is the audit trail for "did this pharmacy's About copy come from them, an AI variation of a generic default, or a scrape of their existing site?" It also lets the QA auditor verify that the published text matches its declared provenance.

### Operator-visible disclosure

When the build completes with one or more AI variations, the build summary delivered to the operator names the affected sections explicitly: "About copy was AI-varied because no edits were detected; the variation is unique to your pharmacy. Review and adjust if desired." Never publish AI variations silently — the operator must know what was machine-written so they can edit.

## Banned phrasings

The phrases below are forbidden in all generated HTML and copy. They are grouped by category for reference. The same list is the grep corpus that `tools/validate-content.mjs` runs against every output file.

### Marketing hyperbole

- revolutionary
- world-class
- best-in-class
- cutting-edge
- state-of-the-art
- industry-leading
- premier
- award-winning
- voted #1
- top-rated

### Clinical / comparative claims

- proven to
- cures
- guarantees
- safest
- fastest
- unlike CVS
- you should take

### Operational overreach

- all insurance
- any insurance
- every insurance
- 24-hour
- 24/7
- same-day delivery
- free delivery

### Credentials

- board-certified
- PharmD
- RPh

### Verification mechanism

`tools/validate-content.mjs` scans all generated HTML after every build. If any banned phrase is found, the tool will fail build with a non-zero exit code and write line-numbered evidence to `/build/log.md` so the exact location of each violation is visible for review and correction.

**Conditional unlock:** a banned phrase is allowed only when its exact wording appears verbatim in the build sheet or scrape (e.g., "FREE local delivery" when a build sheet contains that exact phrase). In that case the phrase may be reproduced faithfully in the corresponding page copy; the validator must be configured to accept the specific override when triggered by the build sheet or scrape source text.

## Factual guardrails

The following fields must never be fabricated. They may only appear in generated output when their value is present in the build sheet, supporting docs, or verified scrape corpus:

- Hours
- address (street, city, state, ZIP)
- phone
- fax
- email
- Staff names
- credentials (degrees, certifications)
- residencies
- board certifications
- awards
- licenses
- NPI
- NCPDP
- DEA
- Services offered
- Insurance plans accepted
- Years in business
- refill / transfer / portal URLs
- Any legal claim

If a field is not in the build sheet or scrape, the corresponding section is omitted, not stubbed.

## PHI rules

The site must never collect, request, store, or output Protected Health Information (PHI).

**Prohibited on public forms.** The following data types are explicitly forbidden from appearing in any public-facing form field:

- Full names paired with medications or conditions
- Date of birth (DOB)
- Medical record numbers
- Rx numbers
- Diagnosis text
- Insurance member IDs

**Transfer page is CTA + outbound link only.** The `/transfer/` Transfer page must contain only a call-to-action button or link pointing to the pharmacy's transfer destination URL — no form fields requesting medication name, Rx number, DOB, or any other PHI. If the scraped source contains such a form, do not port it; replace with: "Call us at `<phone>` to transfer."

**Contact page has no form.** The `/contact/` page must not collect any patient data. It displays address, phone, fax, email, map embed, and hours — nothing else.

**PHI scanner.** As part of build validation, run a PHI scanner step that greps every generated HTML file for the following patterns and fails the build on any hit:

- `name="dob"`
- `name="rx_number"`
- `name="member_id"`
- `name="medication"`
- `name="mrn"` (medical record number)
- `name="diagnosis"`
- Any `<input` whose `type` attribute equals `"date"` (or `'date'`) and that appears inside a `<form>` element — implement this check via an HTML parser, not a raw grep, because attribute-order and quote-style variations defeat literal matching
- Bare `<form>` elements whose `action` does not point to a fully qualified external URL

**Clinical advice.** Never tell a patient what medication to take, when to stop taking a medication, or what a symptom means. For any emergency mention, use only the literal phrase: "Call 911 or go to the nearest emergency room." Nothing else is permitted as emergency copy. That phrase is the only allowed emergency copy block in any generated output.

## Accessibility (WCAG 2.2 AA)

Every generated site must satisfy WCAG 2.2 Level AA. The directives below are binding — Replit Agent must implement each one exactly.

### Structural

- Exactly one <h1> per page. The H1 is the page title; there is never more than one and never zero.
- Heading levels never skip — never skip heading levels. H1 → H2 → H3 in strict order; do not jump from H1 to H3.
- Use landmarks — wrap every page in `<header>`, `<nav>`, `<main>`, and `<footer>` landmark elements. Every page body lives inside `<main>`.
- Skip-link — the first focusable element on every page is a skip link: `<a href="#main-content" class="skip-link">Skip to main content</a>`. It is visually hidden until focused.
- Use real <button> and `<a>` elements for interactive controls. Never use <div onclick> or `<span onclick>` as a button substitute.
- Tab order must match the visual reading order. Do not use positive `tabindex` values.
- Esc closes any open dropdown or modal.
- Enter and Space both activate `<button>` elements.
- **Visible focus** — every interactive element shows a focus indicator that meets WCAG 2.2 Focus Appearance: a minimum `2px outline` in a color that achieves at least 3:1 contrast against the adjacent background.
- Never set `outline: none` without providing an equivalent custom focus indicator that meets the 2px / 3:1 requirement.
- A sticky header must not trap keyboard focus; Tab from the last header item moves into the page body, not back to the logo.

### Content

- Every `<img>` element must carry an `alt` attribute — always.
- Substantive images use the object + context pattern, e.g., `alt="Pharmacist counseling a patient at the pharmacy counter"`.
- Decorative images use `alt=""` (empty string, not omitted).
- **Logo alt** text must be set to the exact pattern `<Pharmacy Name> logo` where `<Pharmacy Name>` comes from the build sheet `Pharmacy name` field. Example: `alt="Riverside Pharmacy logo"`.
- Never use image-only text for substantive content (headings, CTAs, body copy must be real text, not images of text).
- Icons must carry `aria-hidden="true"` and must always have an adjacent visible text label. Never use an icon alone as the only label for a control.
- The root HTML element must include `lang="en"` at all times: `<html lang="en">`.

### Contrast

- Body text must achieve at minimum **4.5:1** contrast against its background.
- Large text (≥ 18 pt / 24 px, or ≥ 14 pt / 18.67 px bold) and focus indicators must achieve at minimum **3:1** contrast against their background.
- The pharmacy's brand color is used for accents, borders, and interactive highlights.
- If the brand color cannot reach a 4.5:1 contrast ratio against white for body text, body text falls back to `#111111` and the brand color is used as accent-only. The skill **auto-darkens** the brand color for accent use until the color reaches at least 3:1 contrast against its background, preserving hue.
- Run the contrast check script (`tools/validate-a11y.mjs`) as part of every build; it must pass before the site is considered complete.

### Open-now indicator a11y

- The open-now indicator in the top bar must convey status through a **text label AND color cue** — never by color-only.
- Wrap the indicator in a live region: `aria-live="polite"` so screen readers announce status changes without requiring a page reload.
- Examples of acceptable labels: "Open now" / "Closed" rendered in text alongside the color dot. The color dot alone is not sufficient.

Run `tools/validate-a11y.mjs` after every build. The validator checks: landmark presence, heading order (no skipped levels), alt attribute presence on all images, focus styles (outline ≥ 2px), contrast computation for body and large text, and keyboard reachability of the services dropdown via Tab and Enter/Esc.

## SEO

### Required `<head>` elements

Every generated page must include the following `<head>` elements.

**Title tag**

Use the pattern `<page> | <Pharmacy Name>` for all pages except the home page, which uses `<Pharmacy Name> | <Tagline>`. Titles must be ≤ 60 chars — exceeding this length causes search engines to truncate. If the source document `SEO_META_Tags_*.docx` supplies per-page titles, use them verbatim and skip the pattern entirely.

**Meta description**

Include `<meta name="description">` with content between 140 and 160 chars. Shorter copy wastes snippet space; longer copy is truncated. Descriptions must accurately reflect the page body and contain at least one call to action.

**Canonical URL**

Include `<link rel="canonical" href="...">` on every page. The root of each canonical href comes from the build sheet field `New Website URL`. Append the relative path for interior pages (e.g. `New Website URL` + `/services/compounding`).

**Heading hierarchy**

Each page must have exactly one `<h1>`. The `<h1>` text should closely match the `<title>` value (minus the brand suffix). Subheadings follow the normal H2 → H3 hierarchy from the Accessibility section.

**Open Graph tags**

Include the full Open Graph set on every page:

- `og:title` — same as `<title>` content
- `og:description` — same as meta description
- `og:url` — same as canonical href
- `og:type` — `website` for every page (do not use the legacy `business.business` value; modern OG parsers ignore or flag it)
- `og:image` — reference a 1200x630 PNG generated from the pharmacy logo, brand color background, and page title text

**Twitter card tags**

Include the minimal Twitter card set:

- `twitter:card` — set to `summary_large_image`
- `twitter:title` — same as `og:title`
- `twitter:description` — same as `og:description`
- `twitter:image` — same 1200x630 asset used for `og:image`

**Other required head tags**

- `<meta charset="UTF-8">` — must appear first inside `<head>`
- `<meta name="viewport" content="width=device-width, initial-scale=1">` — required for mobile rendering
- `<meta name="theme-color" content="...">` — set to the pharmacy brand color (hex)

### Security headers (server config)

The generated site must be served with these HTTP response headers on every HTML response. If the deployment target supports `_headers` (Netlify, Cloudflare Pages), `_redirects`, `vercel.json`, or `next.config.js` `headers()`, write the appropriate config file alongside the build output:

- `Strict-Transport-Security: max-age=63072000; includeSubDomains; preload` (2 years, includeSubDomains; submit to the HSTS preload list separately).
- `Content-Security-Policy: default-src 'self'; script-src 'self' 'unsafe-inline' https://www.googletagmanager.com https://www.google-analytics.com; style-src 'self' 'unsafe-inline' https://fonts.googleapis.com; font-src 'self' https://fonts.gstatic.com; img-src 'self' data: https:; frame-ancestors 'none'; base-uri 'self'; form-action 'self'` (adjust the GA / fonts hosts to match what's actually loaded; tighten by replacing `'unsafe-inline'` with nonces or hashes when feasible).
- `X-Content-Type-Options: nosniff`.
- `X-Frame-Options: SAMEORIGIN` (redundant with CSP `frame-ancestors` but required for older browsers).
- `Referrer-Policy: strict-origin-when-cross-origin`.
- `Permissions-Policy: camera=(), microphone=(), geolocation=(), payment=(), usb=(), magnetometer=(), gyroscope=(), accelerometer=()` (pharmacy site needs none of these — deny all).
- `Cache-Control: public, max-age=31536000, immutable` on hashed static assets; `Cache-Control: public, max-age=300, must-revalidate` on HTML pages.

For Replit Deployments static sites, write a `_headers` file at the project root. For other hosts, write the equivalent config and document the choice in `/build/log.md`.

### Performance budget

Every generated page must hit these Lighthouse-mobile targets (run Lighthouse against the rendered output during validation):

- Performance score ≥ 90 (target); ≥ 85 acceptable; < 80 is a build failure.
- Largest Contentful Paint (LCP) ≤ 2.5s.
- Cumulative Layout Shift (CLS) ≤ 0.1.
- First Contentful Paint (FCP) ≤ 1.8s.
- Speed Index ≤ 3.4s.
- Total Blocking Time (TBT) ≤ 200ms.
- Time to Interactive (TTI) ≤ 3.8s.

To hit these:

- Hero image: serve in AVIF or WebP with a JPG fallback, ≤ 200 KB, dimensions ≤ 1600×900, `loading="eager" fetchpriority="high"`.
- All other images: `loading="lazy"`, modern format with fallback, explicit `width` / `height`.
- Fonts: preload critical font; use `font-display: swap`; subset if possible.
- JavaScript: minimize and tree-shake; defer non-critical scripts; avoid render-blocking third parties above the fold.
- CSS: critical CSS inlined into `<head>` for the home page if practical; rest deferred.
- HTTP/2 or HTTP/3 enabled at the host; gzip or Brotli compression enabled.

If a page misses any threshold, the agent must iterate (compress images, defer scripts, etc.) before declaring the build done. Log the final Lighthouse scores per page to `/build/log.md`.

### Site-wide files

Generate the following files at the site root alongside `index.html`.

**`robots.txt`**

Plain text, UTF-8, **LF line endings (no CRLF), no BOM, no comments above directives.** One directive per line. Sitemap URL must be a fully qualified absolute URL. Write the file as exactly:

```
User-agent: *
Allow: /
Sitemap: <New Website URL>/sitemap.xml
```

Where `<New Website URL>` is the absolute base URL from the build sheet (no trailing slash before the `/sitemap.xml` suffix; the suffix carries its own slash). Do not include `Disallow:` rules (no path needs blocking by default). Do not include `Crawl-delay` (Google ignores it). Do not add custom directives for individual bots.

Validation: file exists at `/robots.txt`, MIME `text/plain; charset=utf-8`, contains exactly the `User-agent: *` / `Allow: /` / `Sitemap:` directives, no extra non-standard lines. The Sitemap URL must return HTTP 200 from a same-host fetch.

**`sitemap.xml`**

Emit a **valid XML 1.0 document** that parses cleanly and validates against the sitemaps.org schema. Common breakage modes — fix all before declaring done:

- XML declaration on **line 1** with no preceding whitespace and no BOM: `<?xml version="1.0" encoding="UTF-8"?>`
- Root element `<urlset>` with the **exact namespace attribute** `xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"`. No other attributes on the root.
- One `<url>` element per generated page. Inside each: `<loc>` (absolute URL with trailing slash for index/section pages), `<lastmod>` (ISO 8601 date `YYYY-MM-DD`), `<changefreq>`, `<priority>` — all four sub-elements required.
- Ampersands in URLs escaped as `&amp;`. No other entity issues.
- Ordering: home first, top-level pages next, deep pages last. The order has no SEO impact but makes the file legible.

`<changefreq>` per page type: `weekly` (home), `monthly` (top-level), `yearly` (static service detail pages). `<priority>`: `1.0` home, `0.8` top-level, `0.6` deep.

Exact template:

```xml
<?xml version="1.0" encoding="UTF-8"?>
<urlset xmlns="http://www.sitemaps.org/schemas/sitemap/0.9">
  <url>
    <loc>https://example.com/</loc>
    <lastmod>2026-05-20</lastmod>
    <changefreq>weekly</changefreq>
    <priority>1.0</priority>
  </url>
  <url>
    <loc>https://example.com/services/</loc>
    <lastmod>2026-05-20</lastmod>
    <changefreq>monthly</changefreq>
    <priority>0.8</priority>
  </url>
  <url>
    <loc>https://example.com/services/immunizations/</loc>
    <lastmod>2026-05-20</lastmod>
    <changefreq>yearly</changefreq>
    <priority>0.6</priority>
  </url>
</urlset>
```

Validation: parse `/sitemap.xml` with an XML parser; confirm well-formedness, the sitemaps.org namespace, at least one `<url>` entry, every entry contains all four sub-elements, and every `<loc>` URL returns HTTP 200. Any parse error or missing sub-element halts the build.

**`llms.txt`**

Generate following the [llms.txt spec](https://llmstxt.org). The file's job is to give an LLM enough context to answer questions about this pharmacy. Use this exact structure:

```markdown
# <Pharmacy Name>

> <Plain-prose summary, ≤ 200 chars, sourced from build-sheet tagline or about copy. No marketing hyperbole. Required blockquote line.>

<2–4 sentence paragraph: city/state, key services, plain-English hours summary (e.g., "Open Monday through Friday, 9 am to 6 pm"), and how a patient takes action (call, refill, transfer). Sourced from the build sheet — never invented.>

## Services

- [Refill Prescriptions](<New Website URL>/refill/): Wired to the build-sheet refill portal URL.
- [Transfer a Prescription](<New Website URL>/transfer/): Outbound link to the transfer destination; no PHI is collected on this site.
- [<Topic Service 1>](<New Website URL>/services/<slug-1>/): <One-sentence description from the build sheet.>
- [<Topic Service 2>](<New Website URL>/services/<slug-2>/): <One-sentence description from the build sheet.>
- ...one bullet per Topics entry, plus a single bullet listing List-only services...

## Information

- [About](<New Website URL>/about/): Pharmacy story, year opened, independence.
- [Contact](<New Website URL>/contact/): Address, phone, fax, email, map + directions.
- [Hours](<New Website URL>/contact/#hours): Business hours table.
- [FAQ](<New Website URL>/faq/): Site-wide frequently asked questions.

## Optional

- [Patient Portal](<Patient Portal URL from build sheet>): External login to manage prescriptions.
- [Mobile App](<New Website URL>/app/): Only included when `Requires Mobile App Page` is yes in the build sheet.
```

Strict-format rules:

- The blockquote (`> …`) is **required** and is the LLM-readable summary. Plain prose only — no inline markdown, no links inside the blockquote.
- Each link bullet uses the format `[Title](URL): description` — the colon-space-description suffix is the spec form. Omit the suffix only when a link genuinely has no description.
- Section headers are exactly `## Services`, `## Information`, `## Optional`. The `## Optional` section is the spec's defined opt-out section for content an LLM may skip when context is limited.
- File saved as `llms.txt` at site root, UTF-8, LF line endings.
- Encode special characters per markdown rules (parentheses inside URLs).
- Omit any bullet whose source data is missing — never stub or fabricate links.

**`size-report.json`**

Every deployed pharmacy site emits a machine-readable size report at the root of the deployed output — so hosting-cost estimation is trivial per site. After the production build (`vite build`, `npm run build`, or equivalent) completes and the output folder (`dist`, `build`, or the framework's default) exists on disk, measure it and write the report **into that same folder** so it deploys alongside the site and is reachable at `/size-report.json`.

Measure the built output folder recursively:

- **totalBytes** — sum of all file sizes in bytes.
- **totalFiles** — count of all files.
- **byType** — per-category `{ bytes, files }` with these exact category names and extensions:
  - `html` — `.html`, `.htm`
  - `css` — `.css`
  - `js` — `.js`, `.mjs`, `.cjs`, `.map`
  - `images` — `.png`, `.jpg`, `.jpeg`, `.gif`, `.webp`, `.svg`, `.avif`, `.ico`
  - `fonts` — `.woff`, `.woff2`, `.ttf`, `.otf`, `.eot`
  - `other` — everything else

Exact JSON shape:

```json
{
  "generatedAt": "2026-07-10T12:00:00.000Z",
  "outputDir": "dist",
  "totalBytes": 1234567,
  "totalFiles": 42,
  "byType": {
    "html":   { "bytes": 120000, "files": 5 },
    "css":    { "bytes": 80000,  "files": 2 },
    "js":     { "bytes": 400000, "files": 6 },
    "images": { "bytes": 600000, "files": 25 },
    "fonts":  { "bytes": 30000,  "files": 3 },
    "other":  { "bytes": 4567,   "files": 1 }
  }
}
```

Rules:

- Measure the output **before** writing `size-report.json`. Its own few hundred bytes don't need to be included in the totals.
- If the build tool cleans the output folder on rebuild, regenerate the report after the final build. Recommended pattern: a small `scripts/size-report.mjs` invoked at the end of the build command (e.g. `"build": "vite build && node scripts/size-report.mjs"`), so the report is never stale.
- **Verify** the file exists in the output folder before finishing Step 4.
- **State the totals in the final summary** delivered to the operator: total size in human-readable form and bytes (e.g. "Total built output: 1.2 MB (1,234,567 bytes) across 42 files"), the per-type breakdown, the fact that `size-report.json` is included in the deploy folder and reachable at `/size-report.json` once published, and the exact deploy folder relative to the project root to use as the Static Deployment public directory.

## Schema (JSON-LD)

Emit one `<script type="application/ld+json">` block per schema object. All
objects are scoped to the page they appear on. Do not merge unrelated types
into a single block.

### Every page

Every page receives the following schemas.

**`Pharmacy` (extends `LocalBusiness`)**

```json
{
  "@context": "https://schema.org",
  "@type": ["Pharmacy", "LocalBusiness"],
  "name": "<Pharmacy Name>",
  "image": "<Primary image URL>",
  "logo": "<Logo URL>",
  "address": {
    "@type": "PostalAddress",
    "streetAddress": "<street>",
    "addressLocality": "<city>",
    "addressRegion": "<state>",
    "postalCode": "<zip>",
    "addressCountry": "US"
  },
  "telephone": "<phone>",
  "email": "<email>",
  "url": "<New Website URL>",
  "openingHoursSpecification": [
    {
      "@type": "OpeningHoursSpecification",
      "dayOfWeek": ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"],
      "opens": "09:00",
      "closes": "18:00"
    }
  ],
  "geo": {
    "@type": "GeoCoordinates",
    "latitude": "<lat>",
    "longitude": "<lng>"
  },
  "sameAs": [
    "<Facebook URL>",
    "<Instagram URL>"
  ]
}
```

- `openingHoursSpecification` — parsed from build sheet hours; split into
  separate `OpeningHoursSpecification` objects per day-group.
- `geo` — include lat/lng **only** if already present in source HTML or
  scraped metadata. **no external geocoding** — omit `geo` entirely if
  coordinates are unavailable in the source.
- `sameAs` — populated from social URLs captured during scrape only; never
  fabricated.

**`WebPage`**

```json
{
  "@context": "https://schema.org",
  "@type": "WebPage",
  "name": "<Page title>",
  "description": "<Meta description>",
  "url": "<Canonical URL>",
  "inLanguage": "en",
  "isPartOf": { "@id": "<New Website URL>" }
}
```

**`BreadcrumbList`** — on all non-home pages:

```json
{
  "@context": "https://schema.org",
  "@type": "BreadcrumbList",
  "itemListElement": [
    {
      "@type": "ListItem",
      "position": 1,
      "name": "Home",
      "item": "<New Website URL>/"
    },
    {
      "@type": "ListItem",
      "position": 2,
      "name": "<Page name>",
      "item": "<Page URL>"
    }
  ]
}
```

**`FAQPage`** — on any page that contains FAQ content:

```json
{
  "@context": "https://schema.org",
  "@type": "FAQPage",
  "mainEntity": [
    {
      "@type": "Question",
      "name": "<Question text>",
      "acceptedAnswer": {
        "@type": "Answer",
        "text": "<Answer text>"
      }
    }
  ]
}
```

FAQ Q&A must come from the build sheet, scrape, or QA doc — **never invented**.

### Page-specific

**No on-site search.** The generated site does not include search functionality. Do not emit `WebSite` JSON-LD with a `SearchAction`, do not implement a `/search` route, do not add a search input to the header or footer, and do not declare a search endpoint anywhere in markup or schema.

**Per-service pages — pick the right schema type per service**

Each per-service detail page gets a JSON-LD block. Choose the type based on what the service actually is — do not default everything to plain `Service`:

| Service kind | Schema type | Example services |
|---|---|---|
| Immunizations / vaccinations | `MedicalProcedure` with `procedureType: "Therapeutic"` and embedded `Vaccine` entries per vaccine listed in `immunization options` | "Immunizations," "Flu Shots," "COVID Vaccines" |
| Clinical / therapeutic services | `MedicalTherapy` | "Medication Counseling," "Medication Synchronization," "Medication Therapy Management," "Medication Adherence" |
| Compounding | `MedicalProcedure` with `procedureType: "Therapeutic"` | "Compounding," "Sterile Compounding" |
| Health screenings (BP, A1C, etc.) | `MedicalTest` | "Blood Pressure Screening," "Diabetes Screening" |
| Operational / non-clinical services | `Service` | "Delivery," "Refills," "Transfer," "OTC Products," "Insurance Support" |

Every chosen type — medical or operational — must include `provider` (the `Pharmacy` node), `name`, `description` (sourced from build sheet or scrape), and `areaServed` (the primary city). Medical types must additionally satisfy schema.org's required properties for that type. `MedicalProcedure` requires at minimum `name` and `procedureType`. `MedicalTherapy` requires `name`. `MedicalTest` requires `name` and `usedToDiagnose` if a target condition is in the source — otherwise omit `usedToDiagnose`.

**Immunizations example** — when the build sheet lists `immunization options`, render the page with one `MedicalProcedure` block and one nested or sibling `Vaccine` block per listed vaccine:

```json
{
  "@context": "https://schema.org",
  "@type": "MedicalProcedure",
  "name": "Immunizations",
  "procedureType": "Therapeutic",
  "provider": {
    "@type": "Pharmacy",
    "name": "<Pharmacy Name>",
    "url": "<New Website URL>"
  },
  "areaServed": { "@type": "City", "name": "<City>" },
  "description": "<Description from build sheet>"
}
```

```json
{
  "@context": "https://schema.org",
  "@type": "Vaccine",
  "name": "<Vaccine name verbatim from build sheet, e.g. COVID-19, Flu, HPV, Shingles, Tdap or TD>"
}
```

Never extend the list of vaccines beyond what the build sheet's `immunization options` field contains.

**Operational service example** — when the page is non-clinical (e.g., delivery):

```json
{
  "@context": "https://schema.org",
  "@type": "Service",
  "serviceType": "<Service name, e.g. Delivery>",
  "provider": {
    "@type": "Pharmacy",
    "name": "<Pharmacy Name>",
    "url": "<New Website URL>"
  },
  "areaServed": { "@type": "City", "name": "<City>" },
  "description": "<Service description from build sheet or scrape>"
}
```

Connect every per-service node back to the pharmacy by listing all chosen service nodes in the Pharmacy node's `availableService` array on the home page and on the services index page.

**Contact page — `ContactPoint` array**

Emit an explicit `ContactPoint` array on the contact page:

```json
{
  "@context": "https://schema.org",
  "@type": "LocalBusiness",
  "name": "<Pharmacy Name>",
  "contactPoint": [
    {
      "@type": "ContactPoint",
      "telephone": "<phone>",
      "contactType": "customer service",
      "areaServed": "US",
      "availableLanguage": "English"
    }
  ]
}
```

**App page — `MobileApplication`**

When an app page is present and real App Store / Google Play URLs are provided
in the build sheet, emit `MobileApplication`:

```json
{
  "@context": "https://schema.org",
  "@type": "MobileApplication",
  "name": "<App name>",
  "operatingSystem": "iOS, Android",
  "applicationCategory": "HealthApplication",
  "downloadUrl": "<App Store URL>",
  "installUrl": "<Google Play URL>",
  "offers": {
    "@type": "Offer",
    "price": "0",
    "priceCurrency": "USD"
  }
}
```

Use real App Store and Google Play URLs from the build sheet only — never
fabricate store links.

### Validation

The skill ships a validator script at `tools/validate-schema.mjs`.

**What it does:**

1. Accepts one or more HTML file paths (or a glob) as arguments.
2. Extracts every `<script type="application/ld+json">` block from each file.
3. `JSON.parse()`s each block — exits with a non-zero code and prints the
   file name + block index on any parse error.
4. Validates required properties against an inline schema map (keyed by
   `@type`) that the skill includes. Prints a diff of missing required
   properties per object.
5. Logs a summary: `N objects validated, M warnings, K errors`.

**Online flag:**

Posts to Google's Rich Results test only if `--online` flag is passed at
runtime. Default behavior is **offline by default** — no network calls are
made during a standard build or CI run.

```bash
# Offline (default)
node tools/validate-schema.mjs dist/**/*.html

# Online (posts to Rich Results API)
node tools/validate-schema.mjs --online dist/**/*.html
```

The Rich Results test endpoint is `https://richresults.google.com/` — using
it in CI requires the `--online` flag to be set explicitly so builds remain
hermetic by default.

## Process

The build runs in five sequential steps. Each step has a defined input, action, exit criteria, and failure mode. Complete each step fully before advancing to the next. Do not reorder steps.

### Step 1 — Discover

**Input:** The build folder path supplied by the operator; the Build Sheet (`*.docx`) inside it.

**Action:** Scan the folder, resolve every file per §Inputs, and parse the Build Sheet plus any supporting docs (`Website content*.docx`, `QA *.docx`, `SEO_META_Tags_*.docx`). Extract every field listed in §Inputs › Build sheet fields to extract, including the `Build origin` field (`new` | `rebuild`) and the per-section `Content-edited flags`. Write a single `build/context.json` consolidating all parsed fields with `provenance` annotations. Mark absent fields `null` with a `nullReason` — never omit them silently. For new builds, also compare each content field against `tools/default-templates.json` and record `is_default_template: true|false` per section so §Content variation policy can drive the variation step in Step 4.

**Exit criteria:** `build/context.json` exists, is valid JSON, and contains every required field (present or `null` with a `nullReason`). No field is missing from the file.

**Failure mode:** Hard fail if the Build Sheet is missing. Warn and continue if the logo is absent. Log every conflict between source documents to `/build/log.md`. Do not advance to Step 2 with a malformed context file.

---

### Step 2 — Scrape

**Input:** `build/context.json` (from Step 1); specifically the `Website URL` field (the pharmacy's existing live site).

**Action:** Run `tools/scrape.mjs` per §Scrape mechanics. Crawl the live site same-origin, depth ≤ 2, max 100 pages, 1 req/sec. Save raw HTML to `/scraped/raw/`, reader-mode markdown to `/scraped/text/`, assets to `/scraped/assets/`. Write `/scraped/manifest.json` per §Scrape › Manifest.

**Exit criteria:** `/scraped/manifest.json` exists and records EITHER at least one page entry with `scrape_status: "complete"` OR a top-level `scrape_status: "unreachable"` entry (with reason). All captured assets, if any, are present on disk. The scrape log entry in `/build/log.md` records the same `scrape_status` value — there is no silent fallback.

**Failure mode:** If the site is unreachable (DNS failure, HTTP 403, blocked by `robots.txt`), log `scrape_status: "unreachable"` to `/build/log.md` and continue with build-sheet-only content. There is no silent fallback — log the failure explicitly so downstream steps know the scrape was skipped. Do not invent scraped content.

---

### Step 3 — Plan

**Input:** `build/context.json` (Step 1); `/scraped/manifest.json` and `/scraped/text/*.md` corpus (Step 2, or build-sheet-only if scrape was unreachable).

**Action:** Determine the full page set per §Required pages (always-built + conditional pages + qualifying scrape discoveries). Apply the scrape-discovery rule (≥ 150 substantive words, not a contact/hours rehash). For each page record: URL slug, page type, title, meta description, H1, primary CTA, schema types required, and source content references. Write the complete page manifest to `/build/page-plan.json`.

**Exit criteria:** `/build/page-plan.json` exists, is valid JSON, and lists every required page (minimum eight always-built pages plus any applicable conditional pages). Each entry carries all required fields. No required page is absent.

**Failure mode:** If required build-sheet fields (e.g., pharmacy name, address) are `null` in `build/context.json`, the corresponding page sections are omitted per §Section omission rule — not stubbed. Log any omitted sections to `/build/log.md`. Do not advance to Step 4 with a malformed plan file.

---

### Step 4 — Generate

**Input:** `/build/page-plan.json` (Step 3); `build/context.json` (Step 1); `/scraped/` corpus (Step 2).

**Action:** Scaffold the project and generate every page in the plan in a **single design pass** per §Visual design — no external design-agent skills, no review-pass loops. Use the recommended React + Tailwind + shadcn/ui stack unless the operator overrides. For each page: write semantic HTML per §Required sections, apply WCAG 2.2 AA per §Accessibility, include all `<head>` elements per §SEO, emit all required JSON-LD blocks per §Schema (JSON-LD), leave the cookie consent placeholder from §Required sections › Cookie consent banner (external drop-in) in the base template, and honor §Conversion. After all pages are written, generate the site-wide files:

- `robots.txt` per §SEO › Site-wide files
- `sitemap.xml` per §SEO › Site-wide files
- `llms.txt` per §SEO › Site-wide files
- `size-report.json` per §SEO › Site-wide files (measured over the final built output; must be regenerated if the build tool cleans the output folder on rebuild)

Wire the following into every page's `<head>` and layout exactly as sourced from `build/context.json`:

- **head JS snippet** — verbatim from the build sheet `head JS` field; injected into `<head>` without modification
- **GA ID** — the Google Analytics measurement ID from the build sheet; wired into the head JS or analytics snippet
- **brand color** — the hex value from the build sheet; applied as the primary accent color
- **Refill, Transfer, and Patient Portal CTAs** — wired to their respective portal URLs from the build sheet; present in the sticky header on every page per §Required sections

**Exit criteria:** Every page in `/build/page-plan.json` has a corresponding generated HTML file. `robots.txt`, `sitemap.xml`, `llms.txt`, AND `size-report.json` exist at the site root of the built output folder. `size-report.json` parses as valid JSON with the exact shape defined in §SEO › Site-wide files › `size-report.json` (`generatedAt`, `outputDir`, `totalBytes`, `totalFiles`, `byType` with the six categories). All JSON-LD blocks are present and syntactically valid. No placeholder text appears in any output file.

**Failure mode:** If a required field is absent from `build/context.json`, omit the corresponding section or element (see §Section omission rule). Log every omission to `/build/log.md`. Do not stub, invent, or hardcode values — no silent fallback.

**Cost and efficiency rules for Step 4.** The design generation and content pipeline is the most expensive part of a build. Apply these rules to keep cost bounded:

- **Single-pass design.** Generate the design once per page. Do not invoke external design agents or run review-pass loops. If the operator explicitly requests a second pass, do it and log; otherwise stop after the first pass.
- **AI content variation only when the flag positively indicates unedited.** Per §Content variation policy, the variation step runs only when a content-edited flag is set to `no` OR the submitted text exactly matches a known jotform default template phrase. Any other signal — including missing flags — is treated as edited and skips the AI call. This avoids paying for variations the operator didn't ask for.
- **Image generation is last-resort.** Follow §Image policy sourcing priority strictly (build folder → scrape → AI-generated for interior-only scenes → Unsplash stock). Prefer existing images over generating new ones; the AI-generation step is only invoked when no acceptable image exists in the first two sources for the specific slot.
- **No cookie banner generation.** The banner is an external drop-in per §Required sections › Cookie consent banner (external drop-in). Do not generate the widget code.
- **Reuse scraped assets in place.** During Generate, reference images and PDFs by their `/scraped/assets/` local paths — do not re-fetch or re-download.
- **Batch validator invocations.** Run each validator (`tools/validate-content.mjs`, `tools/validate-a11y.mjs`, `tools/validate-schema.mjs`) once against the full site output rather than per-page shell fanout. Each script accepts a base directory as input.
- **Lighthouse iteration budget.** After Generate, run Lighthouse once per page. If a metric misses its target by less than 10% (e.g., LCP 2.7s vs 2.5s target), log a warning and continue — do not iterate. Only regenerate for hard misses (> 10% over target or a Critical validator finding). Log all decisions to `/build/log.md`.

---

### Step 5 — Validate

**Input:** All generated HTML files; `build/context.json`; `/build/page-plan.json`.

**Action:** Run the full validator suite against every generated file:

1. **Content validation** — run `tools/validate-content.mjs` to check for banned phrasings (§Banned phrasings), PHI patterns (§PHI rules), and placeholder text. Any hit is a build failure.
2. **Accessibility validation** — run `tools/validate-a11y.mjs` to check landmark presence, heading order, alt attributes, focus styles, contrast ratios, and keyboard reachability (§Accessibility).
3. **Schema validation** — run `tools/validate-schema.mjs` to extract and validate all JSON-LD blocks per §Schema (JSON-LD). Any parse error or missing required property is a build failure.

After the three validators pass, perform a final **structural verification** (not a script, but a mandatory manual check): every page in `/build/page-plan.json` has a corresponding HTML file; `robots.txt`, `sitemap.xml`, and `llms.txt` exist at the site root; no page is missing its required `<head>` elements; the closing QA checklist below is reproduced in `/build/log.md` with every box checked.

**Exit criteria:** All three validators exit with code `0` AND the structural verification confirms every required artifact is present and the QA checklist is fully reproduced in `/build/log.md`.

**Failure mode:** Any FAIL from any validator OR any failing structural check halts the build. Log the failing file path, validator name, and error detail to `/build/log.md`. Fix the violation and re-run the full validator suite from the top. Do not declare done until all three validators exit `0` with zero errors and the structural verification passes — do not declare done with unresolved failures. There is no partial pass state.

## QA self-validation checklist

Before declaring the build complete, you must reproduce this checklist in `/build/log.md` with each box checked. Any unchecked box = build not done.

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
[ ] Per-service JSON-LD: MedicalProcedure / MedicalTherapy / MedicalTest / Vaccine for clinical services; plain Service for operational ones
[ ] No on-site search: no SearchAction in JSON-LD, no /search route, no search input in markup
[ ] Single-pass generation per §Visual design; brand color preserved; no unauthorized second design pass invoked
[ ] sitemap.xml parses as well-formed XML; sitemaps.org namespace present; every <url> has loc/lastmod/changefreq/priority
[ ] robots.txt: User-agent + Allow + Sitemap directives only; UTF-8 LF, no BOM; absolute Sitemap URL
[ ] llms.txt: H1 + blockquote + paragraph + ## Services + ## Information + ## Optional sections; spec format honored
[ ] Mobile menu: hamburger trigger, role=dialog drawer, focus trap, Esc closes, backdrop closes, body scroll lock, prefers-reduced-motion respected, no hover-only interactions
[ ] All tap targets >= 44x44 CSS pixels on mobile
[ ] Sticky bottom CTA bar on mobile (Call + Refill); respects safe-area-inset-bottom; hidden when drawer open
[ ] Above-the-fold on mobile: name + tagline + Refill CTA + tel: link + open-now indicator all visible without scroll
[ ] Every phone number wrapped in <a href="tel:+1..."> with +1 prefix; every email in mailto: link
[ ] No carousel hero, no exit-intent modals, no auto-play media, no "Click here" / "Learn more" CTA copy
[ ] /privacy/ page exists with HIPAA Notice of Privacy Practices; linked from footer of every page
[ ] Cookie consent placeholder present (external drop-in widget target); GA consent-mode default set to denied
[ ] size-report.json exists at the root of the built output with generatedAt, outputDir, totalBytes, totalFiles, and byType (html/css/js/images/fonts/other)
[ ] Final summary states total built size (human + bytes), per-type breakdown, size-report.json path, and the exact Static Deployment public directory
[ ] CSS: box-sizing: border-box reset; >= 1 @media query; body font-size >= 16px on mobile; no horizontal scroll at 320px
[ ] Security headers: HSTS (2yr+), CSP with frame-ancestors, X-Content-Type-Options nosniff, X-Frame-Options, Referrer-Policy, Permissions-Policy denying camera/mic/geo/payment
[ ] Lighthouse mobile: Performance >= 85; LCP <= 2.5s; CLS <= 0.1; FCP <= 1.8s; Speed Index <= 3.4s; TBT <= 200ms — logged per page
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
