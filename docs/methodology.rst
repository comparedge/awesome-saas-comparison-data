Methodology
===========

Data Collection
---------------

ComparEdge aggregates data from multiple authoritative sources:

1. **Official pricing pages** — Direct from vendor websites
2. **Review platforms** — G2, Capterra, TrustRadius
3. **API documentation** — For technical specifications
4. **Public benchmarks** — For performance metrics

Update Frequency
----------------

- **Pricing data**: Monthly
- **Ratings**: Quarterly
- **Features**: As announced by vendors
- **Benchmarks**: When new results are published

Scoring Methodology
-------------------

Products are ranked using a composite score:

.. code-block:: text

    Score = (0.3 × Rating) + (0.25 × Features) + (0.25 × Value) + (0.2 × Popularity)

Where:

- **Rating**: Weighted average of G2, Capterra, TrustRadius scores
- **Features**: Normalized feature count vs category average
- **Value**: Price-to-features ratio
- **Popularity**: Based on review count and market presence

Data Quality
------------

All data passes through:

1. Automated validation (schema checks, range validation)
2. Cross-reference verification (multiple sources)
3. Monthly manual audit of top products per category

Learn more at `comparedge.com <https://comparedge.com>`_.
