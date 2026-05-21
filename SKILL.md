---
name: pharmacy-builder
description: Build a clean, modern, accessible, factually faithful pharmacy website from a build folder. Use when the user asks to "build pharmacy site," "build pharmacy website," generate a site from a "pharmacy build sheet," kick off a "Lumistry pharmacy build," or names a known template label such as "Longhorn." The skill takes a path to a build folder containing a build sheet (.docx) plus optional supporting docs and a logo, scrapes the pharmacy's existing live site for facts and assets, and produces a multi-page site that satisfies a strict output contract (required pages, WCAG 2.2 AA accessibility, SEO + JSON-LD schema, voice and PHI guardrails). Stack-agnostic — the agent picks the framework.
---

# Pharmacy Builder Skill

> The Contract half (below) defines what the build must satisfy. The Process half at the end defines the order in which steps run. Every step in Process references a Contract section by name. Read the whole document before starting a build.

## Inputs

You are given a path to a build folder. Scan it and resolve every file before doing anything else.

### Input folder layout

| File | Required? | Discovery rule |
|---|---|---|
| Build Sheet (`*.docx`) | **Required** | Filename contains `Build Sheet` |
| Logo (PNG/JPG/SVG) | **Required** | Image in folder root, or fetched from the `Logo:` URL in the build sheet |
| `Website content*.docx` | Optional | Filename matches `*content*.docx` |
| `QA *.docx` | Optional | Filename matches `QA *.docx` |
| `SEO_META_Tags_*.docx` | Optional | Filename matches `SEO_META*.docx` |
| Extra images, PDFs, videos | Optional | Any other media in the folder; catalog for possible reuse |
| Word lockfiles (`~$*.docx`) | Ignored | Skip entirely — do not parse or surface |

Hard fail if the Build Sheet is missing. Warn and continue if the logo is missing.

### Build sheet fields to extract

Extract every field listed below. Mark absent fields `null` with a `nullReason`. Do not invent values.

- **Pharmacy name**
- **address** (street, city, state, ZIP)
- **hours** (all open days and times, exactly as written)
- **phone**
- **fax**
- **email**
- **Website URL** (the pharmacy's existing live site — seed for the scrape step)
- **New Website URL** (staging/target; used as the canonical base URL)
- **Google Map URL**
- **refill portal** URL
- **Patient Portal URL** (wired to the Patient Portal CTA across the site; if absent, the Patient Portal CTA is omitted from the sticky header per §Section omission rule — never invent or substitute another URL)
- **Transfer-form requirement** (build-sheet key: `Requires transfer form page`; yes/no)
- **Transfer destination URL** (the outbound URL the `/transfer/` CTA links to when `Requires transfer form page` is yes; never collect PHI on the new site itself)
- **Requires Mobile App Page** flag (yes/no)
- **GA ID** (Google Analytics measurement ID)
- **head JS** snippet (verbatim; wired into `<head>` during generation)
- **brand color** (hex value)
- **Logo URL** (if not a local file)
- **Package label**
- **Template label** (e.g., "Longhorn" — see policy below)
- **services topics** (deeper-treatment services; each gets its own page)
- **services list** (shallow-card services; listed on the services index only)
- **Per-service description copy** for each Topic entry
- **immunization options** (list exactly as written; never extend)
- **year opened**
- **tagline**
- **about** copy
- **pickup methods** (drives `/refill/` copy)
- **Additional locations** flag (yes/no)
- **Social links** (if present)

### Conditional flags

Respect these flags exactly; do not activate conditional pages or features without a matching flag:

- **`Requires Mobile App Page: Yes`** → build the `/app/` page with real Apple App Store and Google Play badges wired to the URLs in the build sheet.
- **Refill portal URL present** → wire the Refill CTA to that URL across the site.
- **`Requires transfer form page`** → wire the `/transfer/` page's CTA / outbound link to the build-sheet transfer destination URL. The `/transfer/` page itself is always built (see §Required pages); this flag controls its wiring, never its existence. Still no PHI form.
- **`pickup methods`** → use the listed methods to drive the copy on `/refill/`.
- **`Additional locations: Yes`** → build a `/locations/` index page plus a `/locations/<slug>/` page per location.

### Template label policy

The build sheet may include a field like `Template: Longhorn`. Treat this as a label or hint only — it is not a binding template directive and does not constrain the design. Record it in build metadata and produce a clean, modern, unique design regardless.

### Output of this step

Write a single `build/context.json` that consolidates every parsed field from the build sheet plus any supporting docs (`Website content*.docx`, `QA *.docx`, `SEO_META_Tags_*.docx`). Each field must carry a `provenance` annotation: one of `build_sheet`, `content_doc`, `qa_doc`, `seo_doc`, or `scrape`. Absent fields must appear explicitly as `null` with a `nullReason` string — never omit them silently. This file is the single source of truth that all later steps quote from.

## Scrape

### Goal

Mirror the build sheet's `Website URL` field — the pharmacy's existing live site — to a local `/scraped/` folder. The scrape is a **fact source**, not a **design source**. The new site doesn't have to look like the old one; it only borrows verifiable facts, copy, and assets from it.

### Mechanics

Write and run `tools/scrape.mjs`. The skill defines the contract; Replit Agent owns the implementation.

- **Seed:** use the `Website URL` from the build sheet (the existing live site, not the staging URL).
- **Crawl rules:** same-origin only; depth ≤ 3; max 200 pages; rate-limit to 1 req/sec; send a descriptive User-Agent string; respect the source site's `robots.txt`; skip `mailto:`, `tel:`, anchor-only links, and tracker or CDN hosts.
- **Asset capture:** collect every `<img>`, `<source>`, `<video>`, and any `<a href>` pointing to `.pdf`, `.docx`, `.mp4`, `.webm`, or image extensions. Download each file to `/scraped/assets/` using collision-safe filenames that preserve the original name where possible.
- **Content capture:** save each crawled page as raw HTML at `/scraped/raw/<slug>.html` and as a reader-mode markdown extraction at `/scraped/text/<slug>.md` for LLM consumption.

### Manifest

Write `/scraped/manifest.json` after the crawl completes. For each page record: URL, HTTP status, final URL (after redirects), `<title>`, first `<h1>`, word count, list of referenced assets, and list of outbound internal links. This file plus the `/scraped/text/*.md` corpus are the handoff to the Plan and Generate steps.

### Failure handling

If the source site is unreachable — DNS failure, HTTP 403, or blocked by `robots.txt` — log `scrape_status: "unreachable"` to `/build/log.md` and continue with build-sheet-only content. There is no silent fallback — log the failure explicitly so downstream steps know the scrape was skipped.

### Allowed uses of scraped content

- **Fact source:** claimed services, awards, staff names, hours phrasing — every claim is still subject to §Factual guardrails before use.
- **PDFs** (forms, brochures) that may be linked from the new site when relevant.
- **Storefront, team, and product images** with generated alt text.

### Disallowed uses

- **Overriding the build sheet on conflict.** Build sheet wins; log every conflict to `/build/log.md`.
- **Carrying over PHI** (patient testimonials with full names paired with conditions, Rx numbers, DOB, etc.) — redact per §PHI rules.
- **Carrying over marketing hyperbole, comparative claims, clinical claims, or unverified credentials** — filter per §Voice and §Factual guardrails.

## Required pages

### Always-built pages

Every build must produce the following eight pages regardless of build-sheet flags:

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

**Sticky header** — fixed to the top of the viewport on scroll. Contains: logo (linked to `/`), primary nav with a services dropdown that lists every service topic, and three CTAs in this order: Refill, Transfer, Patient Portal. The header never wraps to a second row at desktop widths.

**Footer** — contains: full address, phone, fax, email, business hours, social links (only if scraped or present in build sheet), NPI and license numbers (only if found in source material — never fabricated), copyright line, accessibility statement link, and a sitemap link. Omit any footer field whose value is not available in the build context.

**FAQs** — every page includes a FAQ section near the bottom, scoped to the page's topic, drawn from the build sheet and scrape corpus. Include a `FAQPage` JSON-LD block for each FAQ section — see §Schema (JSON-LD).

### Home only

The home page body contains the following sections in order:

1. **Hero** — full-width banner using the build-sheet tagline and a primary CTA (Refill or Transfer, whichever is primary per the build sheet). Background image sourced from scraped or provided assets; never use stock photography placeholders.
2. **Services grid** — card grid for every service (Topics + List). Each card has its own icon drawn from a single coherent icon set, line style, approximately 24×24 px, single-stroke, and recolorable via `currentColor`. The same icon set is reused in the header services dropdown — never mix sets.
3. **Hours of operation** — a semantic `<table>` listing every open day and its hours exactly as written in the build sheet.
4. **Trust callouts** — brief value statements (locally owned, years in business, etc.). No comparative claims ("best," "only," "most").
5. **Testimonials** — patient or customer quotes from the build sheet or scrape. Testimonials are omitted if no source material exists — never fabricated. Redact any PHI.
6. **App download row** — only if `Requires Mobile App Page: Yes` is set in the build sheet. Include real Apple App Store and Google Play badges wired to the URLs from the build sheet.

### Contact only

The contact page body contains:

- Clickable address (links to the Google Maps entry), clickable phone, fax, and email.
- Map embed: construct the embed URL from the build sheet `Google Map URL` field. Render a "Get directions" link that opens the Google Maps URL in a new tab (`target="_blank" rel="noopener noreferrer"`).
- No contact form — the contact page does not collect any patient data.
- Full hours of operation table (same as home).
- FAQs scoped to location and access questions.

### Per-service page

Each per-service detail page (one per Topics entry) follows this structure:

- **H1 = service name** — exactly as written in the build sheet Topics list; do not rename or abbreviate.
- Verbatim build-sheet description copy followed by any additional detail sourced from the scrape.
- For the Immunizations service: include a list labeled **Immunization Options** reproducing the build sheet `immunization options` field exactly — never extend or supplement this list with vaccines not explicitly listed in the build sheet.
- A CTA appropriate to the service (e.g., "Schedule Now," "Request a Refill") — wire to the correct portal URL.
- FAQs scoped to that service's topic.

### Iconography rule

Use one coherent icon set across the entire site (e.g., Lucide, Heroicons, or Phosphor). Pick one set and commit to it. The same icon set appears in the services grid cards and the header services dropdown — never mix two icon families. All icons must be rendered at a consistent size (approximately 24×24 px), use a single-stroke line style, and accept brand-color theming via `currentColor` so they inherit the text color of their container without hardcoded fill values.

### Section omission rule

Any required section whose content cannot be sourced from the build sheet, supporting docs, or scrape corpus is omitted, not stubbed. Do not insert placeholder text. Specifically:

- No "Lorem ipsum" — never use filler Latin text.
- No "Coming soon" — never stub a section with a coming-soon notice.
- No fake content of any kind. If the data isn't there, the section isn't there.

## Visual design

The skill is stack-agnostic, but design quality is not optional. Pharmacies are healthcare businesses — the site must look professional, modern, and trustworthy.

**Invoke the `ui-ux-pro-max` skill** for all visual design decisions: layout, typography, color application beyond the brand hex, spacing, shadows, gradients, hover states, animations, and component patterns. Pro-max is the design authority during Step 4 — Generate.

**Style direction.** Clean, modern, professional. Recommended styles from pro-max's catalog: minimalism, flat design with subtle depth, or a restrained bento grid layout on the home page. Avoid brutalism, claymorphism, heavy neumorphism, and anything that reads "trendy" rather than "trustworthy."

**Stack hint.** When pro-max needs a stack signal, default to React + Tailwind + shadcn/ui (via the shadcn MCP). If Replit Agent picks a different stack at scaffolding time, pro-max should align with that stack instead.

**Constraints — pro-max output is filtered through these. On any conflict, the constraint wins.**

- **Brand color is canonical.** The hex from the build sheet is the primary accent. Pro-max may propose complementary or neutral shades around it, but the brand hex itself is non-negotiable.
- **Accessibility wins.** If a pro-max suggestion conflicts with §Accessibility (low-contrast hover, focus override < 3:1, color-only indicators), the §Accessibility rule wins. Never sacrifice WCAG 2.2 AA for visual flair.
- **Voice wins.** If pro-max generates microcopy (button labels, empty states, error text), §Voice and §Banned phrasings still apply. Filter pro-max copy through `tools/validate-content.mjs` before declaring done.
- **Required sections are non-negotiable.** Pro-max may not invent layouts that omit any of §Required sections or merge them in ways that hide critical content.
- **Iconography.** Pro-max picks one icon set per §Required sections › Iconography rule; never mix sets even if pro-max suggests a hybrid.
- **Typography.** Pro-max picks one of its font pairings. Body sans-serif must support the 8th-grade readability target in §Voice; display fonts must remain accessible at the sizes used. No ornamental display fonts for body content.
- **Dark mode.** Ship dark mode only if pro-max can produce one without breaking WCAG AA contrast against the brand color. If brand color cannot satisfy AA on a dark background, ship light mode only and log the decision in `/build/log.md`. Never force a degraded dark mode.
- **Responsive and mobile-first.** Pro-max output must pass on phone, tablet, and desktop breakpoints. The sticky header must not trap focus or scroll on mobile.

**Review pass.** After Step 4 — Generate produces the first pass, invoke pro-max again with its `review` action against the rendered output and fold its findings into a second pass. Do not declare design done until the §Accessibility validator passes AND a pro-max review returns no critical issues.

## Voice

- Write in plain language targeting an 8th-grade reading level. Target a Flesch-Kincaid readability score of ≥ 70.
- Use short sentences. Active voice only — never passive construction when active is possible.
- Second person throughout: address the patient as "you" ("you can get your refill"), never third person ("patients can…").
- Warm but not casual. Friendly, not flippant. Professional tone that reassures; never breezy, sarcastic, or colloquial.
- Practical: tell the patient what to do, where to go, and what to expect. Every paragraph should answer one of: what is this, how do I get it, what happens next.
- local-color claims — community, neighborhood, family-owned, independent — are allowed only if backed by the build sheet or scrape corpus. Apply the same test to every local-color claim: if there is no source, omit the claim.

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

### Site-wide files

Generate the following files at the site root alongside `index.html`.

**`robots.txt`**

Allow all crawlers and reference the sitemap:

```
User-agent: *
Allow: /
Sitemap: <New Website URL>/sitemap.xml
```

**`sitemap.xml`**

Include every generated page. Set `<lastmod>` to the build date (ISO 8601). Use the following priority scheme:

- Home page: `1.0`
- Top-level pages (e.g. `/services`, `/about`, `/contact`): `0.8`
- Deep pages (e.g. `/services/compounding`): `0.6`

**`llms.txt`**

Generate a markdown index following the llms.txt spec. Structure:

```
# <Pharmacy Name>

<One-sentence description of the pharmacy.>

## Pages
- [Home](<New Website URL>/)
- [Services](<New Website URL>/services)
- ...

## Services
- [<Service Name>](<New Website URL>/services/<slug>)
- ...

## About
- [About Us](<New Website URL>/about)
- [Contact](<New Website URL>/contact)
```

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

**Action:** Scan the folder, resolve every file per §Inputs, and parse the Build Sheet plus any supporting docs (`Website content*.docx`, `QA *.docx`, `SEO_META_Tags_*.docx`). Extract every field listed in §Inputs › Build sheet fields to extract. Write a single `build/context.json` consolidating all parsed fields with `provenance` annotations. Mark absent fields `null` with a `nullReason` — never omit them silently.

**Exit criteria:** `build/context.json` exists, is valid JSON, and contains every required field (present or `null` with a `nullReason`). No field is missing from the file.

**Failure mode:** Hard fail if the Build Sheet is missing. Warn and continue if the logo is absent. Log every conflict between source documents to `/build/log.md`. Do not advance to Step 2 with a malformed context file.

---

### Step 2 — Scrape

**Input:** `build/context.json` (from Step 1); specifically the `Website URL` field (the pharmacy's existing live site).

**Action:** Run `tools/scrape.mjs` per §Scrape mechanics. Crawl the live site same-origin, depth ≤ 3, max 200 pages, 1 req/sec. Save raw HTML to `/scraped/raw/`, reader-mode markdown to `/scraped/text/`, assets to `/scraped/assets/`. Write `/scraped/manifest.json` per §Scrape › Manifest.

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

**Action:** Scaffold the project and generate every page in the plan. **Invoke the `ui-ux-pro-max` skill per §Visual design** to drive layout, typography, palette extension around the brand hex, components, spacing, and motion — pro-max output filtered through the §Visual design constraints. For each page: write semantic HTML per §Required sections, apply WCAG 2.2 AA per §Accessibility, include all `<head>` elements per §SEO, and emit all required JSON-LD blocks per §Schema (JSON-LD). After all pages are written, generate the site-wide files:

- `robots.txt` per §SEO › Site-wide files
- `sitemap.xml` per §SEO › Site-wide files
- `llms.txt` per §SEO › Site-wide files

Wire the following into every page's `<head>` and layout exactly as sourced from `build/context.json`:

- **head JS snippet** — verbatim from the build sheet `head JS` field; injected into `<head>` without modification
- **GA ID** — the Google Analytics measurement ID from the build sheet; wired into the head JS or analytics snippet
- **brand color** — the hex value from the build sheet; applied as the primary accent color
- **Refill, Transfer, and Patient Portal CTAs** — wired to their respective portal URLs from the build sheet; present in the sticky header on every page per §Required sections

**Exit criteria:** Every page in `/build/page-plan.json` has a corresponding generated HTML file. `robots.txt`, `sitemap.xml`, and `llms.txt` exist at the site root. All JSON-LD blocks are present and syntactically valid. No placeholder text appears in any output file.

**Failure mode:** If a required field is absent from `build/context.json`, omit the corresponding section or element (see §Section omission rule). Log every omission to `/build/log.md`. Do not stub, invent, or hardcode values — no silent fallback.

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
[ ] ui-ux-pro-max invoked during Generate; review pass run; brand color preserved; no constraint conflicts unresolved
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
