# Terrateam Iris - Comprehensive Project Analysis

## Project Overview

**Iris** is a modern web-based user interface for Terrateam, a Terraform automation platform. It represents a complete rewrite from OCaml/JavaScript to a modern Svelte-based SPA, providing users with an intuitive way to manage Terraform infrastructure operations, GitHub integrations, and workspace management.

## Architecture

### Frontend Stack
- **Framework**: Svelte 4 with SPA routing
- **Styling**: Tailwind CSS with custom design system
- **Build Tool**: Vite 5 with hot module replacement
- **Icons**: Iconify for scalable icon system
- **State Management**: Reactive Svelte stores
- **Development**: Nginx proxy with SSL for production-like development

### Backend Integration
- **API**: REST-based JSON API with comprehensive endpoints
- **Authentication**: GitHub OAuth flow
- **Proxy Setup**: Development nginx configuration routes `/api/*` to production backend
- **Real-time**: Future WebSocket integration potential for live updates

## Core Features & Components

### 1. Authentication & User Management
- **GitHub OAuth Integration**: Seamless login with GitHub accounts
- **Session Management**: Persistent login state with automatic redirect
- **Multi-Installation Support**: Switch between different GitHub organization installations

### 2. Dashboard & Navigation
- **Fixed Sidebar Navigation**: Persistent sidebar with user avatar and installation selector
- **Responsive Theme System**: Automatic dark/light mode with system preference detection
- **Brand-Compliant Design**: Custom color system following Terrateam brand guidelines

### 3. Repository Management
- **Repository Discovery**: List and manage connected GitHub repositories
- **Setup Workflows**: Guide users through repository configuration
- **Sync Operations**: Refresh repository lists and maintain up-to-date integrations

### 4. Infrastructure Operations (Work Manifests)
- **Run Management**: View and manage Terraform plan/apply operations
- **Advanced Search**: Tag Query Language for filtering operations by various criteria
- **Real-time Status**: Track running, completed, failed, and queued operations
- **Detailed Views**: Drill down into specific operation outputs and logs

### 4.1. Run Search System (Tag Query Language Implementation)
- **Query-Based Architecture**: Uses server-side Tag Query Language instead of client-side pagination
- **Repository Scoping**: Automatic `repo:` filtering scoped to current repository context
- **Clean User Interface**: Search input shows only user filters, repo scoping handled transparently
- **Quick Filter Buttons**: One-click access to common searches (Success, Failed, Running, Plans, Applies)
- **URL Persistence**: Search queries preserved in URL parameters for bookmarking and sharing
- **Real-time Results**: Server-side filtering with 50-item limit for optimal performance

### 5. Cloud Provider Integration
- **Multi-Cloud Support**: AWS, GCP, Azure, Kubernetes, Heroku, Cloudflare
- **Provider Documentation**: Direct links to setup guides and documentation
- **Visual Provider Selection**: Icon-based interface for connecting cloud accounts

### 6. Billing & Subscription Management
- **Tier Management**: Display current subscription tier and usage limits
- **Trial Tracking**: Monitor trial periods and feature availability
- **Usage Metrics**: Potential for detailed usage tracking and reporting

### 7. Support & Documentation
- **In-App Resources**: Direct access to documentation and support channels
- **Community Integration**: Slack community access
- **Help System**: Contextual help and guidance

## API Integration

### Core API Endpoints
```
Authentication:
- GET /whoami - Current user information
- GET /github/whoami - GitHub user details
- POST /logout - Session termination
- GET /github/client_id - OAuth configuration

Installations & Repositories:
- GET /user/github/installations - Available GitHub installations
- GET /installations/{id}/repos - Repository listings
- POST /installations/{id}/repos/refresh - Repository synchronization
- GET /installations/{id}/pull-requests - Pull request listings

Work Manifests (Core Operations):
- GET /installations/{id}/work-manifests - List all operations
- POST /work-manifests/{id}/initiate - Start new operations
- PUT /work-manifests/{id} - Submit operation results
- GET /work-manifests/{id}/outputs - Retrieve operation logs and outputs
- GET /work-manifests/{id}/plans - Terraform plan files
- POST /work-manifests/{id}/plans - Upload plan files

Advanced Features:
- GET /installations/{id}/dirspaces - Directory/workspace combinations
- GET /admin/drifts - Drift detection management
- GET /tasks/{id} - Long-running task status
```

### Data Models

**Work Manifest**: Central abstraction representing Terraform operations
- Tracks plan/apply/index/drift operations
- Links to GitHub pull requests or scheduled operations
- Contains execution metadata, state, and results

**Dirspace**: Terraform directory + workspace combination
- Represents the unit of Terraform execution
- Tracks status across different environments
- Enables workspace-specific operations

**Installation**: GitHub App installation entity
- Manages organization-level permissions
- Controls repository access and billing
- Enables multi-tenant operation

## Tag Query Language Integration

### Overview
The run search system uses Terrateam's Tag Query Language for server-side filtering, providing users with powerful search capabilities while maintaining optimal performance.

### Architecture Pattern
- **Frontend**: Clean search interface with automatic repository scoping
- **Backend**: Server-side query processing via `q` parameter on dirspaces endpoint
- **Performance**: 50-item limit with real-time server-side filtering

### Query Structure
```typescript
// Frontend implementation
async function loadRuns(): Promise<void> {
  // Build query: always include repo filter, add user search if provided
  let query = `repo:${repository.name}`;
  if (searchQuery.trim()) {
    query = `${query} and ${searchQuery.trim()}`;
  }
  
  const params = { 
    tz: Intl.DateTimeFormat().resolvedOptions().timeZone,
    q: query,
    limit: 50
  };
  
  const response = await api.getInstallationDirspaces(installationId, params);
}
```

### Supported Query Operators
- **States**: `state:success`, `state:failure`, `state:running`, `state:aborted`, `state:queued`
- **Users**: `user:username` - Filter by GitHub username
- **Types**: `type:plan`, `type:apply` - Filter by operation type
- **Branches**: `branch:branch-name` - Filter by Git branch
- **Directories**: `dir:path/to/dir` - Filter by Terraform directory
- **Pull Requests**: `pr:123` - Filter by pull request number
- **Workspaces**: `workspace:default`, `workspace:staging` - Filter by Terraform workspace
- **Environments**: `environment:production`, `environment:` (empty) - Filter by environment
- **Kind**: `kind:pr`, `kind:drift` - Filter by operation kind
- **Date Ranges**: `created_at:2024-01-01..`, `"created_at:2024-01-01 12:00..2024-01-25 19:00"`
- **Sorting**: `sort:asc`, `sort:desc` - Sort by creation date

### Query Examples
```
# Basic filtering
state:success
user:josh and state:failure
type:apply and branch:main

# Date-based queries
created_at:2024-01-01..
"created_at:2024-01-01 12:00..2024-01-25 19:00"

# Complex combinations
state:success and user:josh and dir:staging/compute
pr:123 and type:plan
branch:main and type:apply and state:success

# Environment and workspace filtering
environment:production and state:success
workspace:staging and type:apply
```

### URL Integration
Queries are automatically persisted in URL parameters for bookmarking and sharing:
```
#/repositories/infrastructure?q=state:success%20and%20user:josh
```

### User Interface Components

#### Search Input
- **Clean Interface**: Shows only user-added filters
- **Repository Scoping**: `repo:` filter added automatically in backend
- **Placeholder**: "e.g., state:success and user:josh"
- **Enter Key**: Triggers search on Enter keypress

#### Quick Filter Buttons
- **✅ Success**: `state:success`
- **❌ Failed**: `state:failure` 
- **🔄 Running**: `state:running`
- **📋 Plans**: `type:plan`
- **🚀 Applies**: `type:apply`
- **Behavior**: Replace current search (clear first, then apply filter)

#### Results Display
- **Full Query Visibility**: Shows complete query including `repo:` scope
- **Example**: "Found 12 runs matching: `repo:infrastructure and state:success and user:josh`"
- **Context**: Users see exactly what query was executed

#### Advanced Search Help
- **Expandable Examples**: Show complex query patterns
- **Context-Aware**: Examples scoped to current repository
- **Copy-Paste Ready**: Examples can be copied directly into search input

### Implementation Guidelines

#### Component Architecture
```typescript
// State management
let searchQuery: string = ''; // User input only, no repo filter
let isLoadingWorkManifests: boolean = false;
let totalCount: number = 0;

// Query building (backend)
const query = `repo:${repository.name} and ${userQuery}`;

// URL persistence
function updateURLWithQuery(query: string): void {
  const url = new URL(window.location.href);
  if (query) {
    url.searchParams.set('q', query);
  } else {
    url.searchParams.delete('q');
  }
  window.history.replaceState({}, '', url.toString());
}
```

#### Best Practices
1. **Repository Scoping**: Always automatically include `repo:` filter
2. **Clean Interface**: Never show `repo:` filter in user-facing search input
3. **URL Sync**: Keep search state synchronized with URL parameters
4. **Quick Filters**: Replace (don't append) existing search when clicked
5. **Clear Button**: Reset to empty search (repo scoping still applied)
6. **Full Query Display**: Show complete executed query in results summary

### Performance Considerations
- **Server-Side Filtering**: All filtering happens on the server via Tag Query Language
- **Optimal Limits**: 50-item response limit balances data access with performance
- **Real-Time**: No caching, always fresh results from API
- **Timezone Awareness**: Include user timezone in all queries

## Development Insights from OCaml Legacy

### Legacy Architecture Analysis
The previous OCaml implementation revealed several architectural patterns:

1. **Modular Component System**: Highly modular design with separate components for each major feature
2. **Type-Safe API Integration**: Strong typing for all API interactions and data models
3. **Functional Reactive Patterns**: Event-driven UI updates with immutable state management
4. **Comprehensive Search**: Advanced Tag Query Language for filtering operations
5. **Real-time Updates**: Polling-based status updates for long-running operations

### Migration Benefits
- **Performance**: Faster load times and smoother interactions
- **Maintainability**: More accessible codebase for frontend developers
- **Modern UX**: Contemporary design patterns and mobile responsiveness
- **Developer Experience**: Hot reload, better debugging, and standard tooling

## Design System

### Color Palette
```css
:root {
  --brand-primary: #009bff;    /* Primary blue */
  --brand-secondary: #12223f;  /* Dark blue */
  --accent-color: #e7f67e;     /* Lime green */
}
```

### Theme Implementation
- **System Detection**: Automatic dark/light mode based on user preference
- **Manual Override**: User-controlled theme selection in settings
- **CSS Custom Properties**: Maintainable theming system
- **Component Consistency**: All components support both themes

### Typography & Spacing
- **Font**: Apertura custom font family
- **Responsive Design**: Mobile-first approach with Tailwind breakpoints
- **Consistent Spacing**: Tailwind utility classes for uniform spacing

## Development Environment

### Local Development Setup
```bash
# Start development with nginx proxy and SSL
./scripts/dev-setup.sh

# Standard development (Vite only)
npm run dev

# Build for production
npm run build
```

### Proxy Configuration
- **SSL Termination**: Self-signed certificates for local HTTPS
- **API Proxying**: Routes `/api/*` to production backend
- **OAuth Integration**: Handles GitHub OAuth callback routing
- **WebSocket Support**: HMR and future real-time features

---

# 🚀 DEVELOPMENT GUIDELINES & BEST PRACTICES

> **This section serves as the rules engine for maintaining code quality, type safety, and architectural consistency. All AI assistants and developers MUST follow these guidelines.**

## 📋 Quick Navigation
- [TypeScript & Type Safety Rules](#typescript--type-safety-rules)
- [Component Development Standards](#component-development-standards)
- [Accessibility (A11y) Requirements](#accessibility-a11y-requirements)
- [API Integration Requirements](#api-integration-requirements)
- [Code Organization Rules](#code-organization-rules)
- [Automated Quality Checks](#automated-quality-checks)
- [Development Workflow](#development-workflow)

---

## 🔒 TypeScript & Type Safety Rules

### **MANDATORY REQUIREMENTS**

#### **✅ MUST DO:**
```typescript
// ✅ Use TypeScript for ALL new files
<script lang="ts">

// ✅ Import types from validated sources
import type { Installation, Repository } from './types';

// ✅ Use validated API client for type safety
import { api, validateInstallation } from './api';

// ✅ Define interfaces for component props
interface $$Props {
  activeItem: string;
  title: string;
  subtitle?: string;
}

// ✅ Type all function parameters and returns
function handleClick(event: MouseEvent): void {
  // implementation
}

// ✅ Use runtime validation for external data
const installation = validateInstallation(externalData);
```

#### **❌ NEVER DO:**
```typescript
// ❌ Never use JavaScript for new files
<script>

// ❌ Never use 'any' type
let data: any;

// ❌ Never skip runtime validation for API responses
const data = await fetch('/api/endpoint').then(r => r.json()); // Unvalidated!

// ❌ Never use old API client without validation
import { api } from './api'; // Use api instead

// ❌ Never create untyped component props
export let someData; // Missing type!
```

### **API Schema Synchronization Process**
- **Source of Truth**: `api.json` OpenAPI specification
- **Generated Types**: `src/lib/api-types-generated.ts` (auto-generated, DO NOT edit)
- **Manual Types**: `src/lib/types.ts` (hand-crafted with Zod validation)
- **API Client**: `src/lib/api.ts` (type-safe with runtime validation)

**When api.json changes:**
1. Run `npx openapi-typescript api.json --output src/lib/api-types-generated.ts`
2. Update `src/lib/types.ts` to match new schemas
3. Update `src/lib/api.ts` methods if needed
4. Run `npx tsc --noEmit` to verify compilation
5. Update components using changed types

---

## 🧩 Component Development Standards

### **File Structure (MANDATORY)**
```
src/lib/
├── components/           # Reusable components
│   ├── ui/              # UI primitives (Button, Card, etc.)
│   ├── layout/          # Layout components (PageLayout, etc.)
│   ├── forms/           # Form components
│   └── index.ts         # Barrel exports
├── pages/               # Page-level components
├── hooks/               # Reusable logic hooks
└── utils/               # Utility functions
```

### **Component Usage Rules**

#### **Page Components MUST Use PageLayout**
```svelte
<!-- ✅ ALWAYS use PageLayout for pages -->
<script lang="ts">
  import PageLayout from '../components/layout/PageLayout.svelte';
  import { Button, Card, LoadingSpinner } from '../components';
</script>

<PageLayout activeItem="page-name" title="Page Title" subtitle="Optional subtitle">
  <!-- Page content here -->
</PageLayout>
```

#### **UI Components Usage**
```svelte
<!-- ✅ Use existing UI components -->
<Button variant="accent" size="lg" on:click={handler}>Action</Button>
<Card padding="md" hover>Content</Card>
<LoadingSpinner size="md" />
<ErrorMessage type="error" message="Something went wrong" />
<EmptyState icon="repo" title="No repositories" description="Add a repository to get started" />
```

#### **Before Creating New Components**
**CHECKLIST:**
1. ✅ Does a similar component already exist in `src/lib/components/`?
2. ✅ Can existing components be extended or composed?
3. ✅ Will this component be reused in 2+ places?
4. ✅ Does it follow the established design patterns?

---

## ♿ Accessibility (A11y) Requirements

### **MANDATORY ACCESSIBILITY STANDARDS**

> **All components and pages MUST be accessible to users with disabilities. This is both a legal requirement and a moral imperative.**

#### **✅ MUST DO - Keyboard Navigation:**
```svelte
<!-- ✅ Always use semantic HTML elements -->
<button on:click={handleClick}>Action</button>  <!-- Not <div> -->
<a href="#section">Link</a>                     <!-- Not <span> -->

<!-- ✅ Use ClickableCard for accessible clickable areas -->
<script lang="ts">
  import ClickableCard from './components/ui/ClickableCard.svelte';
</script>

<ClickableCard 
  on:click={handleClick}
  aria-label="Descriptive action label"
>
  Content here
</ClickableCard>

<!-- ✅ Always provide proper ARIA labels -->
<button aria-label="Close dialog" on:click={close}>×</button>
<input aria-describedby="help-text" />
<div id="help-text">Helper text</div>

<!-- ✅ Ensure logical tab order -->
<div>
  <button tabindex="0">First</button>
  <button tabindex="0">Second</button>
  <button tabindex="0">Third</button>
</div>
```

#### **❌ NEVER DO:**
```svelte
<!-- ❌ Never use clickable divs without proper accessibility -->
<div on:click={handleClick}>Clickable</div>  <!-- Missing keyboard support! -->

<!-- ❌ Never use tabindex values other than 0 or -1 -->
<div tabindex="1">Bad</div>  <!-- Breaks tab order! -->

<!-- ❌ Never omit alt text for images -->
<img src="logo.png" />  <!-- Missing alt attribute! -->

<!-- ❌ Never use only color to convey information -->
<span style="color: red;">Error</span>  <!-- Add text or icon! -->
```

#### **✅ REQUIRED - Screen Reader Support:**
```svelte
<!-- ✅ Use semantic headings hierarchy -->
<h1>Page Title</h1>
  <h2>Section Title</h2>
    <h3>Subsection Title</h3>

<!-- ✅ Use ARIA landmarks -->
<main>
  <section aria-labelledby="repos-heading">
    <h2 id="repos-heading">Repositories</h2>
    <!-- content -->
  </section>
</main>

<!-- ✅ Announce dynamic content changes -->
<div aria-live="polite" aria-atomic="true">
  {#if loading}Loading repositories...{/if}
  {#if error}Error: {error}{/if}
</div>

<!-- ✅ Use proper form labels -->
<label for="repo-name">Repository Name</label>
<input id="repo-name" type="text" required />
```

#### **✅ REQUIRED - Color & Contrast:**
```css
/* ✅ Maintain 4.5:1 contrast ratio for normal text */
.text-primary { color: #1a1a1a; }  /* Against white background */
.text-secondary { color: #4a4a4a; }

/* ✅ Maintain 3:1 contrast ratio for large text */
.text-large { 
  font-size: 18px; 
  color: #666666; 
}

/* ✅ Use focus indicators */
button:focus {
  outline: 2px solid #009bff;
  outline-offset: 2px;
}
```

#### **✅ REQUIRED - Interactive Elements:**
```svelte
<!-- ✅ Use ClickableCard for complex clickable areas -->
<ClickableCard 
  on:click={() => navigateToRepo(repo)}
  aria-label="View {repo.name} repository details"
>
  <div class="repo-card-content">
    <h3>{repo.name}</h3>
    <p>{repo.description}</p>
  </div>
</ClickableCard>

<!-- ✅ Provide clear button labels -->
<Button 
  variant="primary" 
  aria-label="Connect to {provider.name}"
  on:click={() => connectProvider(provider)}
>
  Connect {provider.shortName}
</Button>

<!-- ✅ Use proper loading states -->
<Button loading={isConnecting} disabled={isConnecting}>
  {#if isConnecting}
    Connecting...
  {:else}
    Connect AWS
  {/if}
</Button>
```

### **ACCESSIBILITY COMPONENT REQUIREMENTS**

#### **ClickableCard Component Usage**
```svelte
<!-- ✅ Required for all clickable card-like elements -->
<script lang="ts">
  import ClickableCard from './components/ui/ClickableCard.svelte';
</script>

<!-- ✅ Always provide meaningful aria-label -->
<ClickableCard 
  padding="md"
  hover={true}
  on:click={handleAction}
  aria-label="Setup {provider.name} integration"
>
  <!-- Card content -->
</ClickableCard>

<!-- ✅ Use for repository listings -->
<ClickableCard 
  padding="none"
  border={false}
  shadow={false}
  on:click={() => openRepo(repo)}
  aria-label="View repository {repo.name}"
  class="custom-styles"
>
  <!-- Repository content -->
</ClickableCard>
```

#### **Button Component Standards**
```svelte
<!-- ✅ Use Button component for all interactive buttons -->
<Button 
  variant="accent" 
  size="lg"
  loading={isSubmitting}
  disabled={!isValid}
  aria-describedby="submit-help"
  on:click={handleSubmit}
>
  Submit Form
</Button>
<div id="submit-help">This will save your changes</div>
```

### **TESTING ACCESSIBILITY**

#### **Automated Testing (Required)**
```bash
# Run accessibility linting
npm run lint:a11y

# Check with validation scripts
npm run check-component-standards
```

#### **Manual Testing Checklist**
**REQUIRED before marking work complete:**

1. **✅ Keyboard Navigation Test:**
   - Tab through entire page
   - All interactive elements reachable
   - No keyboard traps
   - Logical tab order

2. **✅ Screen Reader Test:**
   - Test with screen reader (NVDA, JAWS, VoiceOver)
   - All content announced correctly
   - Heading structure makes sense
   - Form labels are clear

3. **✅ Color/Contrast Test:**
   - Check contrast ratios with tools
   - Test with color blindness simulation
   - Ensure information isn't color-only

4. **✅ Focus Management:**
   - Focus indicators visible
   - Focus moves logically
   - Modal/dialog focus handling

### **ACCESSIBILITY VALIDATION SCRIPTS**

The project includes automated accessibility checking:
- `npm run check-component-standards` - Validates component accessibility patterns
- Pre-commit hooks enforce accessibility standards
- CI/CD pipeline blocks accessibility violations

---

## 🌐 API Integration Requirements

### **MANDATORY API Patterns**

#### **✅ Type-Safe API Calls**
```typescript
// ✅ Use validated API client
import { api, isApiError } from './api';

try {
  // Automatically validated against API schema
  const response = await api.getUserInstallations();
  // response.installations is guaranteed to be Installation[]
} catch (error) {
  if (isApiError(error)) {
    console.error('API Error:', error.message, error.status);
  }
}
```

#### **✅ API Hooks for State Management**
```typescript
// ✅ Use API hooks for loading/error states
import { useAutoApi } from './hooks';

const { data: installations, loading, error } = useAutoApi(
  () => api.getUserInstallations(),
  []
);
```

#### **❌ Forbidden Patterns**
```typescript
// ❌ Never use unvalidated API calls
const response = await fetch('/api/endpoint').then(r => r.json());

// ❌ Never skip error handling
const data = await api.getUserInstallations(); // No try/catch!

// ❌ Never use legacy API client for new code
import { api } from './api'; // Use api instead
```

---

## 📁 Code Organization Rules

### **Import Standards**
```typescript
// ✅ Organized imports
// 1. External libraries
import { writable } from 'svelte/store';
import { z } from 'zod';

// 2. Internal types
import type { Installation, Repository } from './types';

// 3. Components (use barrel exports)
import { PageLayout, Button, Card } from './components';

// 4. Hooks and utilities
import { useAuth } from './hooks';
import { api } from './api';
```

### **File Naming Conventions**
- **Components**: PascalCase (e.g., `PageLayout.svelte`, `UserProfile.svelte`)
- **Pages**: PascalCase (e.g., `Dashboard.svelte`, `Repositories.svelte`)
- **Hooks**: camelCase with `use` prefix (e.g., `useAuth.ts`, `useApi.ts`)
- **Utils**: camelCase (e.g., `formatDate.ts`, `apiHelpers.ts`)
- **Types**: camelCase with descriptive suffix (e.g., `types.ts`)

---

## 🤖 Automated Quality Checks

### **Required Checks Before Committing**
```bash
# 1. TypeScript compilation
npx tsc --noEmit

# 2. Svelte TypeScript validation (CRITICAL)
npm run check

# 3. API schema validation
npm run check-api-types

# 4. Unused code detection (CRITICAL)
npm run knip

# 5. Linting (if configured)
npm run lint
```

**Note**: `npm run knip` is configured to focus on critical issues (unused files and dependencies) while allowing intentional public API exports and types. The configuration is in `knip.json`.

### **Package.json Scripts (ADD THESE)**
```json
{
  "scripts": {
    "check": "svelte-check --tsconfig ./tsconfig.json",
    "type-check": "npx tsc --noEmit",
    "generate-api-types": "npx openapi-typescript api.json --output src/lib/api-types-generated.ts",
    "check-api-types": "node scripts/check-api-types.cjs",
    "pre-commit": "npm run type-check && npm run check-api-types && npm run knip"
  }
}
```

---

## 🚨 DEVELOPMENT GUARD RAILS

> **CRITICAL: Follow these rules to prevent validation failures and maintain code quality from day one.**

### **🔥 BEFORE STARTING ANY WORK**

#### **1. ALWAYS Run Full Validation First**
```bash
# Run ALL validations BEFORE making any changes
npm run check
npm run check-api-types
npm run knip
```
If ANY of these fail, **STOP** and fix the existing issues before proceeding with new work.

#### **2. MANDATORY Pre-Work Checklist**
- ✅ Read this entire CLAUDE.md file  
- ✅ Run `npm run check` and ensure it passes
- ✅ Run `npm run check-api-types` and ensure it passes
- ✅ Run `npm run knip` and ensure it passes
- ✅ Understand the existing component patterns
- ✅ Check if similar functionality already exists

### **🛡️ DURING DEVELOPMENT**

#### **NEVER Create These Anti-Patterns:**
```typescript
// ❌ FORBIDDEN - ANY TYPES
let data: any;
function handleResponse(response: any) { }
const items = response as any;

// ❌ FORBIDDEN - DIRECT SIDEBAR USAGE IN PAGES
import Sidebar from './Sidebar.svelte';
<div class="min-h-screen">
  <Sidebar activeItem="page" />
  <!-- page content -->
</div>

// ❌ FORBIDDEN - UNVALIDATED API RESPONSES  
const response = await fetch('/api/endpoint').then(r => r.json());

// ❌ FORBIDDEN - UNTYPED FUNCTION PARAMETERS
function process(item) { } // Missing types!
```

#### **ALWAYS Use These Patterns:**
```typescript
// ✅ REQUIRED - PROPER TYPESCRIPT
interface DataItem {
  id: string;
  name: string;
}
let data: DataItem[];
function handleResponse(response: DataItem[]): void { }

// ✅ REQUIRED - PAGELAYOUT FOR ALL PAGES
import PageLayout from './components/layout/PageLayout.svelte';
<PageLayout activeItem="page-name" title="Page Title">
  <!-- page content -->
</PageLayout>

// ✅ REQUIRED - VALIDATED API USAGE
import { validatedApi } from './api-validated';
const response = await validatedApi.getInstallations();

// ✅ REQUIRED - TYPED FUNCTIONS
function process(item: DataItem): void { }
```

### **📋 REAL-TIME VALIDATION WORKFLOW**

#### **Step 1: Before Writing Code**
```bash
# Ensure clean starting state
npm run check
npm run check-api-types
npm run knip
echo "✅ Starting with clean validation state"
```

#### **Step 2: During Code Changes**
```bash
# Check types frequently while developing
npx tsc --noEmit
# Or run full Svelte validation
npm run check
```

#### **Step 3: Before Completing Work**
```bash
# MANDATORY final validation - ALL must pass
npm run check
npm run check-api-types
npm run knip
```
**If ANY of these fail, your work is NOT complete.**

### **🎯 NEW COMPONENT CREATION CHECKLIST**

When creating any new `.svelte` file:

#### **For Page Components (top-level routes):**
```svelte
<!-- ✅ REQUIRED TEMPLATE -->
<script lang="ts">
  import PageLayout from './components/layout/PageLayout.svelte';
  import { isAuthenticated } from './auth';
  
  // Authentication check
  $: if (!$isAuthenticated) {
    window.location.hash = '#/login';
  }
  
  // Proper TypeScript interfaces
  interface MyData {
    id: string;
    // ... other properties
  }
</script>

<PageLayout activeItem="sidebar-item" title="Page Title" subtitle="Optional subtitle">
  <!-- Your page content here -->
</PageLayout>
```

#### **For Reusable Components:**
```svelte
<!-- ✅ REQUIRED TEMPLATE -->
<script lang="ts">
  // Define prop interface
  interface $$Props {
    title: string;
    optional?: boolean;
  }
  
  export let title: string;
  export let optional: boolean = false;
</script>

<!-- Component content with proper accessibility -->
<div role="..." aria-label="...">
  <!-- Content -->
</div>
```

### **🔧 API INTEGRATION CHECKLIST**

When making API calls:

```typescript
// ✅ STEP 1: Use validated API client
import { validatedApi, isApiError } from './api-validated';

// ✅ STEP 2: Proper error handling  
try {
  const response = await validatedApi.getInstallations();
  // response.installations is guaranteed to be Installation[]
} catch (error) {
  if (isApiError(error)) {
    console.error('API Error:', error.message, error.status);
  }
}

// ✅ STEP 3: Use hooks for state management
import { useAutoApi } from './hooks';
const { data: installations, loading, error } = useAutoApi(
  () => validatedApi.getUserInstallations(),
  []
);
```

### **⚡ INSTANT FEEDBACK LOOP**

Set up your development environment for instant feedback:

#### **VS Code Settings (Recommended)**
```json
{
  "typescript.preferences.noSemicolons": "off",
  "typescript.validate.enable": true,
  "typescript.preferences.includePackageJsonAutoImports": "auto",
  "editor.codeActionsOnSave": {
    "source.fixAll": true
  }
}
```

#### **Terminal Watcher (Optional)**
```bash
# Run in separate terminal for continuous validation
npx tsc --noEmit --watch

# Or for Svelte-specific validation
npm run check:watch
```

### **🚀 EMERGENCY FIXES**

If you encounter validation failures:

#### **TypeScript Compilation Errors:**
1. **DON'T** add `// @ts-ignore` comments
2. **DO** fix the underlying type issue
3. **DO** add proper interfaces and types

#### **Svelte-Check Errors:**
1. **DON'T** ignore Svelte-specific type errors
2. **DO** fix missing props, incorrect prop types
3. **DO** ensure all Svelte component types are correct
4. **DO** remove unused imports and variables

#### **Component Standard Violations:**
1. **DON'T** modify the validation script to ignore violations
2. **DO** convert components to use PageLayout
3. **DO** follow the established patterns

#### **API Usage Pattern Violations:**
1. **DON'T** use unvalidated API responses
2. **DO** use the validated API client
3. **DO** add proper error handling

### **📊 VALIDATION SCRIPT BREAKDOWN**

Understanding what our validation commands check:

#### **`npm run check` (svelte-check) validates:**
1. **Svelte Component Types**: All component props and exports are properly typed
2. **Template Type Safety**: Bindings and expressions are type-safe
3. **Import/Export Correctness**: All imports resolve and exports are valid
4. **Unused Variables**: Warns about unused imports, variables, and functions
5. **Component Interface Compliance**: Props match expected interfaces

#### **`npm run check-api-types` validates:**
1. **API Specification**: Ensures `api.json` exists and is valid
2. **Generated Types**: Verifies auto-generated types are up to date  
3. **Validated Types**: Confirms manual type definitions exist
4. **Validated API Client**: Ensures type-safe API client is available
5. **TypeScript Compilation**: Validates all TypeScript compiles without errors
6. **Component Standards**: Ensures pages use PageLayout component
7. **API Usage Patterns**: Prevents `any` types and unvalidated API usage

**ALL CHECKS FROM BOTH COMMANDS MUST PASS** for code to be considered complete.

### **🎓 LEARNING FROM PAST ISSUES**

The massive refactoring we just completed happened because:

1. **`any` types accumulated** - Now forbidden completely
2. **Direct Sidebar usage in pages** - Now required to use PageLayout  
3. **Unvalidated API responses** - Now required to use validated client
4. **Missing pre-commit validation** - Now mandatory before completing work
5. **Svelte-specific type errors ignored** - Now `npm run check` is mandatory
6. **Unused variables and imports** - Now flagged and must be cleaned up
7. **Missing or incorrect component props** - Now validated by svelte-check

**DON'T repeat these patterns!**

### **🚨 CURRENT STATE ALERT**

> **CRITICAL WARNING: As of the latest check, `npm run check` is failing with 108 errors!**

**This means the codebase currently has significant Svelte-specific type issues that need to be fixed.** 

Common error categories found:
- **Unused variables and imports** (many files)
- **Missing component props** (like `title` prop for PageLayout)
- **Incorrect type assertions** (Card padding="xl" not valid)
- **Property access on untyped objects** (accessing properties on `any` types)
- **Type mismatches** (string | undefined vs string requirements)

**IMMEDIATE ACTION REQUIRED:**
Before doing ANY new development, these 108 errors must be systematically fixed, just like we did with the `check-api-types` validation. Otherwise, the build process will continue to fail and technical debt will accumulate exponentially.

---

## 🔄 Development Workflow

### **For AI Assistants - CRITICAL RULES**
When working on this codebase:

1. **🎯 ALWAYS read this CLAUDE.md file first**
2. **🔥 ALWAYS run `npm run check`, `npm run check-api-types`, AND `npm run knip` before starting work**
3. **🔍 Check existing components before creating new ones**
4. **💎 Use TypeScript for ALL new code - NO `any` types allowed**
5. **🛡️ Use `validatedApi` for ALL API calls - NO unvalidated responses**
6. **📐 Use PageLayout for ALL page components - NO direct Sidebar usage**
7. **🧹 Remove ALL unused imports and variables - svelte-check will flag these**
8. **✅ Run `npm run check`, `npm run check-api-types`, AND `npm run knip` before completing tasks - ALL MUST PASS**
9. **📝 Follow the Development Guard Rails section above**

### **New Feature Development Process**
1. **Plan**: Check if existing components can be reused
2. **Types**: Update types if API changes are needed
3. **Components**: Create/update components following patterns
4. **Integration**: Use established hooks and patterns
5. **Testing**: Verify TypeScript compilation and functionality
6. **Documentation**: Update CLAUDE.md if new patterns are introduced

---

## 🚨 ABSOLUTE REQUIREMENTS

### **NON-NEGOTIABLE RULES**
1. ❌ **NO JavaScript files** - TypeScript only for new code
2. ❌ **NO unvalidated API calls** - Always use `api`
3. ❌ **NO duplicate layout code** - Use `PageLayout` component
4. ❌ **NO inline authentication logic** - Use hooks or `PageLayout`
5. ❌ **NO `any` types** - Properly type everything
6. ❌ **NO skipping error handling** - Always handle API errors
7. ❌ **NO creating components without checking existing ones first**
8. ❌ **NO clickable divs** - Use `ClickableCard` or proper semantic elements
9. ❌ **NO missing ARIA labels** - All interactive elements need accessible names
10. ❌ **NO keyboard inaccessible elements** - Everything must be keyboard navigable

### **Quality Gates**
Before any code change:
- ✅ Does this follow the established patterns?
- ✅ Am I using the right components and hooks?
- ✅ Is this type-safe and validated?
- ✅ Is this accessible to users with disabilities?
- ✅ Can this be used with keyboard-only navigation?
- ✅ Will this be maintainable in 6 months?
- ✅ Have I checked existing codebase for similar functionality?

---

## 📚 Quick Reference

### **Common Imports**
```typescript
// Components
import { PageLayout, Button, Card, LoadingSpinner, ErrorMessage } from './components';

// Types & Validation
import type { Installation, Repository } from './types';
import { api, validateInstallation } from './api';

// Hooks
import { useAuth, useApi } from './hooks';
```

### **Common Patterns**
```svelte
<!-- Page Structure -->
<PageLayout activeItem="page" title="Title">
  {#if $loading}
    <LoadingSpinner />
  {:else if $error}
    <ErrorMessage type="error" message={$error} />
  {:else}
    <!-- Content -->
  {/if}
</PageLayout>
```

---

**🎯 REMEMBER: This CLAUDE.md file is the RULES ENGINE. All development must follow these standards.**

**Last Updated**: December 2024 - TypeScript Migration & Component Architecture Complete  
**Version**: 3.0 - Full Governance System

---

## Legacy Project Analysis (Historical Context)

Iris represents a modern, scalable foundation for Terrateam's user interface. The migration from OCaml to Svelte provides significant opportunities for enhanced user experience while maintaining the robust functionality of the original platform. The comprehensive API integration and flexible architecture position the project well for future feature development and scaling to meet growing user demands.

The analysis of the legacy OCaml codebase reveals sophisticated patterns around search functionality, real-time updates, and modular component design that should inform future development decisions. The new Svelte architecture provides the foundation to implement these patterns with modern web technologies while adding new capabilities around real-time collaboration, advanced analytics, and mobile-first experiences.
