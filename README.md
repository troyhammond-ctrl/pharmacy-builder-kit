# pharmacy-builder-kit

Two paired skills for building and auditing pharmacy websites:

- **[`SKILL.md`](SKILL.md)** — the **builder**. Instructs Replit Agent (or Claude) to build a clean, modern, accessible, factually faithful pharmacy site from a build folder.
- **[`QA-SKILL.md`](QA-SKILL.md)** — the **auditor**. Takes a built pharmacy site (URL or local path) and produces a structured findings report across twelve audit dimensions, with severity-tagged issues and recommended fixes.

Both skills are stack-agnostic — they tell the agent what the output must satisfy, not how to build it.

> 📘 **New here?** See [`docs/replit-quickstart.md`](docs/replit-quickstart.md) for the end-to-end Replit walkthrough: import → build folder → drive the five-step build → audit → preview → deploy → troubleshoot.

## What's in this repo

| Path | Purpose |
|---|---|
| `SKILL.md` | The **builder** skill. Paste into Replit Agent as a system prompt or commit into your Replit project as a skill. |
| `QA-SKILL.md` | The **auditor** skill. Run against a built site (URL or path) for an independent second-opinion audit covering pages, a11y, SEO, schema, robots/sitemap/llms, mobile UX, conversion, content guardrails, voice, visual quality, performance, and security. |
| `README.md` | This file. |
| `docs/replit-quickstart.md` | Step-by-step Replit operator guide (import, build, audit, deploy, troubleshoot). |
| `docs/superpowers/specs/` | Design spec the builder SKILL.md was built from. Authoritative for any future revisions. |
| `docs/superpowers/plans/` | Implementation plan used to build the SKILL.md. |
| `tests/` | Shell-based structural tests that verify both SKILL.md and QA-SKILL.md satisfy their contracts. |

## How to use it

1. Assemble a **build folder** for the pharmacy. At minimum it must contain:
   - A build sheet (`.docx`) whose filename contains `Build Sheet`.
   - A logo file (PNG / JPG / SVG) — either in the folder root, or fetched from the `Logo:` URL in the build sheet.
2. Optionally include any of: `Website content*.docx`, `QA *.docx`, `SEO_META_Tags_*.docx`, and any additional photos / PDFs / videos. The skill auto-detects them.
3. In Replit, open or create the project. Paste the contents of `SKILL.md` as the agent's system prompt (or place the file in `.replit/skills/` if your Replit instance supports loaded skills).
4. Tell the agent the path to the build folder. The skill drives the rest:
   - **Discover** — parses the build sheet into `build/context.json`.
   - **Scrape** — mirrors the pharmacy's existing live site (per the `Website URL` field) into `/scraped/`.
   - **Plan** — writes `/build/page-plan.json` enumerating every page and section.
   - **Generate** — scaffolds the project (agent picks the stack), generates each page, writes `robots.txt`/`sitemap.xml`/`llms.txt`.
   - **Validate** — runs three validators (content guardrails, accessibility, schema) and reproduces the closing QA checklist in `/build/log.md`.
5. Inspect `/build/log.md`. **If any box is unchecked, the build is not done.**

## Guarantees the skill enforces

- No fabricated facts (hours, address, phone, staff, credentials, licenses, services, insurance, awards, etc.).
- No PHI collection of any kind on public forms.
- WCAG 2.2 AA accessibility baseline (single H1, landmarks, skip-link, visible focus, AA contrast, keyboard-operable services dropdown).
- Per-page SEO baseline (title, description, canonical, OG, Twitter card, single H1).
- JSON-LD schema on every page (Pharmacy/LocalBusiness, WebPage, BreadcrumbList, FAQPage, plus Service / ContactPoint / MobileApplication where relevant).
- `robots.txt` + `sitemap.xml` + `llms.txt` always generated.
- No marketing hyperbole, no comparative claims, no clinical advice. Banned-phrasing scan fails the build on any hit.

## Verifying the SKILL.md after edits

Any change to `SKILL.md` must keep the structural tests passing:

```sh
bash tests/run.sh
```

The tests are grep-based and live under `tests/`. They check that every required contract section, banned phrasing, schema type, accessibility rule, and checklist line item is present.

## Maintaining the skill

The skill's design is captured in `docs/superpowers/specs/2026-05-20-pharmacy-builder-skill-design.md`. If you want to change a rule (e.g., add a new banned phrasing, expand the schema catalog, change the open-now indicator's fallback text):

1. Update the spec.
2. Update or add the corresponding test under `tests/`.
3. Update `SKILL.md` to satisfy the new test.
4. Run `bash tests/run.sh` to verify the whole suite is green.
5. Commit the spec, test, and SKILL.md changes together.
