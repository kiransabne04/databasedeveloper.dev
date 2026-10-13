# Start here

This is the local `databasedeveloper.dev` site. The previous site source is backed up at `/tmp/databasedeveloper-before-final.tar.gz`.

## 1. Install and run

```bash
npm install
npm run dev
```

Then open the local URL Astro prints.

## 2. Required owner check

Open:

`src/config/site.ts`

The working contact address is `kiran@databasedeveloper.dev`.
Verify it still receives mail before publishing a new deployment.

## 3. Build

```bash
npm run build
```

## 4. Connect source control

This local folder does not currently contain a `.git` directory. Connect it to your intended repository before committing or deploying from Git. Confirm the remote and branch before pushing.

## 5. Vercel

Use Vercel Pro or another host that permits commercial sites. Import the connected repository and deploy a preview first.

The public Hashnode sitemap has been inventoried in `docs/MIGRATION_FROM_HASHNODE.md`. Test the retained article paths and redirects on the preview, compare Search Console for any additional indexed URLs, and then plan the DNS switch.

## AI agents

Codex:
read `AGENTS.md` + `docs/business/CODEX_MASTER_PROMPT.md`.

Claude:
read `CLAUDE.md` + `docs/business/CLAUDE_MASTER_PROMPT.md`.

The site is already implemented. Ask agents to improve/review it, not regenerate a generic consulting website.
