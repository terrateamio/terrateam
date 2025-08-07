import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import starlightImageZoom from "starlight-image-zoom";
import { pluginLineNumbers } from '@expressive-code/plugin-line-numbers';

export default defineConfig({
  vite: {
    define: {
      'process.env.NODE_ENV': JSON.stringify(process.env.NODE_ENV)
    }
  },
  site: 'https://docs.terrateam.io',
  integrations: [
    starlight({
      title: "Terrateam",
      components: {
        SiteTitle: './src/components/SiteTitle.astro',
      },
      plugins: [starlightImageZoom()],
      expressiveCode: {
        themes: ["starlight-dark", "solarized-light"],
        styleOverrides: { borderRadius: "0.7rem" },
        defaultProps: {
          wrap: true,
          showLineNumbers: false,
        },
        plugins: [pluginLineNumbers()],
      },
      description: "Terraform and OpenTofu automation on GitHub",
      logo: {
        src: "/src/assets/logo-wordmark.svg",
        replacesTitle: true,
      },
      head: [
        // Only add this script in production environment (vercel env var)
        ...(process.env.NODE_ENV === 'production'
          ? [
              {
                tag: 'script',
                attrs: {
                  src: '/ph-init.js', // Initialize PostHog (no cookie)
                  defer: true,
                },
              },
            ]
          : []
        ),
      ],
      social: {
        github: "https://github.com/terrateamio/terrateam",
      },
      customCss: process.env.NO_GRADIENTS
        ? []
        : [
            "/src/assets/docs.css",
            "@fontsource/roboto",
            "/src/styles/mermaid.css"  
          ],
      sidebar: [
        { label: "Welcome", link: "/" },
        { label: "How It Works", link: "/how-it-works" },
        {
          label: "Getting Started",
          items: [
            { label: "Quickstart Guide", link: "/getting-started/quickstart-guide" },
            { label: "Concepts", link: "/getting-started/concepts" },
            { label: "Configuration", link: "/getting-started/configuration" },
            { label: "Plan And Apply", link: "/getting-started/plan-and-apply" },
            { label: "Pull Requests and Triggers", link: "/getting-started/pull-requests-and-triggers" },
            { label: "Secrets and Variables", link: "/getting-started/secrets-and-variables" },
            { label: "Tag Queries", link: "/getting-started/tag-queries" },
          ],
        },
        {
          label: "Cloud Providers",
          collapsed: true,
          items: [
            {
              label: "AWS",
              collapsed: true,
              items: [
                { label: "Getting Started", link: "/cloud-providers/aws/getting-started" },
                { label: "Static Credentials", link: "/cloud-providers/aws/static-credentials" },
                { label: "OIDC Setup", link: "/cloud-providers/aws/oidc-setup" },
              ],
            },
            {
              label: "GCP",
              collapsed: true,
              items: [
                { label: "Getting Started", link: "/cloud-providers/gcp/getting-started" },
                { label: "Static Credentials", link: "/cloud-providers/gcp/static-credentials" },
                { label: "OIDC Setup", link: "/cloud-providers/gcp/oidc-setup" },
              ],
            },
            { label: "Azure", link: "/cloud-providers/azure" },
            { label: "Other", link: "/cloud-providers/other" },
          ],
        },
        {
          label: "Advanced Workflows",
          autogenerate: { directory: "advanced-workflows" },
          collapsed: true,
        },
        {
          label: "Integrations",
          autogenerate: { directory: "integrations" },
          collapsed: true,
        },
        {
          label: "Security and Compliance",
          autogenerate: { directory: "security-and-compliance" },
          collapsed: true,
        },
        {
          label: "Command Reference",
          autogenerate: { directory: "command-reference" },
          collapsed: true,
        },
        {
          label: "Configuration Reference",
          autogenerate: { directory: "configuration-reference" },
          collapsed: true,
        },
        {
          label: "Self-Hosted",
          collapsed: true,
          items: [
            { label: "Overview", link: "/self-hosted" },
            { label: "Getting Started", link: "/self-hosted/getting-started" },
            { label: "Docker Compose", link: "/self-hosted/docker-compose" },
            { label: "Kubernetes", link: "/self-hosted/kubernetes" },
            { label: "Environment Variables", link: "/self-hosted/environment-variables" },
          ],
        },
        {
          label: "Guides",
          autogenerate: { directory: "guides" },
          collapsed: true,
        },
        {
          label: "Company",
          autogenerate: { directory: "company" },
          collapsed: true,
        },
      ],
    }),
  ],
  markdown: {
    rehypePlugins: []
  },
  redirects: {
    '/quickstart-guide': '/getting-started/quickstart-guide',
    '/security-and-compliance/plan-and-apply-permissions': '/security-and-compliance/role-based-access-control',
    '/configuration': '/getting-started/configuration',
    '/cloud-provider-setup/aws': '/cloud-providers/aws',
    '/cloud-provider-setup/gcp': '/cloud-providers/gcp',
    '/cloud-provider-setup/azure': '/cloud-providers/azure',
    '/cloud-provider-setup/other': '/cloud-providers/other',
    '/company/privacy-policy': 'https://terrateam.io/privacy-policy',
    '/company/cookies': 'https://terrateam.io/cookies',
    '/company/terms-of-service': 'https://terrateam.io/terms-of-service',
    '/company/security-and-data': 'https://terrateam.io/security',
    '/self-hosted/overview': '/self-hosted/instructions',
  },
});
