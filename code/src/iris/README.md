# Terrateam Iris

Web interface for [Terrateam](https://terrateam.io), built with Svelte and TypeScript.

## Quick Start

### Prerequisites
- Node.js v18+
- nginx, authbind, openssl

### Setup

```bash
# Install dependencies
npm install

# Configure hosts file
sudo echo "127.0.0.1 app.terrateam.io" >> /etc/hosts

# Configure authbind (Linux only)
sudo touch /etc/authbind/byport/{80,443}
sudo chown $USER:$USER /etc/authbind/byport/{80,443}
sudo chmod 755 /etc/authbind/byport/{80,443}

# Start development environment
npm run dev:full
```

Visit https://app.terrateam.io and accept the self-signed certificate.

## Development

| Command | Description |
|---------|-------------|
| `npm run dev` | Start Vite dev server only |
| `npm run dev:full` | Start complete dev environment with nginx proxy |
| `npm run build` | Build for production |
| `npm run check` | Run TypeScript and Svelte checks |

## Architecture

### Tech Stack
- **Svelte 4** with TypeScript
- **Tailwind CSS** for styling
- **Vite** for build tooling
- **Zod** for runtime validation

### Key Patterns
- All pages use `PageLayout` component
- Type-safe API client with runtime validation
- Reactive stores for state management
- Accessibility-first component design

### Project Structure
```
src/
├── lib/
│   ├── components/     # Reusable UI components
│   ├── api.ts         # Type-safe API client
│   ├── types.ts       # TypeScript types and Zod schemas
│   └── *.svelte       # Page components
└── main.js            # Entry point
```

## Maintenance Mode

Enable maintenance mode to display a static page during downtime:

### Environment Variables (Recommended)
```bash
# Enable maintenance mode
VITE_TERRATEAM_MAINTENANCE=true

# Optional: Custom message
VITE_TERRATEAM_MAINTENANCE_MESSAGE="Scheduled maintenance. Back at 3PM EST."

# Examples:
VITE_TERRATEAM_MAINTENANCE=true npm run build
VITE_TERRATEAM_MAINTENANCE=true npm run dev
```

### Runtime Configuration
```javascript
// Can also be set via window.terrateamConfig
window.terrateamConfig = {
  maintenanceMode: true,
  maintenanceMessage: "Scheduled maintenance in progress"
};
```

## API Integration

The app connects to Terrateam's production API through an nginx proxy in development. All API calls include runtime validation:

```typescript
// Example API call with automatic validation
const response = await api.getUserInstallations();
// response.installations is guaranteed to be Installation[]
```

## Troubleshooting

### SSL Certificate Errors
Accept the self-signed certificate or regenerate: `npm run dev:certs`

### API Requests Failing
- Check nginx logs: `tail -f logs/nginx_error.log`
- Verify /etc/hosts contains app.terrateam.io entry
- Clear cookies and re-authenticate

### Permission Denied Starting nginx
Ensure authbind is configured correctly (see setup)

## Contributing

1. Follow TypeScript patterns - no `any` types
2. Use existing UI components from `src/lib/components/`
3. All pages must use `PageLayout` wrapper
4. Run `npm run check` before committing
