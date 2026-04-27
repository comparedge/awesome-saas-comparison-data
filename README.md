# 📊 Awesome SaaS Comparison Data

> **Curated pricing, ratings & feature data** for 140+ top software tools across AI, Business & Crypto categories. Machine-readable formats. Updated monthly.

[![License: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](https://creativecommons.org/licenses/by/4.0/)
[![Tools: 142](https://img.shields.io/badge/Tools-142-blue.svg)](https://comparedge.com/best)
[![Categories: 18](https://img.shields.io/badge/Categories-18-green.svg)](https://comparedge.com/best)
[![Updated: April 2026](https://img.shields.io/badge/Updated-April%202026-orange.svg)](https://comparedge.com)

---

## Why This Exists

Choosing the right software tool shouldn't require visiting 30 different pricing pages. We maintain a curated, machine-readable dataset so developers, analysts, and founders can make data-driven decisions.

This repository contains a **curated subset** (~40%) of the full database powering [ComparEdge](https://comparedge.com) — an independent software comparison platform covering 331+ tools across 28 categories.

## 📁 Data Structure

```
data/
├── ai-tools/                    # AI & Machine Learning
│   ├── llm-pricing-2026.json           # GPT-4o, Claude, Gemini, Llama...
│   ├── ai-coding-pricing-2026.json     # Cursor, GitHub Copilot, Windsurf...
│   ├── ai-writing-pricing-2026.json    # Jasper, Copy.ai, Writesonic...
│   ├── ai-image-pricing-2026.json      # Midjourney, DALL-E 3, Stable Diffusion...
│   ├── ai-video-pricing-2026.json      # Runway, Pika, Synthesia...
│   ├── ai-voice-pricing-2026.json      # ElevenLabs, Play.ht, Murf...
│   ├── ai-agents-pricing-2026.json     # AutoGPT, CrewAI, LangChain...
│   ├── ai-productivity-pricing-2026.json
│   └── ai-assistants-pricing-2026.json
├── business/                    # Business Software
│   ├── crm-pricing-2026.json           # Salesforce, HubSpot, Pipedrive...
│   ├── project-management-pricing-2026.json  # Notion, Asana, Monday...
│   ├── email-marketing-pricing-2026.json
│   ├── cloud-hosting-pricing-2026.json
│   └── design-tools-pricing-2026.json
├── crypto/                      # Crypto & Web3
│   ├── crypto-exchanges-pricing-2026.json
│   ├── crypto-wallets-pricing-2026.json
│   ├── crypto-trading-bots-pricing-2026.json
│   └── dex-pricing-2026.json
└── benchmarks/
    └── category-benchmarks-2026.json   # Market stats for all 28 categories
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
  "plans": [
    { "name": "Hobby", "price": 0, "period": "mo" },
    { "name": "Pro", "price": 20, "period": "mo" },
    { "name": "Business", "price": 40, "period": "user/mo" }
  ],
  "rating": 4.7,
  "features_count": 12
}
```

### Category Benchmark

```json
{
  "category": "ai-coding",
  "tools_count": 10,
  "avg_rating": 4.38,
  "free_plan_percentage": 70,
  "explore": "https://comparedge.com/best/ai-coding"
}
```

## 🔍 Quick Insights (April 2026)

| Metric | Value |
|--------|-------|
| Highest avg. rating category | AI Assistants (4.54) |
| Most competitive category | LLMs (25 tools) |
| Highest free plan % | AI Productivity (85%) |
| Fastest growing | AI Agents (+40% YoY) |

## 🔗 Explore Full Data

This dataset is a curated snapshot. For **real-time data**, interactive comparisons, and the full 331-tool database:

| Resource | Link |
|----------|------|
| 🏆 Software Leaderboard | [comparedge.com/best](https://comparedge.com/best) |
| ⚔️ 2,266+ Comparisons | [comparedge.com/compare](https://comparedge.com/compare) |
| 💰 Pricing Breakdown | [comparedge.com/pricing](https://comparedge.com/pricing) |
| 📖 Methodology | [comparedge.com/methodology](https://comparedge.com/methodology) |
| 📊 Market Research | [blog.comparedge.com](https://blog.comparedge.com) |

### Deep Links by Category

**AI & ML:**
[LLMs](https://comparedge.com/best/llm) · [AI Coding](https://comparedge.com/best/ai-coding) · [AI Writing](https://comparedge.com/best/ai-writing) · [AI Image](https://comparedge.com/best/ai-image) · [AI Video](https://comparedge.com/best/ai-video) · [AI Voice](https://comparedge.com/best/ai-voice) · [AI Agents](https://comparedge.com/best/ai-agents) · [AI Productivity](https://comparedge.com/best/ai-productivity)

**Business:**
[CRM](https://comparedge.com/best/crm) · [Project Management](https://comparedge.com/best/project-management) · [Email Marketing](https://comparedge.com/best/email-marketing) · [Cloud Hosting](https://comparedge.com/best/cloud-hosting) · [Design Tools](https://comparedge.com/best/design-tools)

**Crypto & Web3:**
[Exchanges](https://comparedge.com/best/crypto-exchanges) · [Wallets](https://comparedge.com/best/crypto-wallets) · [Trading Bots](https://comparedge.com/best/crypto-trading-bots) · [DEX](https://comparedge.com/best/dex)

## 📊 Also Available On

- **Kaggle**: [SaaS & AI Tools Market Analysis 2026](https://www.kaggle.com/datasets/comparedge/saas-ai-tools-market-2026) — 331 tools, notebook-ready CSV
- **Hugging Face**: [ComparEdge/ai-tools-pricing-2026](https://huggingface.co/datasets/ComparEdge/ai-tools-pricing-2026) — 104 AI tools in JSONL

## 🛠 Use Cases

- **Startup founders** — Find affordable tools, compare pricing tiers side-by-side
- **Data analysts** — Benchmark SaaS pricing, build market models
- **Researchers** — Study pricing strategies, freemium adoption rates
- **Developers** — Build custom comparison tools, integrate into apps
- **Content writers** — Reference accurate pricing in articles (with attribution)

## 🤝 Contributing

Found an error? Know a tool we're missing?

- Open an [Issue](../../issues) with details
- Read our [Contributing Guide](CONTRIBUTING.md)
- Submit a tool for review at [comparedge.com](https://comparedge.com)

## 📄 License

[CC BY 4.0](https://creativecommons.org/licenses/by/4.0/) — Use freely with attribution.

```
Source: ComparEdge — Software Comparison Data (2026)
https://comparedge.com
```

---

<p align="center">
  <b>Built & maintained by <a href="https://comparedge.com">ComparEdge</a></b><br>
  <sub>Independent software comparison platform · 331+ tools · 28 categories · Updated daily</sub><br><br>
  <a href="https://comparedge.com">Website</a> · 
  <a href="https://blog.comparedge.com">Research Blog</a> · 
  <a href="https://x.com/ComparEdge">X (Twitter)</a>
</p>

## Database & Schema

Pre-built SQLite database and DDL schema with full product, pricing, and feature data.

| File | Description |
|------|-------------|
| [comparedge_v1.sqlite](database/comparedge_v1.sqlite) | Full SQLite database — 331 products, 1,013 pricing plans, 6,052 features |
| [core_schema_v2.sql](database/core_schema_v2.sql) | Complete DDL schema with views and sample data |

## Enterprise Assets

Ready-to-use templates for SaaS procurement and TCO analysis.

| File | Description |
|------|-------------|
| [Vendor_Evaluation_Template_2026.docx](enterprise-assets/Vendor_Evaluation_Template_2026.docx) | SaaS vendor evaluation checklist (22 criteria) |
| [TCO_Calculator_2026.xlsx](enterprise-assets/TCO_Calculator_2026.xlsx) | 4-sheet TCO calculator with 3-year projection formulas |

## Reports

Research and analysis reports on SaaS pricing trends.

| File | Description |
|------|-------------|
| [SaaS_Pricing_Report_Q2_2026.pdf](reports/SaaS_Pricing_Report_Q2_2026.pdf) | Q2 2026 SaaS pricing analysis across 29 categories |
