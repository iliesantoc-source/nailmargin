# NailMargin Academy

Static GitHub Pages frontend with a separate Supabase Academy project. No service-role key belongs in the frontend or repository.

## Pages

- `academy.html`: published catalog, purchase information, private video playback by purchase code.
- `admin.html`: authenticated, RLS-protected administration; uploads via resumable TUS, tutorial prices/publication, manual payment confirmation, one-time code display, revocation, lost-code replacement and device reset.
- `academy-config.js`: public project URL and publishable key only.
- `supabase/functions/academy-api/index.ts`: deployed catalog and video authorization endpoint. Public GET returns tutorial metadata only. POST authenticates a high-entropy purchase code, binds the first browser token atomically, and issues a five-minute storage URL.
- `supabase/migrations`: actual applied migration history. Private administrator membership and payment settings are not source-controlled.

## Authentication configuration

In Supabase Authentication → URL Configuration, the Site URL is now `https://nailmargin.ro/admin.html` and the exact allowed redirect URL is `https://nailmargin.ro/admin.html` (and the www equivalent only if used). Email links must return to the admin page, where Supabase JS consumes the session fragment. Without these settings, default redirects may go to localhost. Both values were saved and verified after reloading the Supabase dashboard on 2026-11-02.

Sign in through the email link, then set a personal password in Settings. Email confirmation does not itself establish a session on the Academy domain. Only rows in `academy_admins` grant administration rights. No public signup in the dashboard.

Public HTML integration is connected to the deployed backend and admin dashboard. The owner explicitly confirmed retaining the existing payment/contact details in the public page and repository on 2026-11-02.

## Videos and activation

Upload the real video from the admin editor, then publish. Database guard requires the private storage object to exist before publication. The initial tutorial remains an unpublished draft until its video is available. Supabase plan/file-size limits still apply; resumable upload does not bypass them. MP4 with H.264/AAC is recommended for Safari compatibility; no transcoding is implemented.

After manually verifying payment, confirm it in the panel. Customer, confirmed purchase, and hashed code are created in one database transaction. Copy the full code immediately; plaintext codes are not retained. Codes never expire; playback URLs do. A second browser is rejected after first activation. Reset permits a replacement browser. This binds browser storage, not hardware; users who share their browser token can circumvent it. It is not DRM and cannot prevent screen recording. Revocation stops new playback links; an existing signed URL may work until its five-minute expiry.

The owner explicitly approved public API disclosure of beneficiary, IBAN, Revolut RevTag and WhatsApp for client payments on 2026-11-02. The catalog API selects only these payment fields. The public page refreshes both the purchase modal and a copyable payment-details panel from these settings; Admin edits therefore appear on the next page load. No customer, purchase, access-code or administrator records are returned by the public catalog API.

## Validation

- Node syntax checks for all changed scripts, inline scripts, and unique HTML IDs.
- Transactional database tests: authenticated administrator read/write; non-admin RLS denial; draft publication blocked without uploaded object; draft purchase rejected; server-generated code length/hash; first-browser binding, same-browser replay, second-browser denial, pending-payment denial, revoked-code denial.
- All database test data rolled back.
- Live catalog, CORS and invalid-code HTTP checks; unauthenticated dashboard browser checks.
- Full signed-in upload/purchase/playback QA requires browser sign-in and the real video.

