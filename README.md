# 📊 Awesome SaaS Comparison Data

> **Curated pricing, ratings & feature data** for 508+ software tools across AI, Business, Security & Crypto categories. Machine-readable formats. Updated weekly.

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
[![Tools: 508](https://img.shields.io/badge/Tools-508-blue.svg)](https://comparedge.com/tools)
[![Categories: 45](https://img.shields.io/badge/Categories-45-green.svg)](https://comparedge.com/best)
[![Updated: May 2026](https://img.shields.io/badge/Updated-May%202026-orange.svg)](https://comparedge.com)

---

## Why This Exists

Choosing the right software tool shouldn't require visiting 30 different pricing pages. We maintain a curated, machine-readable dataset so developers, analysts, and founders can make data-driven decisions.

This repository contains a **curated subset** of the full database powering [ComparEdge](https://comparedge.com) — an independent software comparison platform covering 508+ tools across 45 categories.

## 📁 Data Structure

```
data/
├── ai-tools/                    # AI & Machine Learning (12 categories)
│   ├── llm-pricing-2026.json           # ChatGPT, Claude, Gemini, Llama...
│   ├── ai-coding-pricing-2026.json     # Cursor, GitHub Copilot, Windsurf...
│   ├── ai-writing-pricing-2026.json    # Jasper, Copy.ai, Writesonic...
│   ├── ai-image-pricing-2026.json      # Midjourney, DALL-E 3, Stable Diffusion...
│   ├── ai-video-pricing-2026.json      # Runway, Pika, Synthesia...
│   ├── ai-voice-pricing-2026.json      # ElevenLabs, Play.ht, Murf...
│   ├── ai-agents-pricing-2026.json     # AutoGPT, CrewAI, LangChain...
│   ├── ai-productivity-pricing-2026.json
│   ├── ai-assistants-pricing-2026.json
│   ├── ai-meeting-pricing-2026.json
│   └── ai-security-pricing-2026.json
├── business/                    # Business Software (15 categories)
│   ├── crm-pricing-2026.json           # Salesforce, HubSpot, Pipedrive...
│   ├── project-management-pricing-2026.json  # Notion, Asana, Linear...
│   ├── email-marketing-pricing-2026.json
│   ├── cloud-hosting-pricing-2026.json
│   ├── design-tools-pricing-2026.json
│   ├── website-builders-pricing-2026.json
│   ├── accounting-pricing-2026.json
│   ├── password-managers-pricing-2026.json
│   ├── vpn-pricing-2026.json
│   ├── video-conferencing-pricing-2026.json
│   ├── analytics-pricing-2026.json
│   ├── hr-tools-pricing-2026.json
│   ├── payments-pricing-2026.json
│   ├── seo-tools-pricing-2026.json
│   └── customer-support-pricing-2026.json
├── security/                    # Security & Infrastructure (9 categories)
│   ├── iam-pricing-2026.json           # Okta, Auth0, Azure AD...
│   ├── cloud-security-pricing-2026.json
│   ├── endpoint-security-pricing-2026.json
│   ├── compliance-pricing-2026.json
│   ├── vector-databases-pricing-2026.json
│   ├── finops-pricing-2026.json
│   ├── databases-pricing-2026.json
│   ├── erp-pricing-2026.json
│   └── data-observability-pricing-2026.json
├── crypto/                      # Crypto & Web3 (6 categories)
│   ├── crypto-exchanges-pricing-2026.json
│   ├── crypto-wallets-pricing-2026.json
│   ├── crypto-trading-bots-pricing-2026.json
│   ├── crypto-analytics-pricing-2026.json
│   ├── dex-pricing-2026.json
│   └── defi-tools-pricing-2026.json
└── benchmarks/
    └── category-benchmarks-2026.json   # Market stats for all 45 categories
```

## 📋 Data Schema

### Product Entry

```json
{
  "name": "Cursor",
  "slug": "cursor",
  "category": "ai-coding",
  "website": "https://cursor.sh",
  "free_plan": true,
  "starting_price": 0,
  "verified_at": "2026-05-15",
  "last_updated": "2026-05-17",
  "plans": [
    { "name": "Hobby", "price": 0, "period": "mo" },
    { "name": "Pro", "price": 20, "period": "mo" },
    { "name": "Business", "price": 40, "period": "user/mo" }
  ],
  "rating": 4.7,
  "features_count": 12
}
```

## 🔢 Coverage

| Domain | Categories | Tools |
|--------|-----------|-------|
| AI & LLM | 12 | 180+ |
| Business SaaS | 15 | 200+ |
| Security & Infra | 9 | 80+ |
| Crypto & Web3 | 6 | 50+ |
| **Total** | **45** | **508+** |

## 🔗 ComparEdge Platform

| Feature | URL |
|---------|-----|
| Browse all tools | [comparedge.com/tools](https://comparedge.com/tools) |
| Compare two tools | [comparedge.com/compare](https://comparedge.com/compare) |
| Pricing breakdowns | [comparedge.com/pricing](https://comparedge.com/pricing) |
| Alternatives finder | [comparedge.com/alternatives](https://comparedge.com/alternatives) |
| Security hub | [comparedge.com/security](https://comparedge.com/security) |
| Chrome Extension | [comparedge.com/extension](https://comparedge.com/extension) |
| Free Tools Suite | [comparedge.com/suite](https://comparedge.com/suite) |
| Blog | [comparedge.com/blog](https://comparedge.com/blog) |

## 🧩 Chrome Extension

Get instant pricing data while browsing any SaaS website — no tab switching required.

→ [comparedge.com/extension](https://comparedge.com/extension)

## 🤖 Use with AI Tools

| Integration | Repo |
|------------|------|
| LangChain | [langchain-comparedge](https://github.com/comparedge/langchain-comparedge) |
| LlamaIndex | [llamaindex-comparedge](https://github.com/comparedge/llamaindex-comparedge) |
| Claude MCP | [mcp-server-comparedge](https://github.com/comparedge/mcp-server-comparedge) |
| GitHub Action | [saas-price-check](https://github.com/comparedge/saas-price-check) |
| Terraform | [terraform-comparedge-saas](https://github.com/comparedge/terraform-comparedge-saas) |

## 📜 License

Data is licensed under [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/).
Free to use with attribution: **"Data from ComparEdge (comparedge.com)"**

---

[🌐 comparedge.com](https://comparedge.com) · [🐦 @ComparEdge](https://x.com/ComparEdge) · [💼 LinkedIn](https://www.linkedin.com/company/comparedge)
