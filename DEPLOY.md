# Deploying FlyColor

## Automated Deployment (GitHub Actions)

Deployments happen automatically on every push to `main` via GitHub Actions.

**Setup (one-time):**

1. Add GitHub Secrets:
   - Go to your GitHub repo → Settings → Secrets and variables → Actions
   - Add:
     - `VERCEL_TOKEN` - Get from [Vercel Dashboard](https://vercel.com/account/tokens)
     - `VERCEL_ORG_ID` - Your organization/team ID
     - `VERCEL_PROJECT_ID` - Your project ID

2. Push to `main` - the workflow will automatically build and deploy.

## Manual Deployment

```bash
# Build Flutter web app
flutter build web --release

# Deploy to Vercel
vercel --prod --yes
```

## Configuration

The `vercel.json` file is already configured with:
- Output directory: `build/web`
- SPA routing (all routes redirect to `index.html`)
- Security headers
- Asset caching
