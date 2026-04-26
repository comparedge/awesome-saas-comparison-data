Datasets
========

Overview
--------

ComparEdge maintains multiple open datasets across platforms:

.. list-table::
   :header-rows: 1
   :widths: 30 20 50

   * - Dataset
     - Platform
     - Description
   * - `SaaS & AI Tools Market 2026 <https://www.kaggle.com/datasets/comparedge/saas-ai-tools-market-2026>`_
     - Kaggle
     - 331 tools with pricing, ratings, features
   * - `LLM API Pricing 2026 <https://www.kaggle.com/datasets/comparedge/llm-api-pricing-comparison-2026>`_
     - Kaggle
     - 5 CSVs: pricing, scenarios, features, benchmarks, rate limits
   * - `AI Tools Pricing 2026 <https://huggingface.co/datasets/ComparEdge/ai-tools-pricing-2026>`_
     - HuggingFace
     - 104 AI tools with detailed pricing tiers
   * - `LLM Benchmark Matrix 2026 <https://huggingface.co/datasets/ComparEdge/llm-api-benchmark-matrix-2026>`_
     - HuggingFace
     - Performance benchmarks + features + rate limits
   * - `Scientific Dataset (DOI) <https://zenodo.org/records/19799704>`_
     - Zenodo
     - Citable research dataset with DOI

Data Schema
-----------

Each product record contains:

.. code-block:: json

    {
        "name": "Product Name",
        "category": "llm",
        "description": "Brief description",
        "pricing": {
            "free_plan": true,
            "starting_price": 20,
            "currency": "USD",
            "billing": "monthly"
        },
        "ratings": {
            "g2": 4.5,
            "capterra": 4.3
        },
        "features": ["feature1", "feature2"],
        "url": "https://product.com",
        "compare_url": "https://comparedge.com/compare/product"
    }

Categories
----------

28 categories across 3 verticals:

**AI Tools**: LLM, AI Coding, AI Writing, AI Image, AI Video, AI Voice, AI Agents, AI Assistants, AI Productivity

**Business**: CRM, Project Management, Email Marketing, Cloud Hosting, Design Tools

**Crypto**: Exchanges, Wallets, Trading Bots, DEX
