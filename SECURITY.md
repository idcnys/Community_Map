# Security Policy

## Reporting a Vulnerability

If you discover a security vulnerability, please email **idcnys@users.noreply.github.com**.
Do NOT open a public issue.

## What Is Safe to Expose (Client-Side Identifiers)

| Item | Why It Is Safe |
|:---|:---|
| Firebase API keys | Client-side identifiers, not secrets. Security comes from Firestore Rules + App Check. |
| Supabase publishable key | Designed for client use (analogous to Firebase API keys). |
| Cloudinary cloud name + unsigned preset | Unsigned presets are designed for client-side uploads. No secret key exposed. |
| OAuth client IDs | Required for Google Sign-In to function. Standard in every public Flutter+Firebase repo. |

## What Must Stay Private

- `.env` file (contains Supabase URL + publishable key, Cloudinary config)
- Any `*_service_role*` or `*_secret*` keys
- Firestore service account JSON
- Release signing keys / keystores
- Supabase Edge Function service-role tokens

## Security Measures in Place

- `.env` is gitignored; only `.env.example` with placeholders is committed
- Firebase Auth with email verification gate
- Firestore access scoped to authenticated users
- Push notifications routed through Supabase Edge Function (server-side FCM HTTP v1 API)
- Release builds use `--obfuscate` and `--split-debug-info`

## Recommendations for Contributors

1. Never commit `.env`, keystores, or service account files
2. Keep Firestore security rules restrictive (deny by default)
3. Use Firebase App Check in production
4. Rotate any key that is accidentally committed immediately
