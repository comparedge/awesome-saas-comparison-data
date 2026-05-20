# Awesome SaaS Comparison Data

> Machine-readable pricing, ratings & feature data for **508 software tools** across AI, Business, Security & Crypto. Verified by humans. Updated weekly. CC BY 4.0.

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
[![Tools](https://img.shields.io/badge/Tools-508-3b82f6?style=flat-square)](https://comparedge.com/tools)
[![Categories](https://img.shields.io/badge/Categories-44-10b981?style=flat-square)](https://comparedge.com/best)
[![With Pricing](https://img.shields.io/badge/With_Pricing-508_(100%25)-a855f7?style=flat-square)](https://comparedge.com/pricing)
[![Free Plans](https://img.shields.io/badge/Free_Plans-320-f59e0b?style=flat-square)](https://comparedge.com/tools)
[![G2 Rated](https://img.shields.io/badge/G2_Rated-481-ef4444?style=flat-square)](https://comparedge.com)
[![MCP Server](https://img.shields.io/badge/MCP_Server-Available-a855f7?style=flat-square&logo=anthropic)](https://smithery.ai/server/@comparedge/mcp-server)
[![mcp-server-comparedge MCP server](https://glama.ai/mcp/servers/comparedge/mcp-server-comparedge/badges/score.svg)](https://glama.ai/mcp/servers/comparedge/mcp-server-comparedge)

---

## What This Is

This is the open dataset powering [ComparEdge](https://comparedge.com) — an independent software comparison platform with no affiliate revenue and no sponsored rankings.

Every pricing record in this dataset has been manually verified or algorithmically checked against vendor pricing pages. All ratings reference a live source URL (G2 or Capterra). No invented data.

**[Browse the full dataset at comparedge.com/open-data →](https://comparedge.com/open-data)**

---

## Dataset Stats (May 2026)

| Metric | Value |
|--------|-------|
| Total products | **508** |
| Categories | **44** |
| Products with pricing plans | **508 (100%)** |
| Products with free plan | **320 (63%)** |
| Products with G2 rating | **481** — avg **4.45** |
| Products with Capterra rating | **375** |
| G2 source URLs tracked | **447** |
| All records verified | **508 (100%)** |
| Data license | CC BY 4.0 |
| Update frequency | Weekly |

---

## Schema

### Product Entry

```json
{
  "name": "Cursor",
  "slug": "cursor",
  "category": "ai-coding",
  "website": "https://cursor.sh",
  "pricing": {
    "free": true,
    "plans": [
      { "name": "Hobby", "price": 0, "period": "mo", "highlights": ["..."] },
      { "name": "Pro", "price": 20, "period": "mo", "highlights": ["..."] },
      { "name": "Business", "price": 40, "period": "user/mo", "highlights": ["..."] }
    ],
    "hasFree": true,
    "startingPrice": 0
  },
  "rating": {
    "g2": 4.7,
    "capterra": 4.6
  },
  "g2_url": "https://www.g2.com/products/cursor/reviews",
  "verifiedAt": "2026-05-17T00:00:00.000Z",
  "pricingAnalysis": {
    "tier": "freemium",
    "startingPrice": 0,
    "priceRange": "$0–$40/user/mo"
  }
}
```

---

## Coverage by Domain

| Domain | Categories | Products | Free Plans | G2 Rated |
|--------|-----------|----------|------------|----------|
| AI & LLM | 11 | 143 | 81 | 138 |
| Business SaaS | 15 | 221 | 142 | 209 |
| Security & Infrastructure | 9 | 96 | 51 | 88 |
| Crypto & Web3 | 6 | 48 | 46 | 46 |
| **Total** | **44** | **508** | **320** | **481** |

### Top Categories by Product Count

| Category | Products |
|----------|----------|
| LLMs & Foundation Models | 30 |
| Cloud Hosting | 24 |
| Website Builders | 23 |
| Project Management | 20 |
| Email Marketing | 20 |
| Video Conferencing | 19 |
| CRM | 18 |
| Design Tools | 18 |
| AI Productivity | 18 |
| AI Coding | 17 |

---

## AI / MCP Integration

Query this dataset from any MCP-compatible AI agent (Claude, Cursor, Windsurf, etc.):

```bash
npx @smithery/cli install @comparedge/mcp-server --client claude
```

```python
# Available MCP tools
search_products(query, category, limit)     # full-text search
get_pricing(slug)                           # verified pricing plans
get_alternatives(slug, limit)              # ranked alternatives
compare_products(slug_a, slug_b)           # head-to-head
get_category(category, sort_by)            # full category list
```

[![Smithery](https://img.shields.io/badge/Install_via_Smithery-a855f7?style=flat-square&logo=anthropic&logoColor=white)](https://smithery.ai/server/@comparedge/mcp-server)
[![npm](https://img.shields.io/badge/npm_Package-CB3837?style=flat-square&logo=npm&logoColor=white)](https://www.npmjs.com/package/@comparedge/mcp-server)
[![mcp-server-comparedge MCP server](https://glama.ai/mcp/servers/comparedge/mcp-server-comparedge/badges/score.svg)](https://glama.ai/mcp/servers/comparedge/mcp-server-comparedge)

Other integrations:

| Integration | Repo |
|------------|------|
| LangChain | [langchain-comparedge](https://github.com/comparedge/langchain-comparedge) |
| LlamaIndex | [llamaindex-comparedge](https://github.com/comparedge/llamaindex-comparedge) |
| GitHub Action | [saas-price-check](https://github.com/comparedge/saas-price-check) |
| Terraform | [terraform-comparedge-saas](https://github.com/comparedge/terraform-comparedge-saas) |

---

## Data Quality

```
Source validation     All pricing from public vendor pages — no estimates
Rating policy         G2 > Capterra (strict priority); only shown with source URL
Verification status   verifiedAt timestamp on every product
Update cadence        Weekly crawl + human spot-checks for >$100/mo products
Confidence signal     pricingAnalysis.tier (freemium | flat | usage | enterprise)
No affiliate data     Zero commission links, zero sponsored entries
```

---

## Platform Links

| Resource | URL |
|----------|-----|
| Open Data Explorer | [comparedge.com/open-data](https://comparedge.com/open-data) |
| Browse all tools | [comparedge.com/tools](https://comparedge.com/tools) |
| Compare two tools | [comparedge.com/compare](https://comparedge.com/compare) |
| Pricing breakdowns | [comparedge.com/pricing](https://comparedge.com/pricing) |
| Alternatives finder | [comparedge.com/alternatives](https://comparedge.com/alternatives) |
| LLM API Calculator | [comparedge.com/llm-calculator](https://comparedge.com/llm-calculator) |
| Stack Builder | [comparedge.com/tech-stack-builder](https://comparedge.com/tech-stack-builder) |
| Security Hub | [comparedge.com/security](https://comparedge.com/security) |
| Blog | [comparedge.com/blog](https://comparedge.com/blog) |

---

## License

Data licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Attribution: **"Data from ComparEdge (comparedge.com)"**

---

*Independent. No affiliate revenue. No sponsored rankings. Data-first.*

[comparedge.com](https://comparedge.com) · [@ComparEdge](https://x.com/ComparEdge)
