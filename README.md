# Off the Peg

A wardrobe tracker that shows what your clothes actually cost you per wear,
and helps you decide what's worth keeping.

Log an item once, log a wear each time you put it on, and the numbers do
the rest: cost per wear, which pieces you never reach for, and where your
money's genuinely paying off versus just sitting in the cupboard.

## What it does

- **Cupboard** — every item, searchable and sortable by cost-per-wear, most/least worn, or recency. Optional photo per item.
- **Outfits** — group pieces you wear together; logging an outfit's wear logs every piece in it.
- **Insights** — wears-by-month chart, least-worn ranking, worst cost-per-wear leaderboard, spend by category, and a running tally of what you've decluttered and recouped.
- **Cull** — surfaces items that are unworn past a threshold or have a bad cost-per-wear, so you've got an actual shortlist instead of vaguely knowing "something" needs to go.
- **Wishlist** — a 7-day cooling-off pen for anything you're tempted to buy. It only unlocks "add to cupboard" after the week's up.
- **Settings** — tune the cull thresholds, set a max item count per category (with a nudge when you go over), export your data as JSON or CSV.
- **Multi-device** — sign in with email/password, your data syncs through Supabase rather than living in one browser.
- **Installable** — Add to Home Screen on both Android (Chrome) and iOS (Safari), opens full-screen like a native app.

## Stack

Plain HTML/CSS/JS, no build step, no framework. Deliberately simple:

- **[Supabase](https://supabase.com)** — Postgres database, auth, and file storage for photos
- **[Three.js](https://threejs.org)** — a small decorative 3D flourish on the sign-in screen only; fully isolated, the app works with or without it
- **[Routed Gothic](https://webonastick.com/)** by Darren Embry — a free ([SIL OFL](https://scripts.sil.org/OFL)) digitisation of _Gorton_, the mechanically-engraved lettering found on elevator plaques and building signage around Manhattan
- All third-party JS (`supabase-js`, `three.js`) is self-hosted in `/vendor` rather than pulled from a CDN at runtime — one less thing that can silently break the app if a CDN request fails

## Setup

### 1. Supabase project

1. Create a new project at [supabase.com](https://supabase.com).
2. **Storage → New bucket** → name it exactly `item-photos` → leave "Public bucket" **unchecked**.
3. **Authentication → Providers → Email** → enable it. Since this is meant for one person (or a couple), also consider unticking "Confirm email" to skip the verification step.
4. **Authentication → Sign In / Providers** → once your own account exists, turn off "Allow new users to sign up" so the public URL can't be used to create other accounts.
5. **SQL Editor → New query** → paste in and run [`schema.sql`](./schema.sql). This creates every table, row-level security policy, and storage policy in one go.
6. **Project Settings → API** → copy the **Project URL** and the **anon / publishable key**.

### 2. Wire up the app

Open `index.html` and find these two lines near the top of the script:

```js
const SUPABASE_URL = "...";
const SUPABASE_ANON_KEY = "...";
```

Replace them with your own project's values from step 1.6. This key is meant to be public — it's not a secret, your RLS policies are what actually protect the data, not the key.

### 3. Deploy

This is a static site, any static host works, but it was built and tested against GitHub Pages:

1. Push this repo to GitHub.
2. **Settings → Pages** → Source: _Deploy from a branch_ → Branch: `main`, folder: `/ (root)` → Save.
3. Your site will be live at `https://<username>.github.io/<repo>/`.

### 4. Install it on your phone

- **Android (Chrome)**: open the site → menu → _Install app_ / _Add to Home Screen_.
- **iOS**: has to be **Safari**, not Chrome (Apple restricts this to its own browser) → Share icon → _Add to Home Screen_.

## Repo structure

```
├── index.html              the whole app
├── styles.css
├── manifest.json           PWA config
├── service-worker.js       makes it installable; network-first for HTML/CSS so updates always land
├── schema.sql              full database setup — run once on a fresh Supabase project
├── vendor/
│   ├── supabase.js         self-hosted Supabase client
│   ├── three.module.min.js self-hosted Three.js
│   └── three.core.min.js   Three.js's own internal dependency
├── fonts/
│   ├── routed-gothic*.woff2
│   └── routed-gothic-LICENSE.md
└── icons/                  app icons for home screen install
```

## Notes on how data works

- All photos are resized client-side (max 1000px edge, JPEG) before upload, so a multi-MB phone photo doesn't turn into a multi-MB database entry.
- Photos are private, scoped to your own storage folder, and served via short-lived signed URLs, not public links.
- Retiring an item (donated/sold/binned) doesn't delete it, it just drops out of the active views and gets logged under Insights → Decluttered, so there's a record of what actually left the wardrobe and what it recouped.
- Deleting an item _is_ permanent, and also cleans up its stored photo.

## A note on scope

This was built for one person's actual wardrobe, not as a general product. Sign-up is meant to be turned off after the first account exists (see setup step 4). If you fork this for your own use, that's exactly what it's for, just don't expect a multi-tenant SaaS out of it without more work than this README covers.
