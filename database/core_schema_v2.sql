-- ComparEdge Core Database Schema v2.0
-- 331 SaaS products | 28 categories | Updated: 2026-04-27
-- Source: https://comparedge.com
-- API: https://comparedge-api.up.railway.app/docs
-- License: MIT
--
-- Import: sqlite3 comparedge.db < core_schema_v2.sql

-- ============================================================
-- PRAGMAS
-- ============================================================
PRAGMA journal_mode = WAL;
PRAGMA foreign_keys = ON;

-- ============================================================
-- TABLE: categories
-- One row per SaaS product category (e.g. project-management, llm, crm).
-- product_count is denormalized from the source data for fast listing pages.
-- ============================================================
CREATE TABLE IF NOT EXISTS categories (
  id            INTEGER PRIMARY KEY,        -- stable numeric id
  slug          TEXT    UNIQUE NOT NULL,    -- URL-safe identifier (e.g. 'project-management')
  name          TEXT    NOT NULL,           -- Display name (e.g. 'Project Management')
  description   TEXT,                       -- Short marketing description
  product_count INTEGER DEFAULT 0           -- cached count of products in category
);

-- ============================================================
-- TABLE: products
-- Core product catalogue. One row per SaaS tool.
-- comparedge_url is the canonical ComparEdge detail page.
-- Ratings are sourced from G2 and Capterra; overall_rating = average of available sources.
-- ============================================================
CREATE TABLE IF NOT EXISTS products (
  id                INTEGER PRIMARY KEY,        -- stable numeric id
  slug              TEXT    UNIQUE NOT NULL,    -- URL slug, matches comparedge_url path
  name              TEXT    NOT NULL,           -- Product display name
  category_id       INTEGER REFERENCES categories(id),
  description       TEXT,                       -- Long-form description / expert review
  short_description TEXT,                       -- One-liner for cards & meta tags
  website_url       TEXT,                       -- Official product website
  logo_url          TEXT,                       -- CDN logo path on comparedge.com
  g2_rating         REAL,                       -- G2 crowd rating (0-5)
  capterra_rating   REAL,                       -- Capterra rating (0-5)
  overall_rating    REAL,                       -- Average of available review sources
  review_count      INTEGER DEFAULT 0,          -- Total reviews aggregated
  founded_year      INTEGER,                    -- Year company was founded
  hq_location       TEXT,                       -- Headquarters city/country
  has_free_tier     BOOLEAN DEFAULT 0,          -- 1 = free plan exists
  has_free_trial    BOOLEAN DEFAULT 0,          -- 1 = time-limited trial offered
  last_updated      TEXT,                       -- ISO date of last data refresh (YYYY-MM-DD)
  comparedge_url    TEXT                        -- https://comparedge.com/tools/{slug}
);

-- ============================================================
-- TABLE: pricing_plans
-- Each pricing tier for a product. A product may have 1–6 plans.
-- price_monthly = NULL means custom / contact-sales pricing.
-- price_monthly = 0 means genuinely free.
-- billing_model: flat | per-seat | usage-based | per-project
-- features: JSON array of plan highlight strings from vendor.
-- ============================================================
CREATE TABLE IF NOT EXISTS pricing_plans (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id    INTEGER REFERENCES products(id),
  plan_name     TEXT    NOT NULL,          -- e.g. 'Free', 'Pro', 'Enterprise'
  price_monthly REAL,                      -- USD/month (NULL = custom quote)
  price_annual  REAL,                      -- USD/year when billed annually
  billing_model TEXT,                      -- flat | per-seat | usage-based | per-project
  currency      TEXT    DEFAULT 'USD',
  features      TEXT                       -- JSON array of plan highlights
);

-- ============================================================
-- TABLE: features
-- Normalised feature matrix. One row per (product, feature) pair.
-- feature_value is typically 'true'/'false' or a string value.
-- category groups features for comparison table columns:
--   general | integration | security | collaboration | analytics | mobile | ai | export
-- ============================================================
CREATE TABLE IF NOT EXISTS features (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id    INTEGER REFERENCES products(id),
  feature_name  TEXT    NOT NULL,   -- e.g. 'Kanban Boards', 'SAML SSO'
  feature_value TEXT,               -- 'true', 'false', or a descriptive string
  category      TEXT                -- feature group for rendering comparison grids
);

-- ============================================================
-- TABLE: price_history
-- Append-only pricing audit log.
-- One row per (product, plan, date) snapshot.
-- Enables "price changed" alerts and trend charts.
-- ============================================================
CREATE TABLE IF NOT EXISTS price_history (
  id            INTEGER PRIMARY KEY AUTOINCREMENT,
  product_id    INTEGER REFERENCES products(id),
  recorded_date TEXT    NOT NULL,   -- ISO date: YYYY-MM-DD
  plan_name     TEXT,               -- matches pricing_plans.plan_name
  price         REAL,               -- price at time of snapshot (USD/month)
  notes         TEXT                -- e.g. "Initial snapshot | period: user/mo"
);

-- ============================================================
-- INDEXES (performance)
-- ============================================================
CREATE INDEX IF NOT EXISTS idx_products_category    ON products(category_id);
CREATE INDEX IF NOT EXISTS idx_products_rating      ON products(overall_rating DESC);
CREATE INDEX IF NOT EXISTS idx_products_free_tier   ON products(has_free_tier);
CREATE INDEX IF NOT EXISTS idx_pricing_product      ON pricing_plans(product_id);
CREATE INDEX IF NOT EXISTS idx_pricing_price        ON pricing_plans(price_monthly);
CREATE INDEX IF NOT EXISTS idx_features_product     ON features(product_id);
CREATE INDEX IF NOT EXISTS idx_history_product_date ON price_history(product_id, recorded_date);

-- ============================================================
-- VIEW: v_category_stats
-- Aggregated stats per category: avg rating, avg starting price,
-- and percentage of products offering a free tier.
-- Used for category listing pages and API /categories endpoint.
-- ============================================================
CREATE VIEW IF NOT EXISTS v_category_stats AS
SELECT
  c.name,
  c.slug,
  c.product_count,
  ROUND(AVG(p.overall_rating), 2)                                           AS avg_rating,
  ROUND(AVG(CASE WHEN pp.price_monthly > 0 THEN pp.price_monthly END), 2)  AS avg_starting_price,
  ROUND(100.0 * SUM(CASE WHEN p.has_free_tier THEN 1 ELSE 0 END) / COUNT(*), 1) AS free_tier_pct
FROM categories c
JOIN products p ON p.category_id = c.id
LEFT JOIN pricing_plans pp
  ON pp.product_id = p.id
  AND pp.price_monthly = (
    SELECT MIN(pp2.price_monthly)
    FROM pricing_plans pp2
    WHERE pp2.product_id = p.id
      AND pp2.price_monthly > 0
  )
GROUP BY c.id;

-- ============================================================
-- VIEW: v_llm_comparison
-- Pricing comparison table for the 'llm' category.
-- Powers the /compare/llm page.
-- ============================================================
CREATE VIEW IF NOT EXISTS v_llm_comparison AS
SELECT
  p.name,
  p.slug,
  p.overall_rating,
  p.has_free_tier,
  pp.plan_name,
  pp.price_monthly,
  pp.billing_model
FROM products p
JOIN categories c  ON p.category_id = c.id
JOIN pricing_plans pp ON pp.product_id = p.id
WHERE c.slug = 'llm'
ORDER BY pp.price_monthly;

-- ============================================================
-- VIEW: v_free_tier_products
-- All products with a free tier, sorted by rating DESC.
-- Used for "Best free tools" landing pages and email campaigns.
-- ============================================================
CREATE VIEW IF NOT EXISTS v_free_tier_products AS
SELECT
  p.name,
  p.slug,
  c.name        AS category,
  p.overall_rating,
  p.comparedge_url
FROM products p
JOIN categories c ON p.category_id = c.id
WHERE p.has_free_tier = 1
ORDER BY p.overall_rating DESC;

-- ============================================================
-- SAMPLE DATA: All categories
-- ============================================================
INSERT OR IGNORE INTO categories (id, slug, name, description, product_count) VALUES
  (1, 'ai-tools', 'AI Tools', 'Complete directory of AI tools across writing, image, video, coding, voice, agents, and more', 104),
  (2, 'llm', 'Large Language Models', NULL, 25),
  (3, 'cloud-hosting', 'Cloud Hosting', NULL, 21),
  (4, 'email-marketing', 'Email Marketing', NULL, 20),
  (5, 'project-management', 'Project Management', NULL, 20),
  (6, 'video-conferencing', 'Video Conferencing', NULL, 19),
  (7, 'website-builders', 'Website Builders', NULL, 19),
  (8, 'crm', 'Crm', NULL, 18),
  (9, 'design-tools', 'Design Tools', NULL, 18),
  (10, 'accounting', 'Accounting', NULL, 15),
  (11, 'ai-agents', 'AI Agents', NULL, 8),
  (12, 'ai-image', 'AI Image Generators', NULL, 13),
  (13, 'ai-writing', 'AI Writing', NULL, 12),
  (14, 'crypto-wallets', 'Crypto Wallets', NULL, 11),
  (15, 'ai-coding', 'AI Coding', NULL, 10),
  (16, 'ai-productivity', 'AI Productivity', 'AI-powered productivity tools for notes, presentations, research, and data analysis', 13),
  (17, 'ai-video', 'AI Video', NULL, 9),
  (18, 'crypto-analytics', 'Crypto Analytics', NULL, 8),
  (19, 'crypto-exchanges', 'Crypto Exchanges', NULL, 8),
  (20, 'crypto-telegram-bots', 'Crypto Telegram Bots', NULL, 8),
  (21, 'crypto-trading-bots', 'Crypto Trading Bots', NULL, 8),
  (22, 'dex', 'Dex', NULL, 8),
  (23, 'ai-voice', 'AI Voice & Audio', NULL, 7),
  (24, 'crypto-tax', 'Crypto Tax', NULL, 6),
  (25, 'ai-assistants', 'AI Assistants', 'AI chat assistants, conversational AI and smart bots', 7),
  (26, 'crypto-portfolio-trackers', 'Crypto Portfolio Trackers', NULL, 5),
  (27, 'defi-tools', 'Defi Tools', NULL, 5),
  (28, 'password-managers', 'Password Managers', NULL, 5),
  (29, 'vpn', 'Vpn', NULL, 5);

-- ============================================================
-- SAMPLE DATA: First 20 products (sorted by id)
-- Full dataset: 331 rows in comparedge_v1.sqlite
-- ============================================================
INSERT OR IGNORE INTO products
  (id, slug, name, category_id, description, short_description,
   website_url, logo_url, g2_rating, capterra_rating, overall_rating,
   review_count, founded_year, hq_location, has_free_tier, has_free_trial,
   last_updated, comparedge_url)
VALUES
  (1, 'notion', 'Notion', 5, 'Built around the idea that documents, databases, and wikis shouldn''t live in separate apps, Notion lets you structure information exactly how your team thinks. Remote teams and knowledge workers use it to replace scattered Google Docs, Confluence wikis, and Trello boards with a single linked workspa', 'All-in-one workspace for notes, docs, databases, and project management', 'https://www.notion.com', 'https://comparedge.com/logos/notion.png', 4.7, 4.7, 4.7, 0, 2016, 'San Francisco, CA', 1, 0, '2026-04-27', 'https://comparedge.com/tools/notion'),
  (2, 'clickup', 'ClickUp', 5, 'If you''ve ever wished you could replace your task manager, doc editor, spreadsheet, time tracker, and goal tracker with a single app - ClickUp attempts exactly that. It covers the full spectrum from simple personal to-do lists to complex enterprise workflows with dependencies, automations, and workl', 'All-in-one productivity platform replacing multiple work tools', 'https://clickup.com', 'https://comparedge.com/logos/clickup.png', 4.7, 4.6, 4.65, 0, 2017, 'San Diego, CA', 1, 0, '2026-04-27', 'https://comparedge.com/tools/clickup'),
  (3, 'asana', 'Asana', 5, 'Teams that need clear ownership and deadline accountability tend to gravitate toward Asana. Its strength lies in task management with a strong emphasis on assignees, due dates, and project timelines - making it easier than many alternatives to answer ''who is doing what by when.'' The Timeline view (G', 'Work management platform for teams to organize, track, and manage work', 'https://asana.com', 'https://comparedge.com/logos/asana.png', 4.4, 4.5, 4.45, 0, 2008, 'San Francisco, CA', 1, 0, '2026-04-27', 'https://comparedge.com/tools/asana'),
  (4, 'monday', 'monday.com', 5, 'Originally designed as a flexible spreadsheet alternative, monday.com has evolved into a work management platform used across project management, CRM, marketing ops, and HR workflows. Its visual, color-coded board interface makes status tracking immediately legible - even stakeholders who don''t live', 'Work OS that powers teams to run projects and workflows with confidence', 'https://monday.com', 'https://comparedge.com/logos/monday.png', 4.7, 4.6, 4.65, 0, 2012, 'Tel Aviv, Israel', 1, 0, '2026-04-27', 'https://comparedge.com/tools/monday'),
  (5, 'trello', 'Trello', 5, 'One of the original kanban-style tools, Trello made visual project tracking accessible to non-technical teams long before most alternatives existed. Its board-list-card system is genuinely simple to learn - most people are productive within minutes of signing up. This makes it particularly effective', 'Visual collaboration tool using boards, lists, and cards for organizing work', 'https://trello.com', 'https://comparedge.com/logos/trello.png', 4.4, 4.5, 4.45, 0, 2011, 'New York, NY (Atlassian)', 1, 0, '2026-04-27', 'https://comparedge.com/tools/trello'),
  (6, 'jira', 'Jira', 5, 'The standard for software development teams, Jira is built around agile methodologies - sprints, story points, epics, and backlogs - in a way that few other tools match in depth. Engineering teams use it to plan sprints, track bugs, manage releases, and report velocity over time. Its deep integratio', 'The #1 agile project management tool for software development teams', 'https://www.atlassian.com/software/jira', 'https://comparedge.com/logos/jira.png', 4.3, 4.5, 4.4, 0, 2002, 'Sydney, Australia (Atlassian)', 1, 0, '2026-04-27', 'https://comparedge.com/tools/jira'),
  (7, 'basecamp', 'Basecamp', 5, 'Basecamp has a specific philosophy: work should be organized, not overwhelming. It deliberately avoids the feature sprawl that tools like ClickUp accumulate, instead giving every project the same six tools - message board, to-dos, schedule, docs/files, group chat, and automatic check-ins. Agencies a', 'Simple project management and team communication tool', 'https://basecamp.com', 'https://comparedge.com/logos/basecamp.png', 4.1, 4.3, 4.2, 0, 2004, 'Chicago, IL', 1, 0, '2026-04-27', 'https://comparedge.com/tools/basecamp'),
  (8, 'wrike', 'Wrike', 5, 'Positioned between mid-market and enterprise, Wrike offers the workflow depth of a tool like Jira combined with the flexibility teams expect from a general project management solution. Custom request forms, cross-project dependencies, proofing and approval workflows, and resource management are buil', 'Versatile work management platform for enterprise teams', 'https://www.wrike.com', 'https://comparedge.com/logos/wrike.png', 4.2, 4.3, 4.25, 0, 2006, 'San Jose, CA', 1, 0, '2026-04-27', 'https://comparedge.com/tools/wrike'),
  (9, 'teamwork', 'Teamwork', 5, 'While most project management tools treat client work as an afterthought, Teamwork is explicitly designed around it. Billable time tracking, client-facing portals, budget management, and invoice generation are built directly into the platform - reducing the number of separate tools agencies need to ', 'Project management built for client work and agencies', 'https://www.teamwork.com', 'https://comparedge.com/logos/teamwork.png', 4.4, 4.5, 4.45, 0, 2007, 'Cork, Ireland', 1, 0, '2026-04-27', 'https://comparedge.com/tools/teamwork'),
  (10, 'linear', 'Linear', 5, 'Linear was built in reaction to the bloat that accumulates in tools like Jira. It''s fast - deliberately, obsessively fast - with a keyboard-first interface that product and engineering teams who spend hours in the tool genuinely appreciate. Issue creation, assignment, priority updates, and sprint ma', 'Streamlined issue tracking and project management for software teams', 'https://linear.app', 'https://comparedge.com/logos/linear.png', 4.6, 4.7, 4.65, 0, 2019, 'San Francisco, CA', 1, 0, '2026-04-27', 'https://comparedge.com/tools/linear'),
  (11, 'height', 'Height', 5, 'An emerging player in the project management space, Height differentiates itself through AI-powered assistance and genuinely cross-functional design. Unlike tools that serve either developers or business teams, Height works well across both - engineers track issues, designers manage tasks, and produ', 'AI-powered project management tool for cross-functional teams', 'https://height.app', 'https://comparedge.com/logos/height.png', 4.8, 4.7, 4.75, 0, 2019, 'San Francisco, CA', 1, 0, '2026-04-27', 'https://comparedge.com/tools/height'),
  (12, 'hive', 'Hive', 5, 'Designed to serve teams that want project management with built-in productivity insights, Hive pairs traditional task and project management with analytics that show how time is actually being spent. Action cards (tasks), forms, time tracking, and project baselines are built in, and the analytics da', 'AI-powered project management platform for teams of all sizes', 'https://hive.com', 'https://comparedge.com/logos/hive.png', 4.6, 4.5, 4.55, 0, 2015, 'New York, NY', 1, 0, '2026-04-27', 'https://comparedge.com/tools/hive'),
  (13, 'smartsheet', 'Smartsheet', 5, 'Smartsheet occupies a unique space: spreadsheet-familiar interface with project management power underneath. Teams that live in Excel or Google Sheets - particularly in construction, manufacturing, finance, and enterprise operations - find its grid-based layout immediately intuitive, even while it h', 'Enterprise work management platform with spreadsheet-like interface', 'https://www.smartsheet.com', 'https://comparedge.com/logos/smartsheet.png', 4.5, 4.5, 4.5, 0, 2005, 'Bellevue, WA', 0, 0, '2026-04-27', 'https://comparedge.com/tools/smartsheet'),
  (14, 'airtable', 'Airtable', 5, 'Airtable sits at the intersection of spreadsheet and database - structured enough to handle relational data, flexible enough for non-technical teams to configure without writing SQL. Marketing teams use it to manage content calendars with linked asset records. Product teams use it to track feature r', 'Low-code platform for building collaborative apps and workflows', 'https://airtable.com', 'https://comparedge.com/logos/airtable.png', 4.6, 4.7, 4.65, 0, 2012, 'San Francisco, CA', 1, 0, '2026-04-27', 'https://comparedge.com/tools/airtable'),
  (15, 'todoist', 'Todoist', 5, 'Among individual task managers and lightweight team tools, Todoist has one of the strongest track records for actually improving personal productivity. Its natural language input - typing ''Submit report every Friday at 9am'' and having it schedule correctly - reduces friction in capturing tasks. The ', 'Simple yet powerful task manager for individuals and teams', 'https://todoist.com', 'https://comparedge.com/logos/todoist.png', 4.4, 4.6, 4.5, 0, 2007, 'Remote (founded in Brazil)', 1, 0, '2026-04-27', 'https://comparedge.com/tools/todoist'),
  (16, 'miro', 'Miro', 5, 'When distributed teams need to brainstorm, map processes, run workshops, or build product roadmaps together, Miro provides an infinite canvas that translates in-person whiteboard sessions into a digital format that actually works. Designers use it for wireframing and design critique. Product manager', 'Visual collaboration platform for distributed teams', 'https://miro.com', 'https://comparedge.com/logos/miro.png', 4.8, 4.7, 4.75, 0, 2011, 'San Francisco, CA / Amsterdam', 1, 0, '2026-04-27', 'https://comparedge.com/tools/miro'),
  (17, 'coda', 'Coda', 5, 'Coda sits in a specific niche: teams who want the structure of a database, the flexibility of a doc, and the automation of a workflow tool - without stitching three products together. A Coda doc can contain text, tables, formulas, buttons that trigger actions, and integrations with Salesforce, Jira,', 'All-in-one doc that combines documents, spreadsheets, and apps', 'https://coda.io', 'https://comparedge.com/logos/coda.png', 4.7, 4.6, 4.65, 0, 2014, 'Mountain View, CA', 1, 0, '2026-04-27', 'https://comparedge.com/tools/coda'),
  (18, 'shortcut', 'Shortcut (formerly Clubhouse)', 5, 'Built by developers who were frustrated with Jira''s complexity, Shortcut offers a genuinely clean alternative for software teams. It keeps the structure engineers need - stories, epics, sprints (called Iterations), workflows - while removing the configuration overhead that makes Jira adoption painfu', 'Project management tool for software teams with workflows, iterations, and roadmap planning features.', 'https://shortcut.com', 'https://comparedge.com/logos/shortcut.png', 4.3, 4.5, 4.4, 0, 2016, 'New York, NY', 1, 0, '2026-04-27', 'https://comparedge.com/tools/shortcut'),
  (19, 'niftypm', 'Nifty', 5, 'Nifty combines project milestones, task management, document collaboration, and team chat into a single workspace - addressing the fragmentation that comes when teams split work across Asana, Slack, and Google Docs. Milestone tracking is its most distinctive feature: goals are tied directly to tasks', 'Project management hub that aligns goals, tasks, and communication', 'https://niftypm.com', 'https://comparedge.com/logos/niftypm.png', 4.7, 4.7, 4.7, 0, 2017, 'New York, NY', 1, 0, '2026-04-27', 'https://comparedge.com/tools/niftypm'),
  (20, 'zoho-projects', 'Zoho Projects', 5, 'Part of the Zoho ecosystem, Zoho Projects earns attention primarily from businesses already using Zoho CRM, Zoho Books, or other Zoho products. The deep integration between Zoho apps - pulling client data from CRM into project plans, linking billed hours to invoices in Books - creates a connected wo', 'Online project management software for smart project planning', 'https://www.zoho.com/projects/', 'https://comparedge.com/logos/zoho-projects.png', 4.3, 4.4, 4.35, 0, 1996, 'Chennai, India', 1, 0, '2026-04-27', 'https://comparedge.com/tools/zoho-projects');

-- ============================================================
-- SAMPLE DATA: Pricing plans for first 20 products
-- ============================================================
INSERT OR IGNORE INTO pricing_plans
  (product_id, plan_name, price_monthly, price_annual, billing_model, currency, features)
VALUES
  (1, 'Free', 0.0, NULL, 'per-seat', 'USD', '["Unlimited pages for individuals", "7-day page history", "10 guest limit"]'),
  (1, 'Plus', 12.0, NULL, 'per-seat', 'USD', '["Unlimited file uploads", "30-day page history", "Unlimited guests"]'),
  (1, 'Business', 18.0, NULL, 'per-seat', 'USD', '["SAML SSO", "Private teamspaces", "Advanced permissions"]'),
  (1, 'Enterprise', NULL, NULL, 'per-seat', 'USD', '["SCIM", "Audit log", "Custom data retention"]'),
  (2, 'Free', 0.0, NULL, 'flat', 'USD', '["Unlimited tasks", "Unlimited members", "60MB storage"]'),
  (2, 'Unlimited', 7.0, NULL, 'per-seat', 'USD', '["Unlimited storage", "Unlimited integrations", "Gantt charts"]'),
  (2, 'Business', 12.0, NULL, 'per-seat', 'USD', '["Google SSO", "Unlimited dashboards", "Workload management"]'),
  (2, 'Enterprise', NULL, NULL, 'per-seat', 'USD', '["White labeling", "HIPAA", "SSO", "Custom roles"]'),
  (3, 'Personal', 0.0, NULL, 'flat', 'USD', '["Up to 2 users", "List, board & calendar views", "Unlimited tasks"]'),
  (3, 'Starter', 10.99, NULL, 'per-seat', 'USD', '["Timeline & Gantt views", "Workflow builder", "Unlimited users"]'),
  (3, 'Advanced', 24.99, NULL, 'per-seat', 'USD', '["Goals", "Portfolios", "Proofing", "Native time tracking"]'),
  (3, 'Enterprise', NULL, NULL, 'per-seat', 'USD', '["SAML", "SCIM", "Data export", "Custom branding"]'),
  (4, 'Free', 0.0, NULL, 'flat', 'USD', '["Up to 2 seats", "3 boards", "200+ templates"]'),
  (4, 'Basic', 9.0, NULL, 'per-seat', 'USD', '["Unlimited viewers", "Unlimited items", "5GB storage"]'),
  (4, 'Standard', 12.0, NULL, 'per-seat', 'USD', '["Timeline & Gantt", "Calendar view", "Guest access"]'),
  (4, 'Pro', 19.0, NULL, 'per-seat', 'USD', '["Private boards", "Time tracking", "Chart view"]'),
  (4, 'Enterprise', NULL, NULL, 'per-seat', 'USD', '["Advanced security", "Multi-level permissions", "Enterprise analytics"]'),
  (5, 'Free', 0.0, NULL, 'flat', 'USD', '["Unlimited cards", "10 boards/workspace", "Unlimited power-ups"]'),
  (5, 'Standard', 5.0, NULL, 'per-seat', 'USD', '["Unlimited boards", "Advanced checklists", "Custom fields"]'),
  (5, 'Premium', 10.0, NULL, 'per-seat', 'USD', '["AI features", "Dashboard view", "Timeline view", "Calendar view"]'),
  (5, 'Enterprise', 17.5, NULL, 'per-seat', 'USD', '["Unlimited workspaces", "Organization-wide permissions", "24/7 support"]'),
  (6, 'Free', 0.0, NULL, 'flat', 'USD', '["Up to 10 users", "Unlimited projects", "2GB storage"]'),
  (6, 'Standard', 7.91, NULL, 'per-seat', 'USD', '["Up to 100K users", "250GB storage", "AI features"]'),
  (6, 'Premium', 14.54, NULL, 'per-seat', 'USD', '["Cross-team planning", "Unlimited storage", "99.9% SLA"]'),
  (6, 'Enterprise', NULL, NULL, 'per-seat', 'USD', '["Up to 150 sites", "Advanced analytics", "99.95% SLA"]'),
  (7, 'Free', 0.0, NULL, 'flat', 'USD', '["1 project", "Up to 20 users", "1 GB storage"]'),
  (7, 'Basecamp Plus', 15.0, NULL, 'per-seat', 'USD', '["Unlimited projects", "Unlimited users", "500 GB storage", "30-day free trial"]'),
  (7, 'Basecamp Pro Unlimited', 299.0, NULL, 'flat', 'USD', '["Unlimited everything", "Priority support", "5 TB storage", "60-day free trial"]'),
  (8, 'Free', 0.0, NULL, 'flat', 'USD', '["Board & table views", "Task management", "Web & mobile apps"]'),
  (8, 'Team', 10.0, NULL, 'per-seat', 'USD', '["2-15 users", "Gantt charts", "Custom fields"]'),
  (8, 'Business', 25.0, NULL, 'per-seat', 'USD', '["5-200 users", "Resource planning", "Templates"]'),
  (8, 'Pinnacle', NULL, NULL, 'per-seat', 'USD', '["Advanced reporting", "Budgeting", "SSO", "Advanced security"]'),
  (9, 'Free', 0.0, NULL, 'flat', 'USD', '["5 users", "2 projects", "Basic features"]'),
  (9, 'Deliver', 13.99, NULL, 'per-seat', 'USD', '["300 projects", "Time tracking", "Billing"]'),
  (9, 'Grow', 25.99, NULL, 'per-seat', 'USD', '["Unlimited projects", "Resource management", "Profitability reports"]'),
  (9, 'Scale', 69.99, NULL, 'per-seat', 'USD', '["Advanced budgeting", "Custom reports", "Priority support"]'),
  (10, 'Free', 0.0, NULL, 'flat', 'USD', '["Unlimited members", "250 issues", "2 teams"]'),
  (10, 'Basic', 10.0, NULL, 'per-seat', 'USD', '["5 teams", "Unlimited issues", "Admin roles"]'),
  (10, 'Business', 16.0, NULL, 'per-seat', 'USD', '["Unlimited teams", "Private teams", "SLAs", "Insights"]'),
  (10, 'Enterprise', NULL, NULL, 'per-seat', 'USD', '["SAML/SCIM", "Advanced security", "Dedicated support"]'),
  (11, 'Free', 0.0, NULL, 'flat', 'USD', '["Unlimited members", "Basic features", "100 tasks"]'),
  (11, 'Team', 8.5, NULL, 'per-seat', 'USD', '["Unlimited tasks", "Forms", "Integrations"]'),
  (11, 'Business', 15.0, NULL, 'per-seat', 'USD', '["Advanced automations", "SSO", "Priority support"]'),
  (12, 'Free', 0.0, NULL, 'flat', 'USD', '["Up to 10 users", "Core PM features"]'),
  (12, 'Starter', 5.0, NULL, 'per-seat', 'USD', '["Unlimited users", "Gantt charts", "Integrations"]'),
  (12, 'Teams', 12.0, NULL, 'per-seat', 'USD', '["Timesheets", "Resources", "Analytics"]'),
  (12, 'Enterprise', NULL, NULL, 'per-seat', 'USD', '["SSO", "Custom onboarding", "SLA"]'),
  (13, 'Pro', 9.0, NULL, 'per-seat', 'USD', '["Unlimited sheets", "Gantt", "Forms"]'),
  (13, 'Business', 19.0, NULL, 'per-seat', 'USD', '["Unlimited automations", "Proofing", "Unlimited viewers"]'),
  (13, 'Enterprise', NULL, NULL, 'per-seat', 'USD', '["SSO/SAML", "Admin controls", "WorkApps"]'),
  (14, 'Free', 0.0, NULL, 'flat', 'USD', '["Unlimited bases", "1000 records/base", "1GB/base"]'),
  (14, 'Team', 20.0, NULL, 'per-seat', 'USD', '["50K records/base", "20GB/base", "Automations"]'),
  (14, 'Business', 45.0, NULL, 'per-seat', 'USD', '["125K records/base", "100GB/base", "Admin panel"]'),
  (14, 'Enterprise Scale', NULL, NULL, 'per-seat', 'USD', '["500K records/base", "1TB/base", "Enterprise security"]'),
  (15, 'Beginner', 0.0, NULL, 'flat', 'USD', '["5 personal projects", "5 collaborators/project"]'),
  (15, 'Pro', 5.0, NULL, 'per-seat', 'USD', '["300 projects", "25 collaborators", "Reminders", "Calendar"]'),
  (15, 'Business', 8.0, NULL, 'per-seat', 'USD', '["500 projects", "50 collaborators", "Team features"]'),
  (16, 'Free', 0.0, NULL, 'flat', 'USD', '["3 editable boards", "Unlimited team members"]'),
  (16, 'Starter', 8.0, NULL, 'per-seat', 'USD', '["Unlimited boards", "Private boards"]'),
  (16, 'Business', 20.0, NULL, 'per-seat', 'USD', '["SSO", "Smart diagramming", "Guest access"]'),
  (16, 'Enterprise', NULL, NULL, 'per-seat', 'USD', '["Advanced security", "Support SLA", "SCIM"]'),
  (17, 'Free', 0.0, NULL, 'flat', 'USD', '["Unlimited editors", "Unlimited docs", "Basic features"]'),
  (17, 'Pro', 10.0, NULL, 'flat', 'USD', '["Unlimited pages", "Custom domains", "Hidden pages"]'),
  (17, 'Team', 30.0, NULL, 'flat', 'USD', '["Shared permissions", "Private docs", "Advanced automations"]'),
  (17, 'Enterprise', NULL, NULL, 'flat', 'USD', '["SSO", "Audit logs", "Advanced security"]'),
  (18, 'Free', 0.0, NULL, 'flat', 'USD', '["Up to 10 users", "Core features"]'),
  (18, 'Team', 8.5, NULL, 'per-seat', 'USD', '["Unlimited users", "Iterations", "Reporting"]'),
  (18, 'Business', 12.0, NULL, 'per-seat', 'USD', '["Advanced reporting", "Custom fields"]'),
  (18, 'Enterprise', NULL, NULL, 'per-seat', 'USD', '["SSO/SAML", "SCIM", "Audit logs"]'),
  (19, 'Free', 0.0, NULL, 'flat', 'USD', '["Unlimited members", "2 active projects", "Basic features"]'),
  (19, 'Starter', 39.0, 468.0, 'flat', 'USD', '["Up to 10 members", "40 projects", "Time tracking"]'),
  (19, 'Business', 124.0, 1488.0, 'flat', 'USD', '["Up to 50 members", "Unlimited projects", "Workload management"]'),
  (19, 'Unlimited', 399.0, 4788.0, 'flat', 'USD', '["Unlimited members", "All features", "Priority support"]'),
  (20, 'Free', 0.0, NULL, 'flat', 'USD', '["3 users", "2 projects"]'),
  (20, 'Premium', 5.0, NULL, 'per-seat', 'USD', '["Unlimited projects", "Gantt charts", "20 templates"]'),
  (20, 'Enterprise', 10.0, NULL, 'per-seat', 'USD', '["30 templates", "Global Gantt", "Read-only users"]');

-- ============================================================
-- SAMPLE DATA: Features for first 20 products
-- ============================================================
INSERT OR IGNORE INTO features (product_id, feature_name, feature_value, category) VALUES
  (1, 'Task Management', 'True', 'general'),
  (1, 'Kanban Boards', 'True', 'general'),
  (1, 'Gantt Charts', 'False', 'analytics'),
  (1, 'Time Tracking', 'False', 'general'),
  (1, 'Sprints/Scrum', 'False', 'general'),
  (1, 'Roadmaps', 'False', 'general'),
  (1, 'Automation', 'True', 'ai'),
  (1, 'Reporting/Analytics', 'False', 'analytics'),
  (1, 'Custom Workflows', 'True', 'general'),
  (1, 'API/Integrations', 'True', 'integration'),
  (1, 'Mobile App', 'True', 'mobile'),
  (1, 'Resource Management', 'False', 'general'),
  (1, 'Dependencies', 'True', 'general'),
  (1, 'Goals/OKRs', 'False', 'general'),
  (1, 'Forms', 'True', 'general'),
  (1, 'Guest Access', 'True', 'collaboration'),
  (1, 'File Sharing', 'True', 'general'),
  (1, 'Comments/Mentions', 'False', 'collaboration'),
  (1, 'Templates', 'True', 'general'),
  (1, 'Calendar View', 'True', 'general'),
  (2, 'Task Management', 'True', 'general'),
  (2, 'Kanban Boards', 'True', 'general'),
  (2, 'Gantt Charts', 'True', 'analytics'),
  (2, 'Time Tracking', 'True', 'general'),
  (2, 'Sprints/Scrum', 'True', 'general'),
  (2, 'Roadmaps', 'False', 'general'),
  (2, 'Automation', 'True', 'ai'),
  (2, 'Reporting/Analytics', 'True', 'analytics'),
  (2, 'Custom Workflows', 'True', 'general'),
  (2, 'API/Integrations', 'True', 'integration'),
  (2, 'Mobile App', 'False', 'mobile'),
  (2, 'Resource Management', 'True', 'general'),
  (2, 'Dependencies', 'True', 'general'),
  (2, 'Goals/OKRs', 'True', 'general'),
  (2, 'Forms', 'True', 'general'),
  (2, 'Guest Access', 'True', 'collaboration'),
  (2, 'File Sharing', 'False', 'general'),
  (2, 'Comments/Mentions', 'True', 'collaboration'),
  (2, 'Templates', 'True', 'general'),
  (2, 'Calendar View', 'True', 'general'),
  (3, 'Task Management', 'True', 'general'),
  (3, 'Kanban Boards', 'True', 'general'),
  (3, 'Gantt Charts', 'True', 'analytics'),
  (3, 'Time Tracking', 'True', 'general'),
  (3, 'Sprints/Scrum', 'False', 'general'),
  (3, 'Roadmaps', 'False', 'general'),
  (3, 'Automation', 'True', 'ai'),
  (3, 'Reporting/Analytics', 'True', 'analytics'),
  (3, 'Custom Workflows', 'True', 'general'),
  (3, 'API/Integrations', 'True', 'integration'),
  (3, 'Mobile App', 'True', 'mobile'),
  (3, 'Resource Management', 'True', 'general'),
  (3, 'Dependencies', 'False', 'general'),
  (3, 'Goals/OKRs', 'True', 'general'),
  (3, 'Forms', 'True', 'general'),
  (3, 'Guest Access', 'True', 'collaboration'),
  (3, 'File Sharing', 'False', 'general'),
  (3, 'Comments/Mentions', 'False', 'collaboration'),
  (3, 'Templates', 'True', 'general'),
  (3, 'Calendar View', 'True', 'general'),
  (4, 'Task Management', 'True', 'general'),
  (4, 'Kanban Boards', 'True', 'general'),
  (4, 'Gantt Charts', 'False', 'analytics'),
  (4, 'Time Tracking', 'True', 'general'),
  (4, 'Sprints/Scrum', 'True', 'general'),
  (4, 'Roadmaps', 'True', 'general'),
  (4, 'Automation', 'True', 'ai'),
  (4, 'Reporting/Analytics', 'True', 'analytics'),
  (4, 'Custom Workflows', 'True', 'general'),
  (4, 'API/Integrations', 'True', 'integration'),
  (4, 'Mobile App', 'False', 'mobile'),
  (4, 'Resource Management', 'True', 'general'),
  (4, 'Dependencies', 'False', 'general'),
  (4, 'Goals/OKRs', 'False', 'general'),
  (4, 'Forms', 'True', 'general'),
  (4, 'Guest Access', 'False', 'collaboration'),
  (4, 'File Sharing', 'True', 'general'),
  (4, 'Comments/Mentions', 'True', 'collaboration'),
  (4, 'Templates', 'True', 'general'),
  (4, 'Calendar View', 'True', 'general'),
  (5, 'Task Management', 'True', 'general'),
  (5, 'Kanban Boards', 'True', 'general'),
  (5, 'Gantt Charts', 'False', 'analytics'),
  (5, 'Time Tracking', 'False', 'general'),
  (5, 'Sprints/Scrum', 'False', 'general'),
  (5, 'Roadmaps', 'False', 'general'),
  (5, 'Automation', 'False', 'ai'),
  (5, 'Reporting/Analytics', 'False', 'analytics'),
  (5, 'Custom Workflows', 'True', 'general'),
  (5, 'API/Integrations', 'True', 'integration'),
  (5, 'Mobile App', 'True', 'mobile'),
  (5, 'Resource Management', 'False', 'general'),
  (5, 'Dependencies', 'False', 'general'),
  (5, 'Goals/OKRs', 'False', 'general'),
  (5, 'Forms', 'False', 'general'),
  (5, 'Guest Access', 'True', 'collaboration'),
  (5, 'File Sharing', 'True', 'general'),
  (5, 'Comments/Mentions', 'True', 'collaboration'),
  (5, 'Templates', 'True', 'general'),
  (5, 'Calendar View', 'True', 'general'),
  (6, 'Task Management', 'True', 'general'),
  (6, 'Kanban Boards', 'True', 'general'),
  (6, 'Gantt Charts', 'False', 'analytics'),
  (6, 'Time Tracking', 'False', 'general'),
  (6, 'Sprints/Scrum', 'True', 'general'),
  (6, 'Roadmaps', 'False', 'general'),
  (6, 'Automation', 'True', 'ai'),
  (6, 'Reporting/Analytics', 'True', 'analytics'),
  (6, 'Custom Workflows', 'True', 'general'),
  (6, 'API/Integrations', 'True', 'integration'),
  (6, 'Mobile App', 'False', 'mobile'),
  (6, 'Resource Management', 'False', 'general'),
  (6, 'Dependencies', 'True', 'general'),
  (6, 'Goals/OKRs', 'True', 'general'),
  (6, 'Forms', 'True', 'general'),
  (6, 'Guest Access', 'False', 'collaboration'),
  (6, 'File Sharing', 'False', 'general'),
  (6, 'Comments/Mentions', 'False', 'collaboration'),
  (6, 'Templates', 'True', 'general'),
  (6, 'Calendar View', 'True', 'general'),
  (7, 'Task Management', 'True', 'general'),
  (7, 'Kanban Boards', 'True', 'general'),
  (7, 'Gantt Charts', 'False', 'analytics'),
  (7, 'Time Tracking', 'False', 'general'),
  (7, 'Sprints/Scrum', 'False', 'general'),
  (7, 'Roadmaps', 'False', 'general'),
  (7, 'Automation', 'False', 'ai'),
  (7, 'Reporting/Analytics', 'True', 'analytics'),
  (7, 'Custom Workflows', 'True', 'general'),
  (7, 'API/Integrations', 'True', 'integration'),
  (7, 'Mobile App', 'False', 'mobile'),
  (7, 'Resource Management', 'False', 'general'),
  (7, 'Dependencies', 'False', 'general'),
  (7, 'Goals/OKRs', 'False', 'general'),
  (7, 'Forms', 'False', 'general'),
  (7, 'Guest Access', 'True', 'collaboration'),
  (7, 'File Sharing', 'True', 'general'),
  (7, 'Comments/Mentions', 'True', 'collaboration'),
  (7, 'Templates', 'False', 'general'),
  (7, 'Calendar View', 'True', 'general'),
  (8, 'Task Management', 'True', 'general'),
  (8, 'Kanban Boards', 'True', 'general'),
  (8, 'Gantt Charts', 'True', 'analytics'),
  (8, 'Time Tracking', 'False', 'general'),
  (8, 'Sprints/Scrum', 'False', 'general'),
  (8, 'Roadmaps', 'False', 'general'),
  (8, 'Automation', 'True', 'ai'),
  (8, 'Reporting/Analytics', 'True', 'analytics'),
  (8, 'Custom Workflows', 'True', 'general'),
  (8, 'API/Integrations', 'True', 'integration'),
  (8, 'Mobile App', 'True', 'mobile'),
  (8, 'Resource Management', 'True', 'general'),
  (8, 'Dependencies', 'True', 'general'),
  (8, 'Goals/OKRs', 'False', 'general'),
  (8, 'Forms', 'True', 'general'),
  (8, 'Guest Access', 'False', 'collaboration'),
  (8, 'File Sharing', 'False', 'general'),
  (8, 'Comments/Mentions', 'False', 'collaboration'),
  (8, 'Templates', 'True', 'general'),
  (8, 'Calendar View', 'True', 'general'),
  (9, 'Task Management', 'True', 'general'),
  (9, 'Kanban Boards', 'False', 'general'),
  (9, 'Gantt Charts', 'False', 'analytics'),
  (9, 'Time Tracking', 'True', 'general'),
  (9, 'Sprints/Scrum', 'False', 'general'),
  (9, 'Roadmaps', 'False', 'general'),
  (9, 'Automation', 'True', 'ai'),
  (9, 'Reporting/Analytics', 'True', 'analytics'),
  (9, 'Custom Workflows', 'True', 'general'),
  (9, 'API/Integrations', 'True', 'integration'),
  (9, 'Mobile App', 'False', 'mobile'),
  (9, 'Resource Management', 'True', 'general'),
  (9, 'Dependencies', 'False', 'general'),
  (9, 'Goals/OKRs', 'False', 'general'),
  (9, 'Forms', 'True', 'general'),
  (9, 'Guest Access', 'False', 'collaboration'),
  (9, 'File Sharing', 'False', 'general'),
  (9, 'Comments/Mentions', 'False', 'collaboration'),
  (9, 'Templates', 'True', 'general'),
  (9, 'Calendar View', 'True', 'general'),
  (10, 'Task Management', 'True', 'general'),
  (10, 'Kanban Boards', 'True', 'general'),
  (10, 'Gantt Charts', 'False', 'analytics'),
  (10, 'Time Tracking', 'False', 'general'),
  (10, 'Sprints/Scrum', 'False', 'general'),
  (10, 'Roadmaps', 'True', 'general'),
  (10, 'Automation', 'True', 'ai'),
  (10, 'Reporting/Analytics', 'True', 'analytics'),
  (10, 'Custom Workflows', 'True', 'general'),
  (10, 'API/Integrations', 'True', 'integration'),
  (10, 'Mobile App', 'True', 'mobile'),
  (10, 'Resource Management', 'False', 'general'),
  (10, 'Dependencies', 'False', 'general'),
  (10, 'Goals/OKRs', 'False', 'general'),
  (10, 'Forms', 'False', 'general'),
  (10, 'Guest Access', 'False', 'collaboration'),
  (10, 'File Sharing', 'False', 'general'),
  (10, 'Comments/Mentions', 'False', 'collaboration'),
  (10, 'Templates', 'False', 'general'),
  (10, 'Calendar View', 'False', 'general'),
  (11, 'Task Management', 'True', 'general'),
  (11, 'Kanban Boards', 'True', 'general'),
  (11, 'Gantt Charts', 'False', 'analytics'),
  (11, 'Time Tracking', 'False', 'general'),
  (11, 'Sprints/Scrum', 'False', 'general'),
  (11, 'Roadmaps', 'False', 'general'),
  (11, 'Automation', 'True', 'ai'),
  (11, 'Reporting/Analytics', 'True', 'analytics'),
  (11, 'Custom Workflows', 'True', 'general'),
  (11, 'API/Integrations', 'True', 'integration'),
  (11, 'Mobile App', 'False', 'mobile'),
  (11, 'Resource Management', 'True', 'general'),
  (11, 'Dependencies', 'False', 'general'),
  (11, 'Goals/OKRs', 'False', 'general'),
  (11, 'Forms', 'False', 'general'),
  (11, 'Guest Access', 'False', 'collaboration'),
  (11, 'File Sharing', 'False', 'general'),
  (11, 'Comments/Mentions', 'False', 'collaboration'),
  (11, 'Templates', 'False', 'general'),
  (11, 'Calendar View', 'False', 'general'),
  (12, 'Task Management', 'True', 'general'),
  (12, 'Kanban Boards', 'True', 'general'),
  (12, 'Gantt Charts', 'True', 'analytics'),
  (12, 'Time Tracking', 'True', 'general'),
  (12, 'Sprints/Scrum', 'False', 'general'),
  (12, 'Roadmaps', 'False', 'general'),
  (12, 'Automation', 'True', 'ai'),
  (12, 'Reporting/Analytics', 'True', 'analytics'),
  (12, 'Custom Workflows', 'True', 'general'),
  (12, 'API/Integrations', 'True', 'integration'),
  (12, 'Mobile App', 'True', 'mobile'),
  (12, 'Resource Management', 'True', 'general'),
  (12, 'Dependencies', 'False', 'general'),
  (12, 'Goals/OKRs', 'True', 'general'),
  (12, 'Forms', 'True', 'general'),
  (12, 'Guest Access', 'True', 'collaboration'),
  (12, 'File Sharing', 'False', 'general'),
  (12, 'Comments/Mentions', 'True', 'collaboration'),
  (12, 'Templates', 'True', 'general'),
  (12, 'Calendar View', 'True', 'general'),
  (13, 'Task Management', 'True', 'general'),
  (13, 'Kanban Boards', 'False', 'general'),
  (13, 'Gantt Charts', 'True', 'analytics'),
  (13, 'Time Tracking', 'True', 'general'),
  (13, 'Sprints/Scrum', 'False', 'general'),
  (13, 'Roadmaps', 'True', 'general'),
  (13, 'Automation', 'True', 'ai'),
  (13, 'Reporting/Analytics', 'True', 'analytics'),
  (13, 'Custom Workflows', 'True', 'general'),
  (13, 'API/Integrations', 'True', 'integration'),
  (13, 'Mobile App', 'True', 'mobile'),
  (13, 'Resource Management', 'True', 'general'),
  (13, 'Dependencies', 'True', 'general'),
  (13, 'Goals/OKRs', 'True', 'general'),
  (13, 'Forms', 'True', 'general'),
  (13, 'Guest Access', 'True', 'collaboration'),
  (13, 'File Sharing', 'True', 'general'),
  (13, 'Comments/Mentions', 'True', 'collaboration'),
  (13, 'Templates', 'True', 'general'),
  (13, 'Calendar View', 'True', 'general'),
  (14, 'Task Management', 'True', 'general'),
  (14, 'Kanban Boards', 'False', 'general'),
  (14, 'Gantt Charts', 'False', 'analytics'),
  (14, 'Time Tracking', 'False', 'general'),
  (14, 'Sprints/Scrum', 'False', 'general'),
  (14, 'Roadmaps', 'True', 'general'),
  (14, 'Automation', 'True', 'ai'),
  (14, 'Reporting/Analytics', 'True', 'analytics'),
  (14, 'Custom Workflows', 'True', 'general'),
  (14, 'API/Integrations', 'True', 'integration'),
  (14, 'Mobile App', 'True', 'mobile'),
  (14, 'Resource Management', 'True', 'general'),
  (14, 'Dependencies', 'False', 'general'),
  (14, 'Goals/OKRs', 'False', 'general'),
  (14, 'Forms', 'False', 'general'),
  (14, 'Guest Access', 'True', 'collaboration'),
  (14, 'File Sharing', 'True', 'general'),
  (14, 'Comments/Mentions', 'True', 'collaboration'),
  (14, 'Templates', 'True', 'general'),
  (14, 'Calendar View', 'True', 'general'),
  (15, 'Task Management', 'True', 'general'),
  (15, 'Kanban Boards', 'True', 'general'),
  (15, 'Gantt Charts', 'False', 'analytics'),
  (15, 'Time Tracking', 'True', 'general'),
  (15, 'Sprints/Scrum', 'False', 'general'),
  (15, 'Roadmaps', 'False', 'general'),
  (15, 'Automation', 'False', 'ai'),
  (15, 'Reporting/Analytics', 'False', 'analytics'),
  (15, 'Custom Workflows', 'False', 'general'),
  (15, 'API/Integrations', 'True', 'integration'),
  (15, 'Mobile App', 'True', 'mobile'),
  (15, 'Resource Management', 'False', 'general'),
  (15, 'Dependencies', 'False', 'general'),
  (15, 'Goals/OKRs', 'False', 'general'),
  (15, 'Forms', 'False', 'general'),
  (15, 'Guest Access', 'False', 'collaboration'),
  (15, 'File Sharing', 'False', 'general'),
  (15, 'Comments/Mentions', 'True', 'collaboration'),
  (15, 'Templates', 'True', 'general'),
  (15, 'Calendar View', 'True', 'general'),
  (16, 'Task Management', 'True', 'general'),
  (16, 'Kanban Boards', 'True', 'general'),
  (16, 'Gantt Charts', 'False', 'analytics'),
  (16, 'Time Tracking', 'False', 'general'),
  (16, 'Sprints/Scrum', 'False', 'general'),
  (16, 'Roadmaps', 'True', 'general'),
  (16, 'Automation', 'False', 'ai'),
  (16, 'Reporting/Analytics', 'True', 'analytics'),
  (16, 'Custom Workflows', 'True', 'general'),
  (16, 'API/Integrations', 'True', 'integration'),
  (16, 'Mobile App', 'True', 'mobile'),
  (16, 'Resource Management', 'False', 'general'),
  (16, 'Dependencies', 'False', 'general'),
  (16, 'Goals/OKRs', 'True', 'general'),
  (16, 'Forms', 'False', 'general'),
  (16, 'Guest Access', 'True', 'collaboration'),
  (16, 'File Sharing', 'True', 'general'),
  (16, 'Comments/Mentions', 'True', 'collaboration'),
  (16, 'Templates', 'True', 'general'),
  (16, 'Calendar View', 'True', 'general'),
  (17, 'Task Management', 'True', 'general'),
  (17, 'Kanban Boards', 'False', 'general'),
  (17, 'Gantt Charts', 'False', 'analytics'),
  (17, 'Time Tracking', 'False', 'general'),
  (17, 'Sprints/Scrum', 'False', 'general'),
  (17, 'Roadmaps', 'True', 'general'),
  (17, 'Automation', 'True', 'ai'),
  (17, 'Reporting/Analytics', 'True', 'analytics'),
  (17, 'Custom Workflows', 'True', 'general'),
  (17, 'API/Integrations', 'True', 'integration'),
  (17, 'Mobile App', 'True', 'mobile'),
  (17, 'Resource Management', 'False', 'general'),
  (17, 'Dependencies', 'False', 'general'),
  (17, 'Goals/OKRs', 'True', 'general'),
  (17, 'Forms', 'True', 'general'),
  (17, 'Guest Access', 'True', 'collaboration'),
  (17, 'File Sharing', 'True', 'general'),
  (17, 'Comments/Mentions', 'True', 'collaboration'),
  (17, 'Templates', 'True', 'general'),
  (17, 'Calendar View', 'True', 'general'),
  (18, 'Task Management', 'True', 'general'),
  (18, 'Kanban Boards', 'True', 'general'),
  (18, 'Gantt Charts', 'False', 'analytics'),
  (18, 'Time Tracking', 'False', 'general'),
  (18, 'Sprints/Scrum', 'True', 'general'),
  (18, 'Roadmaps', 'True', 'general'),
  (18, 'Automation', 'True', 'ai'),
  (18, 'Reporting/Analytics', 'True', 'analytics'),
  (18, 'Custom Workflows', 'False', 'general'),
  (18, 'API/Integrations', 'True', 'integration'),
  (18, 'Mobile App', 'False', 'mobile'),
  (18, 'Resource Management', 'False', 'general'),
  (18, 'Dependencies', 'False', 'general'),
  (18, 'Goals/OKRs', 'True', 'general'),
  (18, 'Forms', 'False', 'general'),
  (18, 'Guest Access', 'False', 'collaboration'),
  (18, 'File Sharing', 'False', 'general'),
  (18, 'Comments/Mentions', 'True', 'collaboration'),
  (18, 'Templates', 'False', 'general'),
  (18, 'Calendar View', 'False', 'general'),
  (19, 'Task Management', 'True', 'general'),
  (19, 'Kanban Boards', 'False', 'general'),
  (19, 'Gantt Charts', 'True', 'analytics'),
  (19, 'Time Tracking', 'True', 'general'),
  (19, 'Sprints/Scrum', 'False', 'general'),
  (19, 'Roadmaps', 'True', 'general'),
  (19, 'Automation', 'True', 'ai'),
  (19, 'Reporting/Analytics', 'True', 'analytics'),
  (19, 'Custom Workflows', 'True', 'general'),
  (19, 'API/Integrations', 'True', 'integration'),
  (19, 'Mobile App', 'False', 'mobile'),
  (19, 'Resource Management', 'False', 'general'),
  (19, 'Dependencies', 'True', 'general'),
  (19, 'Goals/OKRs', 'True', 'general'),
  (19, 'Forms', 'True', 'general'),
  (19, 'Guest Access', 'True', 'collaboration'),
  (19, 'File Sharing', 'True', 'general'),
  (19, 'Comments/Mentions', 'True', 'collaboration'),
  (19, 'Templates', 'False', 'general'),
  (19, 'Calendar View', 'False', 'general'),
  (20, 'Task Management', 'True', 'general'),
  (20, 'Kanban Boards', 'False', 'general'),
  (20, 'Gantt Charts', 'True', 'analytics'),
  (20, 'Time Tracking', 'True', 'general'),
  (20, 'Sprints/Scrum', 'False', 'general'),
  (20, 'Roadmaps', 'False', 'general'),
  (20, 'Automation', 'True', 'ai'),
  (20, 'Reporting/Analytics', 'True', 'analytics'),
  (20, 'Custom Workflows', 'True', 'general'),
  (20, 'API/Integrations', 'True', 'integration'),
  (20, 'Mobile App', 'True', 'mobile'),
  (20, 'Resource Management', 'False', 'general'),
  (20, 'Dependencies', 'True', 'general'),
  (20, 'Goals/OKRs', 'False', 'general'),
  (20, 'Forms', 'False', 'general'),
  (20, 'Guest Access', 'False', 'collaboration'),
  (20, 'File Sharing', 'False', 'general'),
  (20, 'Comments/Mentions', 'False', 'collaboration'),
  (20, 'Templates', 'False', 'general'),
  (20, 'Calendar View', 'True', 'general');

-- ============================================================
-- SAMPLE DATA: Price history for first 20 products (initial snapshot 2026-04-27)
-- ============================================================
INSERT OR IGNORE INTO price_history (product_id, recorded_date, plan_name, price, notes) VALUES
  (1, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: user/mo'),
  (1, '2026-04-27', 'Plus', 12.0, 'Initial snapshot | period: user/mo'),
  (1, '2026-04-27', 'Business', 18.0, 'Initial snapshot | period: user/mo'),
  (2, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (2, '2026-04-27', 'Unlimited', 7.0, 'Initial snapshot | period: user/mo'),
  (2, '2026-04-27', 'Business', 12.0, 'Initial snapshot | period: user/mo'),
  (3, '2026-04-27', 'Personal', 0.0, 'Initial snapshot | period: forever'),
  (3, '2026-04-27', 'Starter', 10.99, 'Initial snapshot | period: user/mo'),
  (3, '2026-04-27', 'Advanced', 24.99, 'Initial snapshot | period: user/mo'),
  (4, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (4, '2026-04-27', 'Basic', 9.0, 'Initial snapshot | period: seat/mo'),
  (4, '2026-04-27', 'Standard', 12.0, 'Initial snapshot | period: seat/mo'),
  (4, '2026-04-27', 'Pro', 19.0, 'Initial snapshot | period: seat/mo'),
  (5, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (5, '2026-04-27', 'Standard', 5.0, 'Initial snapshot | period: user/mo'),
  (5, '2026-04-27', 'Premium', 10.0, 'Initial snapshot | period: user/mo'),
  (5, '2026-04-27', 'Enterprise', 17.5, 'Initial snapshot | period: user/mo'),
  (6, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (6, '2026-04-27', 'Standard', 7.91, 'Initial snapshot | period: user/mo'),
  (6, '2026-04-27', 'Premium', 14.54, 'Initial snapshot | period: user/mo'),
  (7, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (7, '2026-04-27', 'Basecamp Plus', 15.0, 'Initial snapshot | period: user/mo'),
  (7, '2026-04-27', 'Basecamp Pro Unlimited', 299.0, 'Initial snapshot | period: flat/mo'),
  (8, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (8, '2026-04-27', 'Team', 10.0, 'Initial snapshot | period: user/mo'),
  (8, '2026-04-27', 'Business', 25.0, 'Initial snapshot | period: user/mo'),
  (9, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (9, '2026-04-27', 'Deliver', 13.99, 'Initial snapshot | period: user/mo'),
  (9, '2026-04-27', 'Grow', 25.99, 'Initial snapshot | period: user/mo'),
  (9, '2026-04-27', 'Scale', 69.99, 'Initial snapshot | period: user/mo'),
  (10, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (10, '2026-04-27', 'Basic', 10.0, 'Initial snapshot | period: user/mo'),
  (10, '2026-04-27', 'Business', 16.0, 'Initial snapshot | period: user/mo'),
  (11, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (11, '2026-04-27', 'Team', 8.5, 'Initial snapshot | period: user/mo'),
  (11, '2026-04-27', 'Business', 15.0, 'Initial snapshot | period: user/mo'),
  (12, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (12, '2026-04-27', 'Starter', 5.0, 'Initial snapshot | period: user/mo'),
  (12, '2026-04-27', 'Teams', 12.0, 'Initial snapshot | period: user/mo'),
  (13, '2026-04-27', 'Pro', 9.0, 'Initial snapshot | period: user/mo'),
  (13, '2026-04-27', 'Business', 19.0, 'Initial snapshot | period: user/mo'),
  (14, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (14, '2026-04-27', 'Team', 20.0, 'Initial snapshot | period: seat/mo'),
  (14, '2026-04-27', 'Business', 45.0, 'Initial snapshot | period: seat/mo'),
  (15, '2026-04-27', 'Beginner', 0.0, 'Initial snapshot | period: forever'),
  (15, '2026-04-27', 'Pro', 5.0, 'Initial snapshot | period: user/mo'),
  (15, '2026-04-27', 'Business', 8.0, 'Initial snapshot | period: user/mo'),
  (16, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (16, '2026-04-27', 'Starter', 8.0, 'Initial snapshot | period: user/mo'),
  (16, '2026-04-27', 'Business', 20.0, 'Initial snapshot | period: user/mo'),
  (17, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: mo'),
  (17, '2026-04-27', 'Pro', 10.0, 'Initial snapshot | period: Doc Maker/mo'),
  (17, '2026-04-27', 'Team', 30.0, 'Initial snapshot | period: Doc Maker/mo'),
  (18, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (18, '2026-04-27', 'Team', 8.5, 'Initial snapshot | period: user/mo'),
  (18, '2026-04-27', 'Business', 12.0, 'Initial snapshot | period: user/mo'),
  (19, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (19, '2026-04-27', 'Starter', 39.0, 'Initial snapshot | period: flat/mo (billed annually)'),
  (19, '2026-04-27', 'Business', 124.0, 'Initial snapshot | period: flat/mo (billed annually)'),
  (19, '2026-04-27', 'Unlimited', 399.0, 'Initial snapshot | period: flat/mo (billed annually)'),
  (20, '2026-04-27', 'Free', 0.0, 'Initial snapshot | period: forever'),
  (20, '2026-04-27', 'Premium', 5.0, 'Initial snapshot | period: user/mo'),
  (20, '2026-04-27', 'Enterprise', 10.0, 'Initial snapshot | period: user/mo');

-- ============================================================
-- DATABASE STATS (as of 2026-04-27)
-- ============================================================
--   categories:    29
--   products:     331
--   pricing_plans: 1013
--   features:     6052
--   price_history:  916
--
-- Views: v_category_stats | v_llm_comparison | v_free_tier_products
-- ============================================================
