# Start here

This is the local `walstack.io` site.

## 1. Install and run

```bash
npm install
npm run dev
```

Then open the local URL Astro prints.

## 2. Required owner check

Open:

`src/config/site.ts`

The configured contact address is `hello@walstack.io`.
Verify that it receives mail before publishing a new deployment.

## 3. Build

```bash
npm run build
```

## 4. Connect source control

The public GitHub repository still uses its original URL; confirm the remote and branch before pushing or changing repository links. Agent instructions and business strategy (`AGENTS.md`, `CLAUDE.md`, `docs/business/`) are local-only and gitignored; never commit them.

## 5. Vercel

Use Vercel Pro or another host that permits commercial sites. Import the connected repository and deploy a preview first.

The public Hashnode sitemap has been inventoried in `docs/MIGRATION_FROM_HASHNODE.md`. Test the retained article paths and redirects on the preview, compare Search Console for any additional indexed URLs, and then plan the DNS switch.

## AI agents

Codex:
read `AGENTS.md` + `docs/business/CODEX_MASTER_PROMPT.md` (local only).

Claude:
read `CLAUDE.md` + `docs/business/CLAUDE_MASTER_PROMPT.md` (local only).

The site is already implemented. Ask agents to improve/review it, not regenerate a generic consulting website.
