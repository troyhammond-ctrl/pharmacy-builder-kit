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
- **Transfer-form requirement** (yes/no)
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
- **`Requires transfer form page`** → add `/transfer/` as a CTA-only page (outbound link; no PHI form).
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
| `/` | Home | Hero, tagline, primary CTAs (Refill, Transfer, Contact) |
| `/about/` | About | Pharmacy story, staff, year opened, community roots |
| `/contact/` | Contact | Address, hours, phone, map embed, contact form |
| `/services/` | Services index | Cards for every service (Topics deep + List shallow) |
| `/services/<slug>/` | Per-service detail | One page per "Topics" entry; deep treatment with copy |
| `/refill/` | Refill | Refill portal CTA wired to build-sheet URL; pickup methods copy |
| `/transfer/` | Transfer | CTA + outbound link only — no PHI form |
| `/faq/` | FAQ | Frequently asked questions drawn from build sheet and scrape |

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

## Voice

## Banned phrasings

## Factual guardrails

## PHI rules

## Accessibility (WCAG 2.2 AA)

## SEO

## Schema (JSON-LD)

## Process

## QA self-validation checklist
