# Supabase Migration Inputs Template

Fill this out so we have all required inputs in one place. Replace every `TODO` with your values.

## 1) Supabase Project
- Project URL: TODO
- Anon key: TODO
- Service-role key: TODO
- Extensions enabled: `pg_graphql` (TODO confirm), `pg_net` if needed (TODO), `pgcrypto`/`uuid-ossp` (TODO).
- Buckets: `patient-files` (TODO created?), `profile-pictures` (TODO), `charting-assets` (TODO), other buckets: TODO.
- Collaborator access granted to: TODO

## 2) Parse Exports and Files
- Parse schema export: TODO (path/link)
- Parse data dump: TODO (path/link)
- File storage source (e.g., S3): bucket/path: TODO; access keys/role: TODO

## 3) Auth Configuration (Supabase Auth)
- SMTP host: TODO
- SMTP port: TODO
- SMTP user: TODO
- SMTP password: TODO
- From email (auth): TODO
- Google OAuth client ID: TODO
- Google OAuth client secret: TODO
- Preferred flow: TODO (magic link | password | both)
- Redirect URLs: Dev: TODO, Stage: TODO, Prod: TODO

## 4) RLS / Roles / IDs
- Role matrix (org admin/staff/patient/superadmin): TODO
- Org scoping rules (how to restrict per org): TODO
- PK strategy: TODO (UUID | serial); legacy Parse ID storage strategy: TODO

## 5) Stripe
- Stripe test secret key: TODO
- Stripe live secret key: TODO
- Webhook endpoint URL(s) to configure: TODO
- Connected accounts to preserve/migrate: TODO

## 6) Notifications (Email/SMS)
- Email provider: AWS SES (Simple Email Service)
- AWS Access Key ID: TODO (from .env: AWS_ACCESS_KEY_ID)
- AWS Secret Access Key: TODO (from .env: AWS_SECRET_ACCESS_KEY)
- AWS Region: TODO (e.g., us-east-1, ca-central-1)
- From email/domain (notifications): TODO (must be verified in AWS SES)
- SMS provider: AWS SNS (Simple Notification Service)
- From number/sender ID: TODO (configured in AWS SNS)
- Notification templates/copy: TODO (or link)

## 7) Domains / CORS
- Base URLs: Dev: TODO, Stage: TODO, Prod: TODO
- Allowed CORS origins: TODO
- Allowed webhook origins (if enforced): TODO

## 8) Feature Priority
- First migration slice (e.g., auth + scheduling): TODO
- Zero-tolerance areas (must not break): TODO

## 9) Testing
- Supabase test project/DB access: TODO
- Seed users/orgs for tests: TODO
- Test SMTP endpoint (if different): TODO
- Test SMS endpoint/number (if different): TODO
