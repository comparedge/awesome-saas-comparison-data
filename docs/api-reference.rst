API Reference
=============

ComparEdge data is accessible through multiple channels.

REST Endpoints
--------------

All endpoints return JSON (or CSV) and require no authentication.

.. list-table::
   :header-rows: 1

   * - Endpoint
     - Format
     - Description
   * - ``/data/products-full.json``
     - JSON
     - All 331 products
   * - ``/data/categories/llm.json``
     - JSON
     - LLM category (25 tools)
   * - ``/data/category-benchmarks.csv``
     - CSV
     - Market benchmarks (28 categories)

Base URL: ``https://raw.githubusercontent.com/comparedge/awesome-saas-comparison-data/main``

Postman Collection
------------------

Interactive API documentation: `Postman Workspace <https://www.postman.com/imkemit-ops-3675431/comparedge-data-api>`_

Python SDK
----------

.. code-block:: bash

    pip install comparedge-data

.. code-block:: python

    from comparedge_data import get_products, get_llms, get_benchmarks, get_categories

    products = get_products()       # list of 331 dicts
    llms = get_llms()               # list of 25 LLM tools
    benchmarks = get_benchmarks()   # list of 28 category benchmarks
    categories = get_categories()   # category metadata

JavaScript SDK
--------------

.. code-block:: bash

    npm install comparedge-data

.. code-block:: javascript

    const ce = require('comparedge-data');

    ce.getProducts()     // Array of 331 objects
    ce.getLLMs()         // Array of 25 LLM tools
    ce.getBenchmarks()   // Array of 28 benchmarks
    ce.getCategories()   // Category metadata

Interactive Tools
-----------------

- `LLM Cost Calculator <https://huggingface.co/spaces/ComparEdge/llm-cost-calculator>`_ — Compare API costs across 20 LLM providers
- `Live Rankings <https://comparedge.com/best>`_ — Real-time software rankings
