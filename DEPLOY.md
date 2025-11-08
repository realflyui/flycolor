# Deploying FlyColor to Vercel

## Prerequisites

- Flutter SDK installed
- Node.js installed (for Vercel CLI)
- Vercel account

## Quick Deploy (Recommended)

1. **Build the Flutter web app:**
   ```bash
   flutter build web --release
   ```

2. **Install Vercel CLI** (if not already installed):
   ```bash
   npm i -g vercel
   ```

3. **Deploy from project root:**
   ```bash
   vercel --prod --yes
   ```
   
   The `--yes` flag skips confirmation prompts. The first time you deploy, Vercel will link your project and create a `.vercel` directory.

4. **Your app will be live at:**
   - Production URL: Provided in the deployment output
   - Inspect: View deployment details in Vercel dashboard

## Project Configuration

The `vercel.json` in the root directory is already configured with:
- **Output Directory:** `build/web` (Flutter's web build output)
- **SPA Routing:** All routes redirect to `index.html` for client-side routing
- **Security Headers:** XSS protection, frame options, content type options
- **Asset Caching:** Static assets cached for 1 year

## Deploy via Vercel Dashboard

1. Go to [vercel.com](https://vercel.com)
2. Click "Add New Project"
3. Import your GitHub repository
4. Configure settings:
   - **Framework Preset:** Other
   - **Root Directory:** `.` (project root)
   - **Build Command:** (leave empty - build locally first)
   - **Output Directory:** `build/web`
   - **Install Command:** (leave empty)
5. Click "Deploy"

**Note:** Since Vercel doesn't have Flutter in its build environment, you must build locally first (`flutter build web --release`) before deploying via dashboard.

## Automated Deploy (GitHub Actions)

For automatic deployments on every push to `main`:

1. **Get Vercel tokens:**
   - Install Vercel CLI: `npm i -g vercel`
   - Run: `vercel link` in your project root to link the project
   - Get tokens from [Vercel Dashboard](https://vercel.com/account/tokens) → Create Token
   - Get IDs from `.vercel/project.json` after linking, or from Vercel dashboard

2. **Add GitHub Secrets:**
   - Go to your GitHub repo → Settings → Secrets and variables → Actions
   - Add the following secrets:
     - `VERCEL_TOKEN` - Your Vercel token (from step 1)
     - `VERCEL_ORG_ID` - Your organization/team ID
     - `VERCEL_PROJECT_ID` - Your project ID

3. **Push to main branch:**
   - The GitHub Action (`.github/workflows/deploy.yml`) will automatically:
     - Build the Flutter web app
     - Deploy to Vercel

## Manual Build & Deploy

Complete workflow:

```bash
# 1. Build Flutter web app
flutter build web --release

# 2. Deploy to Vercel
vercel --prod --yes
```

## Troubleshooting

- **"build/web not found"**: Make sure you run `flutter build web --release` first
- **"Output directory error"**: Deploy from project root, not from `build/web` directory
- **First deployment**: Vercel will prompt to link project - this creates `.vercel` directory
- **Large uploads**: The build output is ~400MB, upload may take 30-60 seconds

## Notes

- Vercel doesn't have Flutter in its build environment, so you must build locally or use GitHub Actions
- The `vercel.json` in the root handles routing and headers automatically
- Static assets are cached for optimal performance
- The `.vercel` directory (created on first deploy) should be committed to git

