#!/usr/bin/env bash
# tests/11-seo.sh
set -euo pipefail
source "$(dirname "$0")/lib/check.sh"

# Head elements
assert_contains "<title>" "11-seo:title"
assert_contains "60 chars" "11-seo:title-length"
assert_contains "<meta name=\"description\">" "11-seo:description"
assert_contains "140" "11-seo:description-min"
assert_contains "160" "11-seo:description-max"
assert_contains "<link rel=\"canonical\"" "11-seo:canonical"
assert_contains "New Website URL" "11-seo:canonical-root"
assert_contains "Open Graph" "11-seo:open-graph"
assert_contains "og:title" "11-seo:og-title"
assert_contains "og:description" "11-seo:og-description"
assert_contains "og:url" "11-seo:og-url"
assert_contains "og:type" "11-seo:og-type"
assert_contains "og:image" "11-seo:og-image"
assert_contains "1200x630" "11-seo:og-image-size"
assert_contains "twitter:card" "11-seo:twitter-card"
assert_contains "theme-color" "11-seo:theme-color"

# SEO_META doc verbatim use
assert_contains "SEO_META_Tags" "11-seo:seo-meta-doc"
assert_contains "verbatim" "11-seo:verbatim"

# Site-wide files
assert_contains "robots.txt" "11-seo:robots"
assert_contains "sitemap.xml" "11-seo:sitemap"
assert_contains "llms.txt" "11-seo:llms"
assert_contains "lastmod" "11-seo:lastmod"

# robots.txt concrete content
assert_contains "User-agent: *" "11-seo:robots-user-agent"
assert_contains "Allow: /" "11-seo:robots-allow"
assert_contains "no BOM" "11-seo:no-bom"
assert_contains "LF line endings" "11-seo:lf-line-endings"

# sitemap.xml validity
assert_contains 'xmlns="http://www.sitemaps.org/schemas/sitemap/0.9"' "11-seo:sitemap-namespace"
assert_contains '<?xml version="1.0" encoding="UTF-8"?>' "11-seo:xml-declaration"
assert_contains "<urlset" "11-seo:urlset"
assert_contains "<changefreq>" "11-seo:changefreq"
assert_contains "&amp;" "11-seo:ampersand-escape"

# llms.txt spec compliance
assert_contains "llmstxt.org" "11-seo:llmstxt-spec-link"
assert_contains "## Information" "11-seo:llms-information-section"
assert_contains "## Optional" "11-seo:llms-optional-section"
assert_contains "Required blockquote" "11-seo:llms-blockquote-required"

# size-report.json (folded-in website-migration skill)
assert_contains "size-report.json" "11-seo:size-report-file"
assert_contains "root of the deployed output" "11-seo:size-report-location"
assert_contains "hosting-cost estimation" "11-seo:size-report-rationale"
assert_contains "generatedAt" "11-seo:size-report-generated-at"
assert_contains "outputDir" "11-seo:size-report-output-dir"
assert_contains "totalBytes" "11-seo:size-report-total-bytes"
assert_contains "totalFiles" "11-seo:size-report-total-files"
assert_contains "byType" "11-seo:size-report-by-type"
for cat in html css js images fonts other; do
  assert_contains "\`$cat\`" "11-seo:size-report-cat-$cat"
done
assert_contains "scripts/size-report.mjs" "11-seo:size-report-script"
assert_contains "State the totals in the final summary" "11-seo:size-report-summary"

# Security headers (server config)
assert_contains "Security headers" "11-seo:security-headers-section"
assert_contains "Strict-Transport-Security" "11-seo:hsts"
assert_contains "max-age=63072000" "11-seo:hsts-2yr"
assert_contains "includeSubDomains" "11-seo:hsts-subdomains"
assert_contains "Content-Security-Policy" "11-seo:csp"
assert_contains "frame-ancestors" "11-seo:csp-frame-ancestors"
assert_contains "X-Content-Type-Options: nosniff" "11-seo:xcto"
assert_contains "X-Frame-Options: SAMEORIGIN" "11-seo:xfo"
assert_contains "Referrer-Policy: strict-origin-when-cross-origin" "11-seo:referrer-policy"
assert_contains "Permissions-Policy" "11-seo:permissions-policy"
assert_contains "camera=()" "11-seo:permissions-camera-denied"

# Performance budget (Lighthouse targets)
assert_contains "Performance budget" "11-seo:perf-budget-section"
assert_contains "Performance score ≥ 90" "11-seo:perf-lighthouse-target"
assert_contains "LCP) ≤ 2.5s" "11-seo:perf-lcp"
assert_contains "CLS) ≤ 0.1" "11-seo:perf-cls"
assert_contains "FCP) ≤ 1.8s" "11-seo:perf-fcp"
assert_contains "Speed Index ≤ 3.4s" "11-seo:perf-speed-index"
assert_contains "TBT" "11-seo:perf-tbt"

# CSS responsiveness rules in Visual design
assert_contains "box-sizing: border-box" "11-seo:css-box-sizing-builder"
assert_contains "font-size ≥ 16px" "11-seo:css-font-min-builder"
assert_contains "320px viewport" "11-seo:css-320-builder"

pass "11-seo"
