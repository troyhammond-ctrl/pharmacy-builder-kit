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

pass "11-seo"
