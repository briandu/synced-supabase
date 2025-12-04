# Documentation Index

This directory contains comprehensive documentation for the Supabase database repository.

## Directory Structure

```
docs/
├── migrations/     # Migration guides, status, and feature-specific docs
├── architecture/   # Database architecture decisions and patterns
├── testing/        # Testing guides and plans
└── scripts/        # Script documentation (to be added)
```

## Key Documents

### Migration Documentation (`migrations/`)

**Getting Started:**
- [`SUPABASE_RUNNING_GUIDE.md`](migrations/SUPABASE_RUNNING_GUIDE.md) - Complete setup and running guide
- [`APPLY_MIGRATIONS_GUIDE.md`](migrations/APPLY_MIGRATIONS_GUIDE.md) - How to apply migrations
- [`FIND_DATABASE_CREDENTIALS.md`](migrations/FIND_DATABASE_CREDENTIALS.md) - Finding database credentials

**Migration Status:**
- [`SUPABASE_MIGRATION_CHECKLIST.md`](migrations/SUPABASE_MIGRATION_CHECKLIST.md) - Complete migration checklist
- [`MIGRATION_SCRIPT_SEQUENCE.md`](migrations/MIGRATION_SCRIPT_SEQUENCE.md) - Migration file sequence
- [`MIGRATION_PROGRESS_SUMMARY.md`](migrations/MIGRATION_PROGRESS_SUMMARY.md) - Overall progress summary
- [`FINAL_MIGRATION_STATUS.md`](migrations/FINAL_MIGRATION_STATUS.md) - Final migration status

**Feature-Specific:**
- [`GRAPHQL_CAMELCASE_MIGRATION.md`](migrations/GRAPHQL_CAMELCASE_MIGRATION.md) - GraphQL camelCase migration
- [`GRAPHQL_MIGRATION_QUICK_REFERENCE.md`](migrations/GRAPHQL_MIGRATION_QUICK_REFERENCE.md) - GraphQL quick reference
- [`STORAGE_MIGRATION_STATUS.md`](migrations/STORAGE_MIGRATION_STATUS.md) - Storage migration status
- [`STRIPE_WEBHOOK_IMPLEMENTATION.md`](migrations/STRIPE_WEBHOOK_IMPLEMENTATION.md) - Stripe webhook implementation
- [`CHAT_REALTIME_SETUP.md`](migrations/CHAT_REALTIME_SETUP.md) - Chat and realtime setup

**Phase Completion Reports:**
- [`PHASE3_AUTH_COMPLETE.md`](migrations/PHASE3_AUTH_COMPLETE.md) - Auth migration complete
- [`PHASE4_GRAPHQL_COMPLETE.md`](migrations/PHASE4_GRAPHQL_COMPLETE.md) - GraphQL migration complete
- [`PHASE5_STORAGE_COMPLETE.md`](migrations/PHASE5_STORAGE_COMPLETE.md) - Storage migration complete
- [`PHASE6_API_ROUTES_COMPLETE.md`](migrations/PHASE6_API_ROUTES_COMPLETE.md) - API routes complete
- [`PHASE7_STRIPE_COMPLETE.md`](migrations/PHASE7_STRIPE_COMPLETE.md) - Stripe integration complete
- [`PHASE8_REALTIME_COMPLETE.md`](migrations/PHASE8_REALTIME_COMPLETE.md) - Realtime complete
- [`PHASE9_NOTIFICATIONS_IMPLEMENTATION.md`](migrations/PHASE9_NOTIFICATIONS_IMPLEMENTATION.md) - Notifications implementation

### Architecture Documentation (`architecture/`)

- [`SUPABASE_TRANSACTIONAL_OPERATIONS.md`](architecture/SUPABASE_TRANSACTIONAL_OPERATIONS.md) - Guide for creating transactional operations using PostgreSQL functions

### Testing Documentation (`testing/`)

- [`TESTING_GUIDE.md`](testing/TESTING_GUIDE.md) - Comprehensive testing guide
- [`PHASE11_TESTING_PLAN.md`](testing/PHASE11_TESTING_PLAN.md) - Testing plan for Phase 11
- [`SUPABASE_MCP_SETUP.md`](testing/SUPABASE_MCP_SETUP.md) - Supabase MCP setup

### Root Documentation

- [`../SUPABASE_MIGRATION_PLAN.md`](../SUPABASE_MIGRATION_PLAN.md) - Overall migration plan
- [`../SUPABASE_MIGRATION_REQUIREMENTS.md`](../SUPABASE_MIGRATION_REQUIREMENTS.md) - Migration requirements
- [`../SUPABASE_MIGRATION_INPUTS_TEMPLATE.md`](../SUPABASE_MIGRATION_INPUTS_TEMPLATE.md) - Inputs template (deprecated)

## Quick Links

- **Getting Started**: [`migrations/SUPABASE_RUNNING_GUIDE.md`](migrations/SUPABASE_RUNNING_GUIDE.md)
- **Migration Checklist**: [`migrations/SUPABASE_MIGRATION_CHECKLIST.md`](migrations/SUPABASE_MIGRATION_CHECKLIST.md)
- **Transactional Operations**: [`architecture/SUPABASE_TRANSACTIONAL_OPERATIONS.md`](architecture/SUPABASE_TRANSACTIONAL_OPERATIONS.md)
- **Testing Guide**: [`testing/TESTING_GUIDE.md`](testing/TESTING_GUIDE.md)

