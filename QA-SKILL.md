---
name: pharmacy-qa
description: Audit a built pharmacy website against the pharmacy-builder contract — every required page and section, WCAG 2.2 AA accessibility, full SEO metadata, schema.org JSON-LD correctness, valid robots.txt / sitemap.xml / llms.txt, mobile UX (drawer / sticky bottom bar / tap targets), conversion patterns (click-to-call, above-the-fold, CTA wiring), content guardrails (banned phrasings, PHI scan, clinical advice), voice and readability, visual quality, performance and best practices, and security and privacy. Use when the user asks to "audit a pharmacy site," "QA a pharmacy site," "review a pharmacy build," "validate a pharmacy site," "find UI/UX defects on a pharmacy site," "check schema on a pharmacy site," or otherwise wants an independent second-opinion audit on a site that was built (or claims to have been built) against the pharmacy-builder contract. Input is a URL or local path; output is a structured findings report with severity-tagged issues and recommended fixes. Stack-agnostic — audits rendered output, not source.
---

# Pharmacy QA Skill

> The Audit Dimensions half (below) defines what is checked. The Process half at the end defines how to run an audit and produce the report. Every finding traces back to a named dimension and severity. Read the whole document before starting an audit.

## Inputs

You are given either:

- **A URL** to a deployed pharmacy site (e.g., `https://acme-pharmacy.com`), or
- **A local path** to a static site directory (e.g., `./dist/`) that can be served with a local HTTP server during the audit.

Resolve the input before anything else:

- If a URL: confirm it returns HTTP 200, follow up to 2 redirects, and capture the final URL as the audit base.
- If a local path: spin up a local HTTP server (e.g., `npx serve <path>` on `http://localhost:<port>/`) and use that as the audit base. Some checks (e.g., schema validation against canonical URLs, sitemap loc reachability) require a real server, not file:// URLs.

Optional, helpful inputs:

- **The build context** (`build/context.json` from the pharmacy-builder skill) — the agent's source of truth for what should be on the site (pharmacy name, phone, services, etc.). When provided, fact-check findings against it.
- **The page plan** (`build/page-plan.json`) — the expected page list. When provided, audit against this plan; otherwise discover pages via `sitemap.xml`.

Hard fail if neither URL nor local path resolves. Warn if the optional build artifacts are absent — the audit still runs, but factual cross-checks become structural only.

### Output of this step

Write `audit/scope.json` capturing: base URL, list of pages discovered (from sitemap.xml or page-plan.json), input artifacts present, audit start timestamp, and the QA skill version that ran. This file is the audit's source of truth for what was checked.

## Audit dimensions

Twelve dimensions, each producing PASS / WARN / FAIL plus a findings list. The report aggregates all twelve.

### 1. Pages & structure

Confirm every required page exists, returns HTTP 200, and contains the required sections per the pharmacy-builder contract.

- **Always-built pages:** `/`, `/about/`, `/contact/`, `/services/`, `/services/<slug>/` (one per Topic), `/refill/`, `/transfer/`, `/faq/`. Each must return HTTP 200 with non-empty body. Trailing slashes must be honored (either by URL or by 301 redirect to canonical form).
- **Conditional pages:** `/app/` exists iff the build sheet has `Requires Mobile App Page: Yes`. `/locations/` + `/locations/<slug>/` exist iff `Additional locations: Yes`. Any extra discovered pages must be ≥ 150 substantive words and not a contact/hours rehash.
- **Per-page required sections:** sticky header (logo as home link, primary nav with no "Home" item, three CTAs), top bar, page body, footer (logo always rendered), FAQs near the bottom. Each present in DOM and visible.
- **Home-only sections:** hero (must depict a pharmacist serving a patient), services grid, hours of operation table (in `9:00 AM – 5:00 PM` format), trust callouts, reviews with "Leave a Review" CTA, testimonials (or omitted if no source), app download row (conditional — present only if App-vs-Portal rule selected the app).
- **Contact-only sections:** clickable address/phone/fax/email, map embed, "Get directions" link, hours, FAQs. **No contact form by default** (if present, must satisfy the HIPAA disclaimer + bot protection + no-PHI fields rules).
- **Per-service-page sections:** single H1 = service name, **a header image is present** (sourced per §Image policy in the builder contract — never a broken image, never an empty placeholder), build-sheet description verbatim, scoped FAQs, appropriate CTA.
- **App-vs-Portal exclusivity:** the site shows either App CTAs (header, drawer, app page) OR Patient Portal CTAs — never both. If both surfaces appear, this is a Critical finding (`pages.app-and-portal-both`).
- **No "Home" in primary nav.** The logo is the home link. A nav containing a "Home" item is a Minor finding (`pages.nav-redundant-home`).

Findings reference: `pages.missing`, `pages.empty`, `pages.section-missing`, `pages.unauthorized-form`, `pages.app-and-portal-both`, `pages.nav-redundant-home`, `pages.hero-not-pharmacist-patient`, `pages.service-image-missing`, `pages.hotlinked-stock-image`, `pages.fabricated-exterior-shot`, `pages.hours-format-invalid`, `pages.footer-logo-missing`, `pages.logo-too-small`.

### 2. Accessibility (WCAG 2.2 AA)

Run an automated a11y audit (e.g., `axe-core` via `puppeteer` or `@axe-core/cli`) plus manual checks the automated tool can't catch.

**Automated checks:**

- Exactly one `<h1>` per page. No skipped heading levels (H1 → H2 → H3 in strict order).
- Landmarks: `<header>`, `<nav>`, `<main>`, `<footer>` present. Page body inside `<main>`.
- Skip-link as the first focusable element on every page, pointing to `#main-content` (or equivalent).
- All `<img>` have `alt` attributes. Decorative images have `alt=""`. Logo alt matches `<Pharmacy Name> logo` pattern.
- `<html lang="en">` on every page.
- Icons have `aria-hidden="true"` and an adjacent text label.
- Body text contrast ≥ 4.5:1; large text and focus indicators ≥ 3:1.
- No use of color-only indicators.
- No positive `tabindex` values.
- All interactive elements are `<button>` or `<a>` (no `<div onclick>` / `<span onclick>`).
- Visible focus state ≥ 2px outline at ≥ 3:1 contrast.

**Manual checks (drive a browser or document the expected check in the report):**

- Keyboard reachability: every interactive element is focusable via Tab in visual order. Esc closes any open dropdown or modal. Enter/Space activate buttons.
- Sticky header does not trap focus.
- Open-now indicator has both text label AND color cue (never color-only). Wraps in `aria-live="polite"`.
- Screen reader smoke test: NVDA or VoiceOver can navigate from skip link → main → footer without dead zones.

Findings reference: `a11y.h1-count`, `a11y.heading-skip`, `a11y.missing-alt`, `a11y.contrast-fail`, `a11y.no-skip-link`, `a11y.focus-trap`, `a11y.color-only`, `a11y.tabindex-positive`.

### 3. SEO metadata

For every page, confirm the full required `<head>` set and structure:

- `<title>` present, ≤ 60 chars, follows the pattern `<page> | <Pharmacy Name>` or matches `SEO_META_Tags_*.docx` verbatim if provided.
- `<meta name="description">` present, between 140 and 160 chars, accurately reflects page content.
- `<link rel="canonical" href="...">` present with absolute URL rooted in the build-sheet `New Website URL`.
- Exactly one `<h1>` per page; H1 text closely matches the title's lead clause.
- Open Graph: `og:title`, `og:description`, `og:url`, `og:type=website`, `og:image` (1200×630 PNG, returns HTTP 200).
- Twitter card: `twitter:card=summary_large_image`, `twitter:title`, `twitter:description`, `twitter:image`.
- `<meta charset="UTF-8">` is the first child of `<head>`.
- `<meta name="viewport" content="width=device-width, initial-scale=1">` present.
- `<meta name="theme-color" content="<brand hex>">` present.
- No legacy `og:type=business.business`. No `<meta name="robots" content="noindex">` unless on a draft route.

Findings reference: `seo.title-missing`, `seo.title-too-long`, `seo.description-length`, `seo.canonical-missing`, `seo.h1-mismatch`, `seo.og-incomplete`, `seo.twitter-incomplete`, `seo.viewport-missing`, `seo.theme-color-missing`.

### 4. Schema (JSON-LD)

For every page, extract all `<script type="application/ld+json">` blocks and validate.

**Parse-level checks:**

- Every block is valid JSON. Parse failures are critical.
- Every block has `@context` (must equal `"https://schema.org"` or `["https://schema.org"]`).
- Every block has `@type`.

**Type and property checks:**

- **Every page** must contain a `Pharmacy` (extends `LocalBusiness`) node with `name`, `image`, `logo`, `address` (`PostalAddress` with `streetAddress`, `addressLocality`, `addressRegion`, `postalCode`, `addressCountry`), `telephone`, `email`, `url`, `openingHoursSpecification` (one entry per open day with `dayOfWeek`, `opens`, `closes`), and `sameAs` (only if social URLs sourced from build sheet or scrape).
- **Every page** must contain a `WebPage` node with `name`, `description`, `url`, `inLanguage="en"`, and `isPartOf`.
- **Every non-home page** must contain a `BreadcrumbList` matching the page's navigation path.
- **Every page with a FAQs section** must contain a `FAQPage` node whose `mainEntity` list matches the rendered Q&A exactly (no Q in the schema that isn't on the page; no Q on the page that isn't in the schema).
- **Per-service pages** must contain the correct medical type:
  - Immunizations / vaccinations: `MedicalProcedure` with `procedureType="Therapeutic"` + one `Vaccine` node per item in the rendered Immunization Options list.
  - Therapeutic services (medication counseling, sync, MTM, adherence): `MedicalTherapy`.
  - Compounding: `MedicalProcedure`.
  - Health screenings: `MedicalTest`.
  - Operational services (delivery, refills, transfer, OTC, insurance): plain `Service`.
- **Contact page** must contain an explicit `ContactPoint` array.
- **App page (if present)** must contain `MobileApplication` with real App Store + Google Play URLs from the build sheet.
- **Home and services index** Pharmacy nodes must list every service in `availableService`.

**Negative checks:**

- NO `WebSite` node with `SearchAction` (the site has no on-site search).
- NO `aggregateRating` unless verifiable review data is provided.
- NO `geo` lat/lng unless present in source HTML or scrape (no external geocoding).
- NO fabricated `sameAs` entries.

Findings reference: `schema.parse-fail`, `schema.context-missing`, `schema.type-wrong`, `schema.property-missing`, `schema.search-action-present`, `schema.medical-type-mismatch`, `schema.fabricated-rating`, `schema.faq-mismatch`.

### 5. Site-wide files

**`robots.txt`** — fetch `<base>/robots.txt`. Validate:

- HTTP 200, MIME `text/plain` (charset UTF-8 if declared).
- UTF-8 encoding, LF line endings, no BOM.
- Contains exactly: `User-agent: *`, `Allow: /`, `Sitemap: <absolute URL>`.
- Sitemap URL is fully qualified and returns HTTP 200.
- No `Disallow:` lines unless explicitly justified.
- No `Crawl-delay`, no custom bot directives, no comments above directives.

**`sitemap.xml`** — fetch `<base>/sitemap.xml`. Validate:

- HTTP 200, MIME `application/xml` or `text/xml`.
- Parses as well-formed XML with no warnings.
- Root `<urlset>` has the namespace `xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"`.
- XML declaration is the very first line: `<?xml version="1.0" encoding="UTF-8"?>`. No BOM.
- At least one `<url>` element.
- Every `<url>` contains `<loc>`, `<lastmod>` (ISO 8601 `YYYY-MM-DD`), `<changefreq>`, `<priority>` — all four.
- Every `<loc>` URL resolves to HTTP 200.
- Ampersands in URLs escaped as `&amp;`.
- Priority scheme: 1.0 home, 0.8 top-level, 0.6 deep.

**`llms.txt`** — fetch `<base>/llms.txt`. Validate per the [llms.txt spec](https://llmstxt.org):

- HTTP 200, plain text, UTF-8, LF line endings.
- Required structure:
  - Line 1: H1 with the pharmacy name (`# <Pharmacy Name>`).
  - Blank line, then a `> ` blockquote with a plain-prose summary ≤ 200 chars, no inline markdown.
  - Blank line, then a free-form paragraph with city/state, key services, plain-English hours, and how a patient takes action.
  - `## Services` section with bullets in format `[Title](URL): description`. Includes Refill, Transfer, and one bullet per Topics service.
  - `## Information` section with bullets for About, Contact, Hours, FAQ.
  - `## Optional` section for Patient Portal, Mobile App (if applicable).
- Every link URL returns HTTP 200.
- No marketing hyperbole, no fabricated facts, no PHI.

Findings reference: `robots.invalid`, `robots.disallow-present`, `sitemap.parse-fail`, `sitemap.namespace-missing`, `sitemap.url-404`, `sitemap.missing-subelement`, `llms.h1-missing`, `llms.blockquote-missing`, `llms.sections-incomplete`, `llms.link-404`.

### 6. Mobile UX

Audit the mobile experience at viewport widths 360px, 414px, and 768px. Use a real browser or `puppeteer` with mobile emulation.

**Sticky header & top bar:**

- Below 1024px, the header collapses to a hamburger trigger in the top-right.
- The top bar above the header still shows the open-now indicator and a tap-to-call phone link.
- All header tap targets ≥ 44×44 CSS pixels.

**Mobile drawer:**

- Hamburger has `aria-label="Open menu"` (or "Close menu" when open).
- `aria-expanded` reflects state correctly.
- `aria-controls` points to the drawer's `id`.
- Drawer has `role="dialog"`, `aria-modal="true"`, `aria-labelledby` pointing to its heading.
- First focusable element inside is the close button.
- Tab cycles within the drawer (focus trap verified by attempting Tab past the last focusable element — it should return to the first, not escape the drawer).
- Esc closes the drawer and returns focus to the hamburger.
- Backdrop tap closes the drawer.
- Body scroll is locked while the drawer is open.
- Animation respects `prefers-reduced-motion: reduce`.
- Services subnav is a disclosure group (not a nested dropdown). No `:hover`-only interactions anywhere.

**Sticky bottom CTA bar (mobile only):**

- Appears after the user scrolls past the hero (verify with scroll automation).
- Hidden when the drawer is open.
- Two equal-width buttons: Call (`tel:+1<10digits>`) and Refill (refill portal URL).
- Each button ≥ 44×44 tap target.
- Respects `safe-area-inset-bottom` on iOS (CSS `padding-bottom: env(safe-area-inset-bottom)` or equivalent).

**Touch responsiveness:**

- No 300ms tap delay (viewport meta is set correctly).
- No accidental zoom on form input focus (inputs use `font-size: 16px` minimum).

Findings reference: `mobile.no-collapse`, `mobile.tap-target-small`, `mobile.no-aria-expanded`, `mobile.no-focus-trap`, `mobile.no-backdrop-close`, `mobile.no-body-scroll-lock`, `mobile.bottom-bar-missing`, `mobile.bottom-bar-not-safe-area`, `mobile.hover-only-interaction`.

### 7. Conversion patterns

Audit the patient-conversion path.

**Action priority:**

- Click-to-call is visible above the fold on every page on mobile.
- Refill is the primary CTA in the hero on the home page.
- Transfer is a secondary CTA, never collecting PHI on-site.
- Patient Portal CTA is present but visually secondary.

**Above-the-fold (mobile):**

- Without scrolling, the visitor sees: pharmacy name, tagline, primary CTA (Refill), tap-to-call link, and open-now indicator.

**Sticky bottom mobile CTA bar:**

- Present (per Mobile UX dimension).
- Buttons labeled with action verbs (e.g., "Call" / "Refill"), not "Click here" / "Learn more".

**Trust signals above the fold or first viewport scroll:**

- Open-now indicator.
- Visible phone number with `tel:` link.
- Address line linked to Google Maps URL.
- Independence / years-in-business callout (only if sourced).

**Click-to-call wiring:**

- Every visible phone number is wrapped in `<a href="tel:+1<10digits>">`. The `+1` prefix is required.
- Every email is wrapped in `<a href="mailto:...">`.
- Every address is linked to the Google Maps URL.

**CTA copy:**

- No "Click here", no "Learn more", no "Submit", no "Continue" labels.
- Every CTA uses verb + object phrasing.

**Anti-patterns banned:**

- No exit-intent modal, no newsletter pop-up on first page load.
- No auto-play video or audio.
- No carousel hero on mobile.
- No cookie banner that blocks content interaction.

Findings reference: `cro.no-tel-link`, `cro.no-mailto`, `cro.fold-missing-element`, `cro.bottom-bar-missing`, `cro.bad-cta-label`, `cro.exit-intent-modal`, `cro.autoplay`, `cro.carousel-hero`.

### 8. Content guardrails

**Banned phrasings.** Scan every page's rendered text for the full banned-phrasings list from the pharmacy-builder contract:

- Marketing hyperbole: revolutionary, world-class, best-in-class, cutting-edge, state-of-the-art, industry-leading, premier, award-winning, voted #1, top-rated.
- Clinical / comparative claims: proven to, cures, guarantees, safest, fastest.
- Operational overreach: all insurance, any insurance, every insurance, 24-hour, 24/7, same-day delivery, free delivery.
- Credentials: board-certified, PharmD, RPh (unless verbatim in source).
- Comparative: unlike <named competitor>.
- Clinical-advice patterns: "you should take", "stop taking", "this means you have".

Allowed override: a banned phrase is permitted only if its exact wording appears verbatim in the build sheet or scrape (e.g., "FREE local delivery"). Cross-reference `build/context.json` when provided.

**PHI scan.** Greps every page's HTML for these `name="..."` patterns in form contexts: `dob`, `rx_number`, `member_id`, `medication`, `mrn`, `diagnosis`. Also flags `<input type="date">` inside `<form>` elements, and `<form>` elements whose `action` is not a fully qualified external URL.

**Clinical advice.** Confirm the site contains no instructions to take, stop, or change medications, no symptom interpretations, no diagnostic statements. The single allowed emergency phrasing is "Call 911 or go to the nearest emergency room." — and it appears only in emergency contexts.

**Factual fabrication.** When `build/context.json` is provided, cross-check every factual claim on the site (hours, address, phone, fax, email, staff, awards, credentials, services, insurance, years in business) against the context. Flag any claim that doesn't trace back to the build sheet or scrape.

Findings reference: `content.banned-phrase`, `content.phi-form-field`, `content.clinical-advice`, `content.fabricated-fact`.

### 9. Voice & readability

- Plain language: target Flesch-Kincaid ≥ 70 (8th-grade reading level or easier) per page body. Use a readability library or compute inline.
- Active voice predominant: passive constructions ≤ 20% of sentences.
- Second person: copy addresses the patient as "you", not third-person "patients".
- Warm but not casual: no slang, no flippancy, no overly clever phrasing.
- Practical: every paragraph answers what is this / how do I get it / what happens next.

Findings reference: `voice.readability-below-target`, `voice.passive-heavy`, `voice.third-person`, `voice.casual-tone`.

### 10. Visual quality

- Brand color (from build sheet hex) used consistently as primary accent. Same hex appears in CSS variables, theme-color meta, and OG image background.
- Typography pairing is coherent across pages. Body font supports the readability target. Display fonts accessible at the sizes used.
- Spacing rhythm: consistent vertical spacing scale. No squeezed or excessive whitespace.
- Single coherent icon set (Lucide / Heroicons / Phosphor / etc.). Same set in services grid AND header dropdown. No mixed icon families.
- Image quality: hero and storefront images at least 1200px wide, not visibly compressed.
- Logo placement, sizing, and contrast respect both light and dark backgrounds where it appears.
- Sticky bottom CTA bar is visually distinct from the page content beneath (backdrop blur or solid background with sufficient contrast).
- No image-only text for substantive content (headings, body copy, CTAs).
- Dark mode (if shipped) maintains WCAG AA contrast against the brand color; otherwise light mode only with a logged decision.

Findings reference: `visual.brand-color-inconsistent`, `visual.mixed-icon-sets`, `visual.low-res-image`, `visual.image-only-text`, `visual.dark-mode-contrast-fail`.

### 11. Performance & best practices

- Total page weight ≤ 1.5 MB for home, ≤ 1 MB for interior pages (uncompressed transfer size). Verify via DevTools network or `puppeteer.metrics`.
- Largest Contentful Paint ≤ 2.5s on a simulated 4G connection.
- Cumulative Layout Shift ≤ 0.1.
- All images use `loading="lazy"` except the hero image (which can use `loading="eager" fetchpriority="high"`).
- Images served in modern formats (AVIF or WebP) with fallbacks where needed.
- All images have explicit `width` and `height` attributes (or aspect-ratio CSS) to prevent layout shift.
- Fonts loaded with `font-display: swap` and preloaded if critical.
- No render-blocking third-party scripts above the fold.
- Compression: gzip or brotli enabled on the server (verify via `Content-Encoding` response header).
- HTTP/2 or HTTP/3 enabled (verify via response protocol).
- Cache headers set: `Cache-Control` on static assets ≥ 1 year with hashed filenames; HTML with shorter TTL.

Findings reference: `perf.page-weight`, `perf.lcp`, `perf.cls`, `perf.no-lazy-loading`, `perf.no-modern-image-format`, `perf.no-dimensions`, `perf.render-blocking`, `perf.no-compression`.

### 12. Security & privacy

- HTTPS only. No mixed-content warnings.
- `Strict-Transport-Security` header present with at least 6-month max-age.
- `Content-Security-Policy` header present. Inline scripts use nonces or hashes.
- `X-Content-Type-Options: nosniff` header present.
- `Referrer-Policy: strict-origin-when-cross-origin` or stricter.
- `X-Frame-Options: SAMEORIGIN` or `Content-Security-Policy: frame-ancestors 'self'`.
- Third-party scripts limited to what the build sheet authorized (e.g., GA ID, the head JS snippet). Flag anything else.
- No PHI exposed in URLs, cookies, localStorage, or sessionStorage.
- Cookie banner (if present) does not modal-block content and is dismissible.
- External links to Google Maps and other destinations use `rel="noopener noreferrer"`.

Findings reference: `sec.no-hsts`, `sec.no-csp`, `sec.no-nosniff`, `sec.no-referrer-policy`, `sec.mixed-content`, `sec.unauthorized-third-party`, `sec.phi-in-storage`, `sec.unsafe-external-link`, `sec.no-clickjacking-protection`.

**Clickjacking protection — explicit.** Either `X-Frame-Options: SAMEORIGIN` (or `DENY`) OR a `Content-Security-Policy` containing a `frame-ancestors` directive that restricts framing. At least one of these must be present. Both is better. A site with neither fails this check (Important severity by default; Critical if the site has any login or auth flow).

### 13. HIPAA compliance

Five checks, mirroring the highest-weighted grader category (25%). Every pharmacy site must satisfy all five.

**1. Privacy policy link.** A `/privacy/` page exists, returns HTTP 200, and is linked from the footer of every page. The link's visible text contains "Privacy Policy" or "Privacy Practices." The linked page contains the pharmacy's Notice of Privacy Practices (HIPAA-required) covering at minimum: how PHI is used and disclosed, patient rights, how to file a complaint with the pharmacy and with HHS, contact information for the pharmacy's Privacy Officer (or designated contact), and an effective date. Generic boilerplate without the pharmacy's actual contact details is a finding.

**2. HIPAA disclaimer on forms.** No public form on the site should collect PHI (per §PHI rules in the builder contract). If any form exists for non-PHI purposes (e.g., a contact-us request — which we also discourage), it must include a visible HIPAA disclaimer above the submit control with this exact pattern: "Do not submit Protected Health Information through this form. For prescription transfers, refills, or anything involving your medications, call us at `<phone>`." A form collecting PHI is a Critical finding regardless of disclaimer presence.

**3. Cookie consent banner.** A compact, dismissible cookie consent banner is present on first visit when any non-essential cookie or storage is used (e.g., GA wired via the build-sheet GA ID). Rules:

- Compact bottom banner — never a center-screen modal that blocks content interaction.
- Names the categories used: "Essential" plus "Analytics" if GA is wired. No mention of categories the site doesn't use.
- Provides Accept All, Reject Non-Essential, and a link to `/privacy/`. The Reject control must actually suppress non-essential cookies.
- Persists the user's choice (cookie or localStorage; never PHI; never linkable to the patient).
- Hidden after the choice is made; reappears only if the persisted choice expires or is cleared.
- Does not block keyboard navigation or screen reader access while visible.

A banner that modal-blocks content, or that has no Reject option, or that drops analytics cookies before consent, fails this check (Important by default; Critical if it blocks accessibility).

**4. HTTPS encryption.** Already verified in Dimension 12. Cross-listed here so the HIPAA category aggregates correctly. A site without HTTPS fails BOTH dimensions (Critical, Critical).

**5. No exposed patient data.** Already verified in Dimension 8 via the PHI scan and form-field checks. Cross-listed here so the HIPAA category aggregates correctly. Any exposed PHI fails BOTH dimensions (Critical, Critical).

**Notice of Privacy Practices content checks (the `/privacy/` page itself):**

- Headed "Notice of Privacy Practices" (or includes that phrase prominently).
- States the effective date.
- Names the Privacy Officer or designated contact with a phone or email.
- References the pharmacy's right to amend the notice and how patients will be notified.
- Includes the patient's right to: inspect and copy their record, request amendments, request restrictions, receive an accounting of disclosures, request confidential communications, and file a complaint with the pharmacy AND the U.S. Department of Health and Human Services Office for Civil Rights.
- Includes the HHS OCR complaint URL: `https://www.hhs.gov/ocr/privacy/hipaa/complaints/` (or the current canonical URL — verify it returns HTTP 200 from the audit base).
- Plain language consistent with §Voice in the builder contract.

Findings reference: `hipaa.no-privacy-policy`, `hipaa.privacy-policy-no-effective-date`, `hipaa.privacy-policy-no-contact`, `hipaa.privacy-policy-missing-patient-rights`, `hipaa.privacy-policy-no-ocr-link`, `hipaa.privacy-policy-not-linked-from-footer`, `hipaa.form-no-disclaimer`, `hipaa.no-cookie-banner`, `hipaa.cookie-banner-modal-blocking`, `hipaa.cookie-banner-no-reject`, `hipaa.cookie-banner-no-categories`, `hipaa.analytics-before-consent`.

## Scoring rubric

The grader that operators benchmark against scores six weighted categories. Every QA report must compute a 0–100 score per category, a weighted total, and a letter grade — alongside the dimension findings — so the operator can read the report next to the grader output and see them line up.

| Category | Weight | QA dimensions that feed it |
|---|---|---|
| HIPAA Compliance | 25% | Dimension 13 (primary); Dimensions 8 (PHI scan) + 12 (HTTPS) cross-listed |
| Accessibility | 20% | Dimension 2 |
| Performance | 20% | Dimension 11 |
| SEO | 20% | Dimension 3 (head metadata); Dimension 4 (schema.org JSON-LD); the site-wide-file accessibility checks from Dimension 5 |
| Usability | 10% | Dimension 6 (Mobile UX) + the responsive checks below |
| Security | 5% | Dimension 12 |

**Per-category scoring.** Each category starts at 100. Subtract for each finding referenced from a feeding dimension:

- Critical: −20
- Important: −10
- Minor: −2

Floor at 0. The result is the category score (0–100).

**Weighted total.** `weighted_total = Σ(category_score × weight) ÷ 100`. Floor 0, cap 100.

**Letter grade.** A ≥ 90; B 80–89; C 70–79; D 60–69; F < 60.

**Per-category check rendering.** The report must reproduce the grader's check-by-check breakdown (✓ pass, ✗ fail) so the two reports read side by side. Use these check names — they match the grader's labels verbatim:

*HIPAA Compliance:* HIPAA disclaimer on forms; Privacy policy link; Cookie consent banner; HTTPS encryption; No exposed patient data.

*Accessibility:* Image alt text; Skip-to-content link; ARIA landmarks; Form input labels; Focus indicators; Reduced motion support; HTML lang attribute.

*Performance:* Lighthouse performance score; Largest Contentful Paint (LCP); Cumulative Layout Shift (CLS); First Contentful Paint (FCP); Speed Index.

*SEO:* Title tag; Meta description; H1 heading; Schema.org structured data; Open Graph tags; Canonical URL; robots.txt; sitemap.xml.

*Usability:* Mobile viewport; Responsive design (media queries); Touch-friendly tap targets; Readable font size; No horizontal scroll.

*Security:* HTTPS; HSTS header; Clickjacking protection; Bot protection on forms; Content Security Policy.

**Grading thresholds the QA skill enforces.** A weighted total below 80 is a deployment blocker — flag the verdict to FAIL even if no individual dimension recorded a Critical finding. Aim for 90+. The pharmacy-builder skill is designed to produce a 95+ on a clean build.

## Tighter measurements for Performance, Usability, and Security

The grader is more specific than Dimensions 6, 11, and 12 were originally written. Augment those dimensions with these explicit metrics:

### Performance — Lighthouse-grade targets (Dimension 11 augmentation)

Run Lighthouse against every page (mobile and desktop) or a headless equivalent (`puppeteer` with `lighthouse` library). Required thresholds:

| Metric | Pass | Important | Critical |
|---|---|---|---|
| Lighthouse Performance score (mobile) | ≥ 90 | 80–89 | < 80 |
| Largest Contentful Paint (LCP) | ≤ 2.5s | 2.5–4.0s | > 4.0s |
| Cumulative Layout Shift (CLS) | ≤ 0.1 | 0.1–0.25 | > 0.25 |
| First Contentful Paint (FCP) | ≤ 1.8s | 1.8–3.0s | > 3.0s |
| Speed Index | ≤ 3.4s | 3.4–5.8s | > 5.8s |
| Total Blocking Time (TBT) | ≤ 200ms | 200–600ms | > 600ms |
| Time to Interactive (TTI) | ≤ 3.8s | 3.8–7.3s | > 7.3s |

Findings reference: `perf.lighthouse-score`, `perf.lcp`, `perf.cls`, `perf.fcp`, `perf.speed-index`, `perf.tbt`, `perf.tti`.

### Usability — responsive design checks (Dimension 6 augmentation)

Beyond the existing Mobile UX drawer/tap-target checks, the grader's Usability category demands these explicit responsive primitives. Audit each:

- **Mobile viewport meta tag.** `<meta name="viewport" content="width=device-width, initial-scale=1">` present on every page. Missing = Critical.
- **Responsive design (media queries).** At least one `@media` query present in the page's CSS. Mobile-first sites typically have several. Zero = Critical (signals a non-responsive site).
- **Touch-friendly tap targets.** Every interactive element has a hit area ≥ 44×44 CSS pixels at mobile widths (Apple HIG) or ≥ 48×48 (Material). Already in Dimension 6; surfaced here for the rubric.
- **Readable font size.** Body text computed font-size ≥ 16px on mobile. iOS auto-zooms input fields with font-size < 16px on focus — a UX defect.
- **No horizontal scroll on mobile.** At 320px viewport width, the document does not scroll horizontally. Inspect with `document.documentElement.scrollWidth <= window.innerWidth`. Common cause: missing `box-sizing: border-box` reset or a fixed-width element. Missing = Important.
- **Box-sizing reset.** Confirm CSS includes `*, *::before, *::after { box-sizing: border-box; }` or equivalent. Missing = Important (causes the horizontal scroll issue above).

Findings reference: `usability.no-viewport-meta`, `usability.no-media-queries`, `usability.tap-targets-small`, `usability.font-too-small`, `usability.horizontal-scroll`, `usability.no-box-sizing-reset`.

### Security — clickjacking protection and bot protection (Dimension 12 augmentation)

- **Clickjacking protection.** `X-Frame-Options: SAMEORIGIN` (or `DENY`) header OR a `Content-Security-Policy` containing `frame-ancestors` directive (`'self'` or `'none'`). Both is best. Neither = Important.
- **Bot protection on forms.** If any form exists (even a non-PHI contact form, which we discourage), it includes either: hCaptcha / reCAPTCHA / Cloudflare Turnstile invisible challenge OR a honeypot field. The pharmacy-builder default of no forms passes this trivially.
- **Subresource integrity (SRI).** Externally-hosted scripts and stylesheets include `integrity="sha384-..."` and `crossorigin="anonymous"` attributes. Without SRI, a CDN compromise becomes an XSS vector. Missing on a third-party script = Important.
- **Permissions Policy.** `Permissions-Policy` header (or `Feature-Policy` legacy name) restricts unused browser features (camera, microphone, geolocation, USB, payment). The pharmacy site needs none of those; the policy should deny them all. Missing = Minor (defense in depth).

Findings reference: `sec.no-clickjacking-protection`, `sec.no-sri-on-external-script`, `sec.no-permissions-policy`, `sec.no-bot-protection`.

## Imagery and layout audit

In addition to the dimension-by-dimension checks, every audit runs these focused image, logo, hours, and nav checks. Findings roll into Dimension 1 (Pages & structure) for the score rubric.

**Hero image.**

- The home-page hero must depict a pharmacist serving a patient. Verify by visual inspection or vision-model classification of the hero image. Stock photography of generic happy seniors, pill bottles on a counter, or an exterior storefront fails this check (Critical for the home page hero specifically). The hero is the trust signal; getting it wrong is high-impact.

**Service page images.**

- Every per-service page has a header image. Missing = Important (`pages.service-image-missing`).
- Images are served from the same origin — no hotlinks to Unsplash CDN, Google CDN, or any third-party image host (Important `pages.hotlinked-stock-image`). Check by inspecting every `<img src>` and confirming the host matches the audit base origin.
- Unsplash images include photographer attribution somewhere on the page (footer or near the image). Missing attribution on a known-stock image is Minor.
- AI-generated exterior shots of the pharmacy: flag any image classified as `exterior` whose provenance in `build/image-manifest.json` is `ai_generated` — Critical (`pages.fabricated-exterior-shot`).

**Hours format.**

- Every rendered hours string matches the pattern `H:MM AM – H:MM PM` (12-hour clock, leading zeros on minutes, uppercase AM/PM with no periods, en-dash or hyphen separator surrounded by single spaces). Specifically reject: `a.m.` / `p.m.` lowercase with periods; single-digit hours without minutes (`9 AM`); 24-hour format (`09:00`); missing leading zero on minutes (`9:0 AM`); missing separator. Each violation = Important (`pages.hours-format-invalid`).

**Logo rendering.**

- Footer logo renders on EVERY page (not just home). Missing on any page = Important (`pages.footer-logo-missing`).
- Header logo computed height between 32px and 64px on desktop; between 28px and 56px on mobile. Below the floor = Important (`pages.logo-too-small`); above the ceiling = Minor.
- Logo is the home link. Clicking the logo navigates to `/` or the base URL. The logo's `<a>` wrapper must have an accessible name (alt text on the inner `<img>` satisfies this if the parent is the only link).
- Header primary nav must NOT contain a "Home" link. Detect by scanning the `<header>` `<nav>` for any link whose visible text is "Home" or whose `href` is `/`. Either is Minor.

**App vs Portal exclusivity.**

- Scan every page for "Patient Portal" CTAs and "Get the App" / Apple App Store / Google Play badges. The site uses one set or the other, never both. Both = Critical.
- Cross-check with `build/context.json`: if `Requires Mobile App Page: Yes`, the site must surface App CTAs and the `/app/` page must exist; if no, the site must surface Patient Portal CTAs (when `Patient Portal URL` is present) and no `/app/` page exists.

**Reviews section.**

- The home page contains a Reviews section with at least one "Leave a Review" CTA. Missing = Important.
- The "Leave a Review" CTA's `href` matches the build-sheet `Reviews URL` field exactly (when present). Mismatch = Important.
- Review cards (when rendered) use first name + last initial; full last names are flagged as a privacy-best-practice issue = Minor (`pages.review-full-name`).
- No fabricated reviews: every review card's text and reviewer name must trace to a real source (build sheet, scrape, or named review platform). Fabrication = Critical (rolls into Dimension 8 too).

## Best practices

Beyond the strict contract, audit for these heuristics. These are not pass/fail gates — they produce **WARN-level** findings unless severe.

- **Local SEO completeness.** Confirm the LocalBusiness/Pharmacy schema includes `priceRange` (e.g., "$$"), `paymentAccepted` (sourced from build sheet only), and `currenciesAccepted: "USD"`.
- **Google Business Profile signal alignment.** Pharmacy name, address, and phone (NAP) must be byte-identical to the build sheet across the site, schema, and any visible footer. Variation hurts local SEO.
- **Mobile-first content.** Critical text (hero headline, primary CTA, phone number) renders in the first 100kb of HTML so it appears before render-blocking resources.
- **Accessibility beyond AA.** Bonus credit (not a gate): `prefers-color-scheme` support, `prefers-contrast: more` support, `prefers-reduced-motion` honored across all animations.
- **Resilience.** Site degrades gracefully without JS — the top bar shows "Open/Closed unavailable" rather than nothing, the hamburger menu's content is reachable via a fallback link, all `<a>` elements work without JS.
- **Trust positioning.** Phone number, address, hours, and "Open now" indicator visible on every page (in top bar or header), not just on contact.
- **Schema linking.** Every `Service` / `MedicalProcedure` / `MedicalTherapy` / `MedicalTest` node references the `Pharmacy` node via `provider` with a stable `@id`. The Pharmacy node's `availableService` array references those same `@id`s, not duplicated nodes.
- **Image alt-text quality.** Substantive image alts go beyond "image of X" — they describe object + context (e.g., "Pharmacist counseling a patient at the pharmacy counter").
- **FAQ depth.** Each FAQ section has at least 3 Q&A pairs sourced from the build sheet, QA doc, or scrape. Too-thin FAQ sections (1–2 Q&As) suggest the source wasn't mined fully.
- **CTA hierarchy.** Primary CTA is visually dominant; secondary CTA is outlined/ghost-style; tertiary actions are text-link style. No two CTAs compete for the same visual weight.
- **Testimonial diversity.** If testimonials are present, they reference different services / staff / aspects of the pharmacy — not five quotes all praising the same thing. (Only when source supports this.)
- **404 page.** A custom 404 page exists with the sticky header, top bar, search? — no, there's no on-site search — a clear "page not found" message, and links to Home / Contact / Services. Confirm by requesting a known-bad URL.
- **Print stylesheet.** Optional but recommended: a minimal print stylesheet that hides sticky headers / drawers and preserves contact info and hours.

Findings under best practices use the prefix `best.<dimension>.<rule>` (e.g., `best.local-seo.no-price-range`, `best.404.missing`).

## Audit process

Run the audit in five steps, mirroring the builder's process. Each step writes an artifact under `audit/`.

### Step 1 — Resolve

**Input:** URL or local path.

**Action:** Validate the input. If a URL, follow up to 2 redirects and capture the final base. If a local path, start a local HTTP server. Discover all pages: prefer `<base>/sitemap.xml`, fall back to crawling internal links from the home page up to depth 3.

**Exit criteria:** `audit/scope.json` exists with base URL, discovered page list, and timestamp. The base URL returns 200.

**Failure mode:** If neither URL nor path resolves, hard fail and write the reason to `audit/scope.json`.

### Step 2 — Fetch

**Input:** `audit/scope.json`.

**Action:** Fetch every page's HTML, every site-wide file (`robots.txt`, `sitemap.xml`, `llms.txt`), every referenced asset (CSS, JS, fonts, images), and capture the rendered DOM (use a headless browser for accurate rendering — `puppeteer` recommended). Save raw responses to `audit/raw/<slug>.html` and rendered DOMs to `audit/rendered/<slug>.html`. Capture network metrics per page (request count, transfer size, LCP, CLS) to `audit/metrics/<slug>.json`.

**Exit criteria:** `audit/raw/`, `audit/rendered/`, `audit/metrics/` populated. Every page in `scope.json` has both raw and rendered captures.

**Failure mode:** If a page returns non-200, log the status in `audit/scope.json` and continue with the remaining pages. A 404 on a required page becomes a critical finding in dimension 1.

### Step 3 — Check

**Input:** `audit/raw/`, `audit/rendered/`, `audit/metrics/`, optional `build/context.json`.

**Action:** Run each of the thirteen audit dimensions in order (Dimensions 1–12 plus 13 HIPAA Compliance). Apply the augmented Performance / Usability / Security checks from the Tighter measurements section. For each finding, capture: dimension, severity (Critical / Important / Minor), page URL, DOM selector or file:line, the offending value, the recommended fix. Write findings to `audit/findings.jsonl` as one JSON object per line.

Severity guidance:

- **Critical** — site is broken or violates a hard contract: required page missing, JSON-LD parse failure, PHI form field present, banned phrasing on rendered page, HTTPS missing, sitemap.xml unparseable.
- **Important** — affects user experience, conversions, or SEO meaningfully: a11y violations of WCAG AA, missing canonical, low contrast, broken sitemap URL, mobile menu without focus trap.
- **Minor** — quality issue but not breaking: best-practice recommendations, suggestions, polish gaps.

**Exit criteria:** `audit/findings.jsonl` written. Every dimension has at minimum a dimension-level pass/warn/fail summary recorded.

**Failure mode:** A check that can't run (e.g., a11y validator crashed) is logged with status `error` and treated as a critical finding so the audit can't silently skip it.

### Step 4 — Render report

**Input:** `audit/findings.jsonl`.

**Action:** Aggregate findings into a single markdown report at `audit/report.md`. Use the report format below. Also emit `audit/report.json` with the same structured data for machine consumption. Compute the six grader-style scores per the §Scoring rubric, the weighted total, and the letter grade — these appear at the top of the report next to the verdict.

**Exit criteria:** Both files exist. The summary table is complete. Every finding is referenced in the body.

**Failure mode:** If the report can't be assembled (e.g., findings file corrupted), halt and surface the error — never declare the audit done.

### Step 5 — Verdict

**Input:** `audit/report.md`.

**Action:** Compute the overall verdict using BOTH the severity rule and the score rule:

- **PASS** if zero Critical findings, zero Important findings, AND weighted total ≥ 90.
- **PASS WITH WARNINGS** if zero Critical, any Important, any Minor, AND weighted total ≥ 80.
- **FAIL** if any Critical findings OR weighted total < 80.

The score threshold backstops the severity rule — a site that accumulates many Minor findings can still drop the weighted total below 80 even with no Critical or Important findings, and that becomes a FAIL by score.

Append the verdict to the top of `audit/report.md` and the JSON file. Reproduce the closing audit checklist (below) in `/audit/log.md` with each box checked or marked with the relevant finding ID.

**Exit criteria:** Verdict appears at the top of the report. Checklist reproduced. Audit closed.

**Failure mode:** Any inconsistency between findings count and verdict halts the audit (no "PASS" with critical findings allowed).

## Report format

`audit/report.md` follows this exact structure:

```markdown
# Pharmacy Site Audit Report

**Site:** <base URL>
**Date:** <YYYY-MM-DD HH:MM>
**Auditor:** pharmacy-qa skill
**Pages audited:** <count>
**Verdict:** PASS | PASS WITH WARNINGS | FAIL
**Weighted score:** <0–100>  **Grade:** A | B | C | D | F

## Score breakdown (grader rubric)

| Category | Score | Grade | Weight |
|---|---|---|---|
| HIPAA Compliance | <0–100> | <A–F> | 25% |
| Accessibility | <0–100> | <A–F> | 20% |
| Performance | <0–100> | <A–F> | 20% |
| SEO | <0–100> | <A–F> | 20% |
| Usability | <0–100> | <A–F> | 10% |
| Security | <0–100> | <A–F> | 5% |
| **Weighted total** | **<0–100>** | **<A–F>** | 100% |

### HIPAA Compliance details

- <✓ or ✗> HIPAA disclaimer on forms: <evidence>
- <✓ or ✗> Privacy policy link: <evidence>
- <✓ or ✗> Cookie consent banner: <evidence>
- <✓ or ✗> HTTPS encryption: <evidence>
- <✓ or ✗> No exposed patient data: <evidence>

### Accessibility details

- <✓ or ✗> Image alt text
- <✓ or ✗> Skip-to-content link
- <✓ or ✗> ARIA landmarks
- <✓ or ✗> Form input labels
- <✓ or ✗> Focus indicators
- <✓ or ✗> Reduced motion support
- <✓ or ✗> HTML lang attribute

### Performance details

- <✓ or ✗> Lighthouse performance score: <NN>/100 (mobile)
- <✓ or ✗> Largest Contentful Paint (LCP): <s>
- <✓ or ✗> Cumulative Layout Shift (CLS): <value>
- <✓ or ✗> First Contentful Paint (FCP): <s>
- <✓ or ✗> Speed Index: <s>

### SEO details

- <✓ or ✗> Title tag
- <✓ or ✗> Meta description
- <✓ or ✗> H1 heading
- <✓ or ✗> Schema.org structured data
- <✓ or ✗> Open Graph tags
- <✓ or ✗> Canonical URL
- <✓ or ✗> robots.txt
- <✓ or ✗> sitemap.xml

### Usability details

- <✓ or ✗> Mobile viewport
- <✓ or ✗> Responsive design (media queries)
- <✓ or ✗> Touch-friendly tap targets
- <✓ or ✗> Readable font size
- <✓ or ✗> No horizontal scroll

### Security details

- <✓ or ✗> HTTPS
- <✓ or ✗> HSTS header
- <✓ or ✗> Clickjacking protection
- <✓ or ✗> Bot protection on forms
- <✓ or ✗> Content Security Policy

## Summary (per QA dimension)

| Dimension | Status | Critical | Important | Minor |
|---|---|---|---|---|
| 1. Pages & structure | ... | 0 | 0 | 0 |
| 2. Accessibility | ... | 0 | 0 | 0 |
| 3. SEO | ... | 0 | 0 | 0 |
| 4. Schema | ... | 0 | 0 | 0 |
| 5. Site-wide files | ... | 0 | 0 | 0 |
| 6. Mobile UX | ... | 0 | 0 | 0 |
| 7. Conversion | ... | 0 | 0 | 0 |
| 8. Content guardrails | ... | 0 | 0 | 0 |
| 9. Voice & readability | ... | 0 | 0 | 0 |
| 10. Visual quality | ... | 0 | 0 | 0 |
| 11. Performance | ... | 0 | 0 | 0 |
| 12. Security & privacy | ... | 0 | 0 | 0 |
| 13. HIPAA compliance | ... | 0 | 0 | 0 |

## Findings

### Critical

<numbered list of every Critical finding with: id, dimension reference, page, selector/file:line, offending value, recommended fix>

### Important

<numbered list>

### Minor

<numbered list>

## Best practices

<numbered list of best-practice findings>

## Pages audited

<table of every page URL with: HTTP status, byte size, LCP, CLS, findings count>

## Methodology

<one paragraph naming the audit base, the tools used (browser, axe, schema validator, readability lib), the date and version of the QA skill>
```

`audit/report.json` mirrors this with the same data in structured form for machine consumption:

```json
{
  "site": "...",
  "date": "...",
  "version": "...",
  "verdict": "PASS | PASS_WITH_WARNINGS | FAIL",
  "summary": { "byDimension": [ ... ] },
  "findings": [ { "id": "...", "dimension": "...", "severity": "...", "page": "...", "selector": "...", "offending": "...", "fix": "..." } ],
  "pages": [ { "url": "...", "status": 200, "bytes": ..., "lcp": ..., "cls": ... } ]
}
```

## Closing audit checklist

Before declaring the audit complete, you must reproduce this checklist in `/audit/log.md` with each box checked or annotated with a finding ID.

```
SCOPE
[ ] Input resolved (URL or local path); audit/scope.json written
[ ] Page list discovered via sitemap or crawl; pages count recorded
FETCH
[ ] Every page captured: raw HTML + rendered DOM + metrics
[ ] robots.txt, sitemap.xml, llms.txt fetched
CHECKS — all twelve dimensions ran
[ ] 1. Pages & structure
[ ] 2. Accessibility (WCAG 2.2 AA)
[ ] 3. SEO metadata
[ ] 4. Schema (JSON-LD)
[ ] 5. Site-wide files (robots.txt, sitemap.xml, llms.txt)
[ ] 6. Mobile UX
[ ] 7. Conversion patterns
[ ] 8. Content guardrails (banned phrasings, PHI scan, clinical advice, fabricated facts)
[ ] 9. Voice & readability
[ ] 10. Visual quality
[ ] 11. Performance & best practices
[ ] 12. Security & privacy
[ ] 13. HIPAA compliance
SCORING
[ ] Six grader-category scores computed (HIPAA 25%, A11y 20%, Perf 20%, SEO 20%, Usability 10%, Security 5%)
[ ] Weighted total and letter grade computed
[ ] Per-category check breakdown rendered with ✓ / ✗ matching grader labels verbatim
BEST PRACTICES
[ ] Best-practices heuristics ran and were captured as WARN-level findings
REPORT
[ ] audit/report.md generated with summary table and findings sections
[ ] audit/report.json generated as machine-readable mirror
[ ] Verdict computed correctly (PASS / PASS WITH WARNINGS / FAIL)
[ ] Verdict matches finding counts (no "PASS" with critical findings)
RESULT
[ ] Audit complete; report delivered to operator
```

Any unchecked or unannotated box = audit not done.
