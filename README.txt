SHORIF DIAMOND TOPUP CENTER BD — Secure Admin v1

This version replaces the demo hard-coded admin login with Supabase Auth.
Files:
- index.html / style.css / script.js : public site
- admin.html : secure admin login + password change
- supabase-config.js : ONLY public Supabase URL + publishable key
- supabase_schema.sql : database/RLS setup
- assets/owner.png : owner image

Setup:
1. Create a Supabase project.
2. Create the Admin user in Authentication > Users.
3. Run supabase_schema.sql in SQL Editor.
4. Add the Admin user's UUID to public.profiles with role=admin.
5. Put the project URL and publishable key in supabase-config.js.
6. Upload these files to GitHub Pages.

IMPORTANT:
Never put a Supabase secret/service_role key in browser code.
The database-backed website settings/packages/order dashboard will be connected in the next step.
For real payment/business accounts, involve a parent/guardian and follow the payment provider's rules.
