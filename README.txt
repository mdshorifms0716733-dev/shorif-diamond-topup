SHORIF DIAMOND TOPUP CENTER BD — FULL ADMIN PANEL

This package contains a new secure Supabase Auth based Admin Dashboard.

Files:
- admin.html
- admin.js

Use:
1. Keep your existing supabase-config.js.
2. Replace old admin.html and admin.js in GitHub with these two files.
3. Open:
   https://mdshorifms0716733-dev.github.io/shorif-diamond-topup/admin.html
4. Login with the Admin email/password already created in Supabase Authentication.
5. The account must have role='admin' in public.profiles.

Dashboard:
- Overview
- Customer Orders + status update
- Package management
- Website settings
- bKash/Nagad/WhatsApp/support email
- Notice
- Admin photo upload
- Admin password change

IMPORTANT:
- This panel uses the existing database. It does not replace your tables.
- Because your current packages table has a different schema from the newer sample schema, package editing first tries the name/title form and falls back to title-only updates.
- If the database rejects a field, the error will be shown in the dashboard; do not paste secret/service_role keys.
