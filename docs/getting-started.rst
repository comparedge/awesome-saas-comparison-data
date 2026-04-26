Getting Started
===============

Installation
------------

**Python**::

    pip install comparedge-data

**JavaScript**::

    npm install comparedge-data

**Direct Download**:

Download the full dataset from `GitHub <https://github.com/comparedge/awesome-saas-comparison-data>`_ or
`Zenodo (DOI: 10.5281/zenodo.19799704) <https://zenodo.org/records/19799704>`_.

Python Quick Start
------------------

.. code-block:: python

    from comparedge_data import get_products, get_llms, get_benchmarks

    # Get all 331 products
    products = get_products()

    # Filter by category
    llms = get_llms()  # 25 LLM tools
    
    # Get market benchmarks
    benchmarks = get_benchmarks()  # 28 categories

JavaScript Quick Start
----------------------

.. code-block:: javascript

    const ce = require('comparedge-data');

    const products = ce.getProducts();  // 331 tools
    const llms = ce.getLLMs();          // 25 LLM tools
    const benchmarks = ce.getBenchmarks();

API Endpoints
-------------

Access data directly via GitHub raw URLs:

- **All Products**: ``GET https://raw.githubusercontent.com/comparedge/awesome-saas-comparison-data/main/data/products-full.json``
- **LLM Category**: ``GET https://raw.githubusercontent.com/comparedge/awesome-saas-comparison-data/main/data/categories/llm.json``
- **Benchmarks**: ``GET https://raw.githubusercontent.com/comparedge/awesome-saas-comparison-data/main/data/category-benchmarks.csv``

Full API documentation available on `Postman <https://www.postman.com/imkemit-ops-3675431/comparedge-data-api>`_.
