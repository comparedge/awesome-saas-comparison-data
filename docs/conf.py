project = 'ComparEdge Data Documentation'
copyright = '2026, ComparEdge'
author = 'ComparEdge Research Team'
release = '1.0.0'

extensions = ['sphinx.ext.autodoc', 'sphinx.ext.viewcode']
templates_path = ['_templates']
exclude_patterns = []

html_theme = 'sphinx_rtd_theme'
html_theme_options = {
    'logo_only': False,
    'display_version': True,
    'navigation_depth': 4,
}

html_context = {
    'display_github': True,
    'github_user': 'comparedge',
    'github_repo': 'awesome-saas-comparison-data',
    'github_version': 'main/docs/',
}
