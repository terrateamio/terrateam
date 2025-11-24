---
title: API Architecture
description: Overview of Terrateam's API architecture and how it works
---

# API Architecture

This document provides a high-level overview of Terrateam's API architecture, covering the key components, authentication flows, and integration patterns.

## Overview

Terrateam's API is a RESTful HTTP API that enables programmatic access to Terrateam's infrastructure automation platform. The API supports:

- Managing Terraform/OpenTofu workflows
- Accessing work manifests and execution outputs
- Managing API keys and authentication
- Integrating with GitHub and GitLab
- Key-value storage for custom workflows
- Stack configuration and dependency management

The API is currently in **beta** and is subject to change.

## Technology Stack

Terrateam's API is built on a custom, type-safe foundation:

- **Language**: OCaml - Provides compile-time safety and functional programming patterns
- **HTTP Framework**: Custom async HTTP server (Brtl) with type-safe routing
- **Database**: PostgreSQL with connection pooling and type-safe SQL queries
- **Authentication**: JWT-based tokens with capability-based authorization
- **API Design**: Schema-driven development using OpenAPI specifications

## Architecture Pattern

### Service-Oriented Design

Terrateam uses a **modular service-oriented architecture** with a VCS (Version Control System) abstraction layer:

```
┌─────────────────────────────────────────┐
│         HTTP API Layer (Brtl)           │
│  Authentication • Routing • Middleware  │
└────────────┬────────────────────────────┘
             │
       ┌─────┴─────┐
       │           │
┌──────▼─────┐ ┌──▼───────────┐
│  GitHub    │ │   GitLab     │
│  Service   │ │   Service    │
└──────┬─────┘ └──┬───────────┘
       │           │
       └─────┬─────┘
             │
    ┌────────▼────────┐
    │  VCS Abstraction│
    │     Interface   │
    └────────┬────────┘
             │
    ┌────────▼────────┐
    │   Core Engine   │
    │ • Workflow Eval │
    │ • Work Manifests│
    │ • KV Store      │
    │ • Storage Layer │
    └─────────────────┘
```

### Dual URL Structure

The API uses two URL patterns to serve different use cases:

- **`/api/v1/{vcs}/...`** - General API and UI calls
- **`/api/{vcs}/v1/...`** - Pipeline and action-specific calls

This allows independent versioning for different API consumers.

## Key Components

### Authentication & Authorization

**Session Management**
- Handles JWT token validation and cookie-based sessions
- Extracts user identity and capabilities from tokens
- Injects authenticated user context into requests

**Capability System**
- Fine-grained permission model
- Capabilities include: `Access_token_create`, `Kv_store_read`, `Kv_store_write`, `Installation_id`
- Each API key can have specific capability sets
- Capabilities are embedded in JWT tokens

### VCS Services

**GitHub Service**
- GitHub App integration with OAuth
- Webhook event processing
- Installation and repository management
- Pull request and work manifest handling

**GitLab Service**
- OAuth2 authentication
- Pipeline and merge request events
- Group membership and access control
- Similar API surface to GitHub service

### Core Engine

**Work Manifest System**
- Immutable execution context for Terraform/OpenTofu operations
- Contains all parameters, configurations, and state for a workflow run
- Supports resume, retry, and audit trail
- Stores plan outputs and execution results

**KV Store**
- Key-value storage built on PostgreSQL
- Namespace isolation per installation
- Transactional operations with compare-and-swap
- Capability-based read/write access control

**Event Evaluator**
- Processes VCS events (push, PR, comments)
- Executes workflow logic based on event type
- Manages Terraform operation state transitions
- Coordinates with VCS provider for status updates

## API Organization

### Endpoint Categories

The API is organized into logical feature areas:

#### Authentication APIs
- Token refresh and exchange
- User identity verification
- Session management

#### Access Token Management
- Create, list, and delete API keys
- Configure key capabilities
- Manage long-lived credentials

#### Installation APIs
- List repositories and pull requests
- Manage dirspaces (directory-workspace pairs)
- Access work manifests and outputs
- Trigger repository refreshes

#### Work Manifest APIs
- Submit Terraform execution results
- Initialize and manage workflows
- Store and retrieve plan data
- List workspace configurations

#### KV Store APIs
- Get, set, and delete key-value pairs
- Atomic compare-and-swap operations
- Key iteration and counting
- Transactional commits

#### Stack APIs
- Retrieve stack configurations
- Access dependency graphs
- Query stack state for pull requests

#### System & Admin APIs
- Server configuration
- Health checks
- Prometheus metrics
- Administrative functions

## Authentication Flow

Terrateam uses a **two-step authentication process** for maximum security:

### Step 1: Create API Key (Long-lived)

Users create API keys through the UI:

1. Navigate to Settings → API Access
2. Select desired capabilities
3. Generate API key (long-lived credential)

The API key is stored securely and has the built-in capability `Access_token_refresh`.

### Step 2: Exchange for Access Token (Short-lived)

Before making API calls, exchange the API key for a short-lived access token:

```bash
POST /api/v1/access-token/refresh
Authorization: Bearer <API_KEY>
```

**Response:**
```json
{
  "access_token": "eyJhbGc...",
  "expires_in": 60
}
```

The access token is a JWT that:
- Expires after **60 seconds**
- Inherits capabilities from the API key
- Must be refreshed frequently

### Step 3: Use Access Token

Include the access token in API requests:

```bash
GET /api/v1/github/installations/123/repos
Authorization: Bearer <ACCESS_TOKEN>
```

### Authentication Flow Diagram

```
┌─────────┐                                ┌─────────────┐
│  Client │                                │  Terrateam  │
└────┬────┘                                └──────┬──────┘
     │                                            │
     │  POST /api/v1/access-token/refresh        │
     │  Authorization: Bearer <API_KEY>          │
     ├──────────────────────────────────────────►│
     │                                            │
     │  Validate API key, check capabilities     │
     │                                            │
     │  { "access_token": "...", "expires": 60 } │
     │◄──────────────────────────────────────────┤
     │                                            │
     │  GET /api/v1/.../repos                    │
     │  Authorization: Bearer <ACCESS_TOKEN>     │
     ├──────────────────────────────────────────►│
     │                                            │
     │  Validate JWT, verify capabilities        │
     │                                            │
     │  { "repos": [...] }                       │
     │◄──────────────────────────────────────────┤
     │                                            │
```

### Why Short-Lived Tokens?

The 60-second token expiration provides enhanced security:
- Limits exposure if a token is intercepted
- Forces regular refresh, allowing capability changes to propagate quickly
- Reduces risk of token replay attacks

## Request/Response Flow

### Complete Request Pipeline

```
1. TCP Connection
   └─► HTTP Request arrives

2. Middleware Pipeline
   ├─► Logging Middleware (captures request details)
   └─► Session Middleware
       ├─► Extract Bearer token or Cookie
       ├─► Validate JWT/session
       ├─► Create user object with capabilities
       └─► Inject into request context

3. Routing
   ├─► Pattern match URL
   └─► Select handler from VCS service routes

4. Request Validation
   ├─► Parse JSON body
   ├─► Validate against schema
   └─► Type-safe conversion

5. Handler Execution
   ├─► Check user capabilities
   ├─► Execute business logic
   └─► Query database

6. Response
   ├─► Serialize to JSON
   ├─► Log response
   └─► Send to client
```

### Example Request Flow

**Request:**
```bash
GET /api/v1/github/installations/12345/repos?limit=10
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

**Flow:**
1. Request arrives at Brtl HTTP server
2. Logging middleware captures request ID and remote IP
3. Session middleware validates JWT token
4. Router matches `/api/v1/github/installations/{id}/repos`
5. Handler checks for `Installation_id` capability
6. Database query fetches repositories for installation 12345
7. Results serialized to JSON
8. Response returned with pagination metadata

**Response:**
```json
{
  "repos": [
    {
      "id": "repo-uuid-1",
      "name": "terraform-infrastructure",
      "owner": "myorg",
      "default_branch": "main"
    }
  ],
  "next_page": ["cursor-token"]
}
```

## VCS Integration

### GitHub Integration

**Authentication:**
- GitHub App with OAuth flow
- Callback: `GET /api/v1/github/callback`
- Webhook events: `POST /api/github/v1/events`

**Key Features:**
- Organization and repository access
- Pull request event processing
- Check run status updates
- Installation lifecycle management

**Example: List Pull Requests**
```bash
GET /api/v1/github/installations/12345/pull-requests?limit=20
Authorization: Bearer <ACCESS_TOKEN>
```

**Response:**
```json
{
  "pull_requests": [
    {
      "id": "pr-uuid",
      "number": 42,
      "title": "Add new feature",
      "base_branch": "main",
      "head_branch": "feature/new-feature",
      "state": "open",
      "repo_id": "repo-uuid"
    }
  ]
}
```

### GitLab Integration

**Authentication:**
- OAuth2 flow
- Callback: `GET /api/v1/gitlab/callback`
- Webhook events: `POST /api/v1/gitlab/events`

**Key Features:**
- Group and project access
- Merge request processing
- Pipeline event handling
- Access token management per installation

**Example: Check Group Membership**
```bash
GET /api/v1/gitlab/groups/456/is-member
Authorization: Bearer <ACCESS_TOKEN>
```

**Response:**
```json
{
  "is_member": true
}
```

### VCS Abstraction

Both GitHub and GitLab services implement a common VCS provider interface, allowing Terrateam to:
- Write VCS-agnostic business logic
- Support multiple VCS platforms with shared code
- Easily add new VCS providers in the future

## API Versioning

### Current Version: v1

- **Status**: Beta - subject to change
- **URL Pattern**: `/api/v1/...` or `/api/{vcs}/v1/...`
- **Stability**: Not guaranteed until GA release

### Conventions

**URL Structure:**
- Resource-based paths: `/installations/{id}/repos`
- VCS parameter accepts `github` or `gitlab`
- Nested resources show relationships

**Pagination:**
- Cursor-based using `page` parameter
- `limit` parameter (default: 20, max: 100)
- Results include `next_page` cursor in response

**Query Parameters:**
- `q` - Tag query for filtering (e.g., `tag:production AND team:platform`)
- `d` - Sort direction (`asc` or `desc`)
- `tz` - Timezone for date filtering

**Data Formats:**
- Content-Type: `application/json`
- Timestamps: ISO 8601 format (UTC)
- IDs: UUIDs or VCS-specific identifiers

## Security Features

### Multi-Layer Security

**1. Authentication**
- Two-factor approach: API key + short-lived access token
- JWT signature verification with key rotation
- Token expiration enforcement (60 seconds)

**2. Authorization**
- Capability-based access control
- Per-installation access verification
- User must be member of GitHub org/GitLab group
- Per-endpoint capability checks

**3. Input Validation**
- Type-safe parameter binding prevents SQL injection
- JSON schema validation for all request bodies
- URL parameter validation via routing layer

**4. VCS Access Control**
- Installation-level isolation
- Repository access limited by VCS permissions
- Webhook signature verification

### Example Capability Check

When calling a protected endpoint:

```bash
GET /api/v1/github/installations/12345/repos
Authorization: Bearer <TOKEN>
```

The system:
1. Validates JWT signature
2. Extracts capabilities from token
3. Verifies user has `Installation_id` capability
4. Checks user is member of installation's organization
5. Proceeds with request or returns 403 Forbidden

## Scalability & Operations

### Stateless Design

- No server-side session state (all state in JWT or database)
- Horizontal scaling via load balancer
- Database connection pooling for efficiency

### Monitoring

**Health Checks:**
```bash
GET /health
```

Returns 200 OK if system is healthy.

**Metrics:**
```bash
GET /metrics
```

Prometheus-formatted metrics including:
- Request latencies
- Database query times
- Connection pool usage
- Background job execution times

**Logging:**
- Structured logging with request IDs
- Per-module log sources
- Remote IP tracking via `X-Forwarded-For`

### Background Jobs

The system runs periodic background tasks:
- **Drift Detection** - Runs hourly to detect infrastructure drift
- **Cleanup Tasks** - Removes stale data and temporary resources
- **Repository Refresh** - Updates repository configurations

## Working with Work Manifests

Work manifests are central to Terrateam's workflow execution:

### What is a Work Manifest?

A work manifest represents a **complete execution context** for a Terraform/OpenTofu operation. It contains:
- Target directories and workspaces
- Terraform version and configuration
- Environment variables and secrets
- Plan data and execution state
- Results and outputs

### Work Manifest Lifecycle

```
1. Initiate
   POST /api/{vcs}/v1/work-manifests/{id}/initiate
   └─► Create manifest from VCS event

2. Execute (external - GitHub Actions, GitLab CI)
   ├─► Download manifest configuration
   ├─► Run Terraform plan/apply
   └─► Collect outputs

3. Submit Results
   PUT /api/{vcs}/v1/work-manifests/{id}
   └─► Store execution results

4. Query
   GET /api/v1/{vcs}/installations/{id}/work-manifests
   └─► Retrieve manifests and outputs
```

### Example: Get Work Manifest Outputs

```bash
GET /api/v1/github/installations/12345/work-manifests/wm-uuid/outputs
Authorization: Bearer <ACCESS_TOKEN>
```

**Response:**
```json
{
  "outputs": [
    {
      "dir": "terraform/vpc",
      "workspace": "production",
      "plan": "Plan: 3 to add, 1 to change, 0 to destroy",
      "status": "completed"
    }
  ]
}
```

## KV Store Usage

The KV Store provides flexible key-value storage for custom workflows:

### Features

- **Namespaced** - Isolated per installation
- **Transactional** - ACID guarantees with commit
- **Atomic** - Compare-and-swap for concurrent updates
- **Capability-based** - Read/write access control per key

### Example: Store Configuration

```bash
PUT /api/v1/github/kv/12345/key/config.deployment
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: application/json

{
  "value": {
    "environment": "production",
    "replicas": 3
  }
}
```

### Example: Atomic Update

```bash
PUT /api/v1/github/kv/12345/cas/key/counter
Authorization: Bearer <ACCESS_TOKEN>
Content-Type: application/json

{
  "value": 43,
  "version": 42
}
```

Only succeeds if current version is 42, preventing race conditions.

### Example: Iterate Keys

```bash
GET /api/v1/github/kv/12345/iter/config.
Authorization: Bearer <ACCESS_TOKEN>
```

Returns all keys with prefix `config.`:
```json
{
  "keys": [
    "config.deployment",
    "config.database",
    "config.monitoring"
  ]
}
```

## Best Practices

### API Key Management

- **Create separate keys** for different applications
- **Use minimal capabilities** - only grant what's needed
- **Rotate keys regularly** - especially for production use
- **Never commit keys** to version control
- **Revoke unused keys** immediately

### Token Refresh

- **Implement automatic refresh** - tokens expire in 60 seconds
- **Handle 401 responses** - refresh token and retry
- **Cache tokens briefly** - avoid unnecessary refresh calls
- **Fail gracefully** - handle refresh failures with backoff

### Pagination

- **Use the `limit` parameter** - don't fetch more than needed
- **Follow `next_page` cursors** - for complete result sets
- **Handle empty results** - end of pagination returns empty array

### Error Handling

Expected HTTP status codes:
- `200 OK` - Success
- `400 Bad Request` - Invalid input
- `401 Unauthorized` - Missing or invalid token
- `403 Forbidden` - Insufficient capabilities
- `404 Not Found` - Resource doesn't exist
- `429 Too Many Requests` - Rate limit exceeded
- `500 Internal Server Error` - Server error

## Additional Resources

- [API Reference](/reference/api/) - Detailed endpoint documentation
- [Authentication Guide](/reference/api/authentication) - Auth setup and examples
- [Access Tokens](/reference/api/access-tokens) - Managing API keys
- [Work Manifests](/reference/api/work-manifests) - Workflow execution
- [KV Store](/reference/api/kv-store) - Key-value storage guide

## Support

For questions or issues with the API:
- Report bugs at [GitHub Issues](https://github.com/terrateamio/terrateam/issues)
- Check the documentation at [docs.terrateam.io](https://docs.terrateam.io)
