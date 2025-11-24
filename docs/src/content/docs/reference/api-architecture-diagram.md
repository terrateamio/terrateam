---
title: API Architecture Diagram
description: Visual explanation of how Terrateam's API authentication works
---

# API Architecture Diagram

## Why Two Different Authentication Systems?

**Common Question:** "Why can't I just use my GitHub App token to call the Terrateam API?"

**Answer:** GitHub App tokens and Terrateam API tokens serve completely different purposes in different systems:

```
┌─────────────────────────────────────────────────────────────┐
│                    Two Separate Systems                      │
└─────────────────────────────────────────────────────────────┘

┌──────────────────────────┐        ┌──────────────────────────┐
│  GitHub's System         │        │  Terrateam's System      │
│  (You don't control)     │        │  (We control)            │
├──────────────────────────┤        ├──────────────────────────┤
│                          │        │                          │
│  GitHub App Token        │        │  Terrateam API Token     │
│  • GitHub creates it     │        │  • Terrateam creates it  │
│  • Works on GitHub API   │        │  • Works on Terrateam API│
│  • Controls GitHub       │        │  • Controls Terrateam    │
│    resources             │        │    resources             │
│                          │        │                          │
└──────────────────────────┘        └──────────────────────────┘
         ▲                                     ▲
         │                                     │
         │  Used for:                          │  Used for:
         │  - Creating PRs                     │  - Listing workspaces
         │  - Adding comments                  │  - Getting work manifests
         │  - Updating check runs              │  - Using KV store
         │  - Managing repos                   │  - Querying stacks
         │                                     │
```

## Complete System Architecture

Here's how everything fits together:

```
┌─────────────────────────────────────────────────────────────────────┐
│                              User/Client                             │
│  (Developer using Terrateam API programmatically)                   │
└───────────┬─────────────────────────────────────────────────────────┘
            │
            │ Step 1: One-time setup
            │ Create API Key via UI
            │
            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Terrateam Web UI                                │
│                   https://app.terrateam.io                           │
├─────────────────────────────────────────────────────────────────────┤
│  Settings → API Access → Create API Key                             │
│                                                                      │
│  [✓] Installation Access   [✓] KV Store Read   [✓] KV Store Write  │
│                                                                      │
│  Generated API Key: tt_live_abc123xyz...                            │
│  (Save this - shown only once!)                                     │
└───────────┬─────────────────────────────────────────────────────────┘
            │
            │ Returns: Long-lived API Key
            │
            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Client Application                              │
│  (Your script, CI/CD, or application)                               │
└───────────┬─────────────────────────────────────────────────────────┘
            │
            │ Step 2: Exchange API Key for Access Token
            │ (Do this before each API call or when token expires)
            │
            ▼
    POST /api/v1/access-token/refresh
    Authorization: Bearer tt_live_abc123xyz...
            │
            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Terrateam API Server                               │
│                                                                      │
│  ┌────────────────────────────────────────────────────────┐         │
│  │ 1. Session Middleware                                  │         │
│  │    • Validates API Key signature                       │         │
│  │    • Checks key is not revoked                         │         │
│  │    • Extracts capabilities from key                    │         │
│  └────────────────────────────────────────────────────────┘         │
│                          │                                           │
│                          ▼                                           │
│  ┌────────────────────────────────────────────────────────┐         │
│  │ 2. Token Generator                                     │         │
│  │    • Creates JWT with user ID + capabilities           │         │
│  │    • Sets expiration: now + 60 seconds                 │         │
│  │    • Signs with secret key                             │         │
│  └────────────────────────────────────────────────────────┘         │
│                                                                      │
└───────────┬─────────────────────────────────────────────────────────┘
            │
            │ Returns: Short-lived Access Token (JWT)
            │ { "access_token": "eyJhbG...", "expires_in": 60 }
            │
            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Client Application                              │
│  Stores token temporarily (valid for 60 seconds)                    │
└───────────┬─────────────────────────────────────────────────────────┘
            │
            │ Step 3: Make API calls with Access Token
            │
            ▼
    GET /api/v1/github/installations/12345/work-manifests
    Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
            │
            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Terrateam API Server                               │
│                                                                      │
│  ┌────────────────────────────────────────────────────────┐         │
│  │ 1. Session Middleware                                  │         │
│  │    • Validates JWT signature                           │         │
│  │    • Checks expiration (< 60 seconds old?)             │         │
│  │    • Extracts user ID + capabilities                   │         │
│  └──────────────────────┬─────────────────────────────────┘         │
│                         │                                            │
│                         ▼                                            │
│  ┌────────────────────────────────────────────────────────┐         │
│  │ 2. Router → Handler                                    │         │
│  │    • Matches URL pattern                               │         │
│  │    • Checks required capabilities                      │         │
│  │      (needs "Installation_id" capability)              │         │
│  └──────────────────────┬─────────────────────────────────┘         │
│                         │                                            │
│                         ▼                                            │
│  ┌────────────────────────────────────────────────────────┐         │
│  │ 3. Business Logic                                      │         │
│  │    • Verify user has access to installation 12345      │         │
│  │    • Query database for work manifests                 │         │
│  │    • Serialize results to JSON                         │         │
│  └────────────────────────────────────────────────────────┘         │
│                                                                      │
└───────────┬─────────────────────────────────────────────────────────┘
            │
            │ Returns: API Response
            │ { "work_manifests": [...] }
            │
            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      Client Application                              │
│  Process the data!                                                  │
└─────────────────────────────────────────────────────────────────────┘
```

## Where GitHub App Authentication Fits In

GitHub App authentication is used by **Terrateam's backend** to interact with GitHub on your behalf. You never use it directly:

```
┌─────────────────────────────────────────────────────────────────────┐
│                        Your GitHub Org                               │
│  (e.g., github.com/mycompany)                                       │
└───────────┬─────────────────────────────────────────────────────────┘
            │
            │ 1. You install Terrateam GitHub App
            │    (one-time setup)
            │
            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      GitHub's System                                 │
│                                                                      │
│  Installation Created:                                              │
│  • Installation ID: 12345                                           │
│  • Permissions: Read/Write PRs, Contents, Checks                    │
│  • Org: mycompany                                                   │
└───────────┬─────────────────────────────────────────────────────────┘
            │
            │ When events happen (PR opened, push, etc.)
            │
            ▼
    POST https://app.terrateam.io/api/github/v1/events
    X-GitHub-Delivery: webhook-id
    X-Hub-Signature-256: sha256=...

    { "action": "opened", "pull_request": {...} }
            │
            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                   Terrateam Backend                                  │
│                                                                      │
│  ┌────────────────────────────────────────────────────────┐         │
│  │ Webhook Handler                                        │         │
│  │ 1. Verifies webhook signature                          │         │
│  │ 2. Processes PR event                                  │         │
│  │ 3. Needs to update PR with status                      │         │
│  └──────────────────────┬─────────────────────────────────┘         │
│                         │                                            │
│                         ▼                                            │
│  ┌────────────────────────────────────────────────────────┐         │
│  │ GitHub Client                                          │         │
│  │ • Gets Installation Token from GitHub                  │         │
│  │ • Uses token to call GitHub API                        │         │
│  │ • Creates check run, adds comments, etc.               │         │
│  └────────────────────────────────────────────────────────┘         │
│                                                                      │
└───────────┬─────────────────────────────────────────────────────────┘
            │
            │ Uses GitHub App Installation Token
            │ (Terrateam gets this from GitHub automatically)
            │
            ▼
    POST https://api.github.com/repos/mycompany/myrepo/check-runs
    Authorization: Bearer ghs_installationtoken123...

    { "name": "terrateam", "status": "completed" }
            │
            ▼
┌─────────────────────────────────────────────────────────────────────┐
│                      GitHub's API                                    │
│  Creates check run on PR                                            │
└─────────────────────────────────────────────────────────────────────┘
```

## Side-by-Side Comparison

| Aspect | GitHub App Token | Terrateam API Token |
|--------|------------------|---------------------|
| **Created by** | GitHub | Terrateam |
| **Used to access** | GitHub's API (api.github.com) | Terrateam's API (app.terrateam.io) |
| **Who uses it** | Terrateam's backend (you don't see it) | Your application/script |
| **Purpose** | Let Terrateam update PRs, repos, etc. | Let you query Terrateam data |
| **Lifetime** | ~60 minutes (GitHub manages) | 60 seconds (you refresh it) |
| **Permissions** | GitHub App permissions (repos, PRs, checks) | Terrateam capabilities (installations, KV store) |
| **Example use** | Post comment on PR | List work manifests for PR |

## Two-Token Flow: Why 60 Seconds?

You might wonder: "Why do I need to refresh my token every 60 seconds? That seems annoying!"

```
┌─────────────────────────────────────────────────────────────────────┐
│                    Security Benefits                                 │
└─────────────────────────────────────────────────────────────────────┘

API Key (long-lived)              Access Token (60 seconds)
─────────────────────              ─────────────────────────

🔑 Store securely                  ✈️  Can be transmitted freely
🏦 Keep in secrets manager         📡 Sent in every API request
⚠️  If stolen: Big problem        ✅ If stolen: Expires in 60s
🔒 Rarely transmitted              🔄 Refresh as needed
💎 Precious - protect it!          ⚡ Ephemeral - use and refresh

                    ▼

               Best Practice:

    1. Store API key in environment variable
       export TERRATEAM_API_KEY="tt_live_..."

    2. In your code, implement auto-refresh:

       function getAccessToken() {
         if (cachedToken && !isExpired(cachedToken)) {
           return cachedToken
         }

         // Refresh when expired
         const response = await fetch(
           'https://app.terrateam.io/api/v1/access-token/refresh',
           {
             headers: {
               'Authorization': `Bearer ${process.env.TERRATEAM_API_KEY}`
             }
           }
         )

         cachedToken = response.access_token
         return cachedToken
       }

    3. Use access token for API calls:

       const token = await getAccessToken()
       const manifests = await fetch(
         'https://app.terrateam.io/api/v1/github/installations/12345/work-manifests',
         {
           headers: {
             'Authorization': `Bearer ${token}`
           }
         }
       )
```

## Common Scenarios

### Scenario 1: I want to list work manifests from my CI/CD

```
You:   "I need to get work manifest data in GitHub Actions"

You:   Create API Key in Terrateam UI
       ├─ Select "Installation Access" capability
       └─ Save key: tt_live_abc123...

You:   Add to GitHub Secrets
       └─ TERRATEAM_API_KEY = tt_live_abc123...

Your GitHub Action:

       - name: Get Work Manifests
         run: |
           # Step 1: Get access token
           TOKEN=$(curl -X POST \
             https://app.terrateam.io/api/v1/access-token/refresh \
             -H "Authorization: Bearer ${{ secrets.TERRATEAM_API_KEY }}" \
             | jq -r '.access_token')

           # Step 2: Use token to call API
           curl https://app.terrateam.io/api/v1/github/installations/12345/work-manifests \
             -H "Authorization: Bearer $TOKEN"
```

### Scenario 2: I want to use the KV store in my Terraform run

```
You:   "I need to store/retrieve config during Terraform execution"

You:   Create API Key in Terrateam UI
       ├─ Select "KV Store Read" capability
       ├─ Select "KV Store Write" capability
       └─ Save key: tt_live_xyz789...

Your Terraform Wrapper Script:

       #!/bin/bash

       # Get short-lived token
       ACCESS_TOKEN=$(curl -s -X POST \
         https://app.terrateam.io/api/v1/access-token/refresh \
         -H "Authorization: Bearer $TERRATEAM_API_KEY" \
         | jq -r '.access_token')

       # Store deployment metadata
       curl -X PUT \
         "https://app.terrateam.io/api/v1/github/kv/12345/key/deploy.timestamp" \
         -H "Authorization: Bearer $ACCESS_TOKEN" \
         -H "Content-Type: application/json" \
         -d '{"value": "2024-01-15T10:30:00Z"}'

       # Run terraform
       terraform apply -auto-approve

       # Store results
       curl -X PUT \
         "https://app.terrateam.io/api/v1/github/kv/12345/key/deploy.status" \
         -H "Authorization: Bearer $ACCESS_TOKEN" \
         -H "Content-Type: application/json" \
         -d '{"value": "success"}'
```

### Scenario 3: Long-running script that needs API access

```
You:   "My monitoring script runs for hours and calls the API periodically"

Your Script:

       import time
       import requests
       from datetime import datetime, timedelta

       class TerrateamClient:
           def __init__(self, api_key):
               self.api_key = api_key
               self.access_token = None
               self.token_expires_at = None

           def get_access_token(self):
               # Refresh if expired or about to expire
               if not self.access_token or datetime.now() >= self.token_expires_at:
                   response = requests.post(
                       'https://app.terrateam.io/api/v1/access-token/refresh',
                       headers={'Authorization': f'Bearer {self.api_key}'}
                   )
                   data = response.json()
                   self.access_token = data['access_token']
                   # Refresh 10 seconds before expiration
                   self.token_expires_at = datetime.now() + timedelta(seconds=50)

               return self.access_token

           def list_work_manifests(self, installation_id):
               token = self.get_access_token()  # Auto-refreshes if needed
               response = requests.get(
                   f'https://app.terrateam.io/api/v1/github/installations/{installation_id}/work-manifests',
                   headers={'Authorization': f'Bearer {token}'}
               )
               return response.json()

       # Usage
       client = TerrateamClient(api_key=os.environ['TERRATEAM_API_KEY'])

       while True:
           manifests = client.list_work_manifests(12345)
           print(f"Found {len(manifests['work_manifests'])} manifests")
           time.sleep(300)  # Check every 5 minutes
           # Token auto-refreshes when needed!
```

## Quick Reference

### To call the Terrateam API, you need:

1. ✅ **Terrateam API Key** (created in Terrateam UI)
2. ✅ **Terrateam Access Token** (exchanged from API key)

### You do NOT need:

1. ❌ GitHub App Installation Token (Terrateam manages this internally)
2. ❌ GitHub Personal Access Token (PAT)
3. ❌ GitHub OAuth App Token

### Authentication flow summary:

```
Your API Key  →  Exchange  →  Access Token  →  API Call  →  Data
(long-lived)     (60s TTL)     (short-lived)    (authorized)   (success!)
```

## Still Confused?

Think of it this way:

- **GitHub App** = Terrateam's "employee badge" to access GitHub on your behalf
- **Terrateam API Key** = Your "employee badge" to access Terrateam's systems

Just like you wouldn't use Terrateam's badge to access GitHub, you wouldn't use GitHub's badge to access Terrateam!

## Next Steps

- [Create your first API key](/reference/api/access-tokens)
- [Try the authentication flow](/reference/api/authentication)
- [Explore API endpoints](/reference/api/)
- [Read the full architecture guide](/reference/api-architecture)
