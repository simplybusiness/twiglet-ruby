# Trusted Publishing Setup

This repository now uses RubyGems trusted publishing via GitHub Actions OIDC tokens, eliminating the need for stored API keys.

## How it works

1. **Automated Publishing**: When code is pushed to the `master` branch, the workflow automatically:
   - Runs the full test suite across multiple Ruby versions (3.1, 3.2, 3.3, 3.4)
   - Builds the gem if tests pass
   - Publishes to RubyGems using OIDC token authentication
   - Creates a GitHub release

2. **Security**: No stored credentials are needed. Authentication happens via:
   - GitHub's OIDC token provider
   - RubyGems trusted publishing configuration
   - Repository-specific permissions

## Configuration Required

To enable trusted publishing for this gem on RubyGems:

1. Go to <https://rubygems.org/gems/twiglet/trusted_publishers>
2. Add a new trusted publisher with:
   - **Repository**: `simplybusiness/twiglet-ruby`
   - **Workflow**: `gem-publish.yml`
   - **Environment**: (leave blank)

## Benefits

- ✅ No stored API keys or secrets
- ✅ Automatic key rotation via OIDC tokens
- ✅ Repository-scoped permissions
- ✅ Audit trail through GitHub Actions
- ✅ Tests must pass before publishing

## Workflow Details

The publishing workflow (`/.github/workflows/gem-publish.yml`) uses:

- `rubygems/configure-rubygems-credentials@v1.0.0` for OIDC authentication
- Required permissions: `id-token: write` and `contents: write`
- Multi-stage process: test → build → publish → release