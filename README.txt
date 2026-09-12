SHORIF DIAMOND TOPUP CENTER BD — FULL WEBSITE

Included:
- index.html: Home / Tutorial / Topup / Contact Us, notice popup, intro animation, manual order, payment, tracking
- account.html + account.js: Player Sign Up/Login, profile photo, order history
- admin.html + admin.js: secure Supabase Admin Panel, packages, orders, settings, admin photo, password change
- style.css: responsive gaming-inspired design
- script.js: public Supabase app logic
- supabase_schema.sql: database, RLS, tracking RPC, storage buckets/policies, package seed
- supabase-config.js: public URL + publishable key only
- assets/owner.png: supplied Admin photo

SETUP:
1) In Supabase SQL Editor run ALL of supabase_schema.sql.
2) Confirm the existing Admin UUID is still 0a17e9b4-617a-4ff2-9ea6-42912dbb2520 and role=admin.
3) If Email confirmation is enabled in Supabase Auth, Player must verify email before first login.
4) Upload the whole folder to GitHub Pages. Keep assets/owner.png in the assets folder.
5) Open index.html.

IMPORTANT:
- Do NOT put a service_role/secret key in supabase-config.js.
- Manual topup is the current flow. Auto-topup can be added later through a secure server-side/API integration.
- Payment accounts and any business operation should follow the payment provider's rules and involve a parent/guardian where required.
