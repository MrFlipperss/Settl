# Settl Web

Settl is a people-first shared expense app. This React/Vite client connects to the Settl Go API and Supabase Auth. It does not ship with fixture accounts or sample ledger data.

## Local setup

1. Copy `.env.example` to `.env.local`.
2. Add the Supabase project URL and anon key from your Supabase project settings.
3. Set `VITE_API_URL` to the Settl API origin if you are not using the default.
4. Install dependencies with `npm install` and run `npm run dev`.

The public Supabase anon key belongs in browser configuration. Never put a service role key or other server secret in this app.

## Connected workflows

- Supabase email/password sign in and account creation.
- Settl profile bootstrap, including a required display name and phone.
- People search and contact creation.
- Expense logging with equal, exact, percentage, and shares splits.
- Collections, recent expense activity, and balance summaries.
- Editable plain-language expense drafts on the overview page.

Budgets, recurring subscriptions, receipt OCR, ticket storage, and verified UPI settlement are not connected to persistent backend services. The interface does not represent them as saved features.

## Commands

- `npm run dev` — start Vite locally.
- `npm run lint` — lint the web source.
- `npm run build` — produce the Vercel-ready bundle in `dist/`.
