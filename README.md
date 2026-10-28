# BrandFlux website: setup guide (Android phone, no computer needed)

**Status: NOT deployed and NOT tested yet.** Do not announce the site until you finish the test list in Step 8.
Stack: plain HTML/JS site + Supabase (login, database, file storage, live chat) + Vercel (hosting). Use Chrome; open sites in "Desktop site" mode (Chrome menu ⋮ → Desktop site) if a page looks cramped.

## Step 1. Create the Supabase project (free)
1. Go to supabase.com → Sign up (use GitHub or email) → **New project**.
2. Name: BrandFlux. Set and SAVE a strong database password. Pick the region closest to your customers. Click Create and wait about 2 minutes.

## Step 2. Create the database
1. In Supabase open **SQL Editor** → **New query**.
2. Open `schema.sql` from this project, select everything, copy, paste into the editor, tap **Run**. It should say "Success". If you see an error, send me the message.

## Step 3. Add your Supabase keys to the site
1. Supabase → **Project Settings → API**. Copy the **Project URL** and the **anon / publishable** key.
2. Open `config.js` and replace `YOUR_SUPABASE_URL` and `YOUR_SUPABASE_ANON_KEY`. Put your WhatsApp number in `WHATSAPP` (digits only with country code, e.g. 923001234567).
3. SECURITY: the anon/publishable key is designed to be public. Your data is protected by the database rules in schema.sql. NEVER paste the `service_role` or "secret" key anywhere.

## Step 4. Put the project on GitHub (needed by Vercel)
1. Unzip the project with the Files by Google app (long-press the zip → Extract).
2. github.com → sign up → **+ → New repository** → name `brandflux` → Create.
3. **uploading an existing file** link → choose all 6 files (index.html, config.js, schema.sql, logo.webp, card.webp, README.md) from your phone → **Commit changes**.
4. To edit later: open the file on GitHub → pencil icon → change → Commit. Vercel redeploys automatically.

## Step 5. Deploy on Vercel (free)
1. vercel.com → Sign up with GitHub → **Add New → Project** → import `brandflux`.
2. Framework Preset: **Other**. Leave everything else empty. Tap **Deploy**. You get a link like `brandflux.vercel.app`.

## Step 6. Tell Supabase your website address
Supabase → **Authentication → URL Configuration**: set **Site URL** to your Vercel link and add the same link under **Redirect URLs**. Later add your real domain too.
Email confirmation: for testing you may turn off **Authentication → Providers → Email → Confirm email**. For real customers keep it on and set up **custom SMTP** (Authentication → Emails), because Supabase's built-in email is heavily rate-limited.

## Step 7. Create your admin account
1. On your site tap **Sign in → Create an account** using YOUR email.
2. Supabase → SQL Editor → run (use your email):
   `update public.profiles set is_admin = true where id = (select id from auth.users where email = 'YOUR_EMAIL');`
3. Sign out and in again. An **Admin** link appears. Only accounts with is_admin = true get admin data, enforced by the database, not just hidden buttons.

## Step 8. Test checklist (do all before launch)
1. Register a second test account (different email) and place an order with an image. Check you get a reference number.
2. Open **My Orders**: see the order, status Pending, and the chat.
3. Sign in as admin: open the order, view the image, tap **Accept order**, set a final price and delivery link, add a note, reply in chat.
4. As the customer: confirm status, price, delivery link and your reply appear (live or within 15 seconds).
5. Confirm the customer cannot see internal notes, other customers' orders, or the Admin page.
6. Add a portfolio video in Admin and confirm it plays on the homepage when signed out.
7. Send a Contact form message while signed out; read it in Admin.
8. Check on your phone: menu, buttons, forms.

## Videos, prices, WhatsApp
- **Videos:** Admin → Portfolio videos → title + YouTube/Vimeo/.mp4 link → Add video. (Upload to YouTube as Unlisted or Public first.)
- **Prices/descriptions:** Supabase → Table Editor → `packages` → edit a row. The site updates immediately.
- **WhatsApp:** edit `config.js` on GitHub; the link becomes `https://wa.me/<number>`.

## Domain (www.brandfluxstudio.com)
Not registered or connected by me. Check availability at a registrar (Namecheap, Cloudflare, GoDaddy) by searching the name. After buying: Vercel → your project → **Settings → Domains → Add** `www.brandfluxstudio.com` and follow the DNS records Vercel shows you (usually a CNAME for `www` and an A record or redirect for the bare domain) at your registrar. Then add the domain to Supabase URL Configuration (Step 6).

## Not included yet
Password reset, email notifications (customers see updates in-app only), file attachments inside chat (links work), an in-app pricing editor, spam protection on the contact form (add CAPTCHA before heavy traffic).
