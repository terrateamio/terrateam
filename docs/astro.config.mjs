import { defineConfig } from "astro/config";
import starlight from "@astrojs/starlight";
import starlightImageZoom from "starlight-image-zoom";
import { pluginLineNumbers } from '@expressive-code/plugin-line-numbers';
import rehypeMermaid from 'rehype-mermaid';
import addMermaidClass from './add-mermaid-classname';

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
        Banner: './src/components/Banner.astro',
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
        src: "/src/assets/logo.png",
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
        : ["/src/assets/docs.css", "@fontsource/roboto"],
      sidebar: [
        { label: "Welcome", link: "/" },
        { label: "Quickstart Guide", link: "/quickstart-guide" },
        { label: "How It Works", link: "/how-it-works" },
        {
          label: "Getting Started",
          autogenerate: { directory: "getting-started" },
        },
        {
          label: "Cloud Providers",
          autogenerate: { directory: "cloud-providers" },
          collapsed: true,
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
          autogenerate: { directory: "self-hosted" },
          collapsed: true,
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
    rehypePlugins: [addMermaidClass, rehypeMermaid],
  },
  redirects: {
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
  },
});
