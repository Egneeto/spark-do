# 🚀 GitHub Pages Deployment Guide

## Prerequisites
1. Your repository is already on GitHub: ✅ https://github.com/Egneeto/spark-do
2. You have a Supabase project set up: ✅

## Step 1: Configure Repository Secrets

Go to your GitHub repository → **Settings** → **Secrets and variables** → **Actions**

Add these **Repository secrets**:

### Required Secrets:
1. **`SUPABASE_URL`**
   - Value: Your Supabase project URL
   - Example: `https://ftmxbyonwjhzrzwatwin.supabase.co`

2. **`SUPABASE_ANON_KEY`**
   - Value: Your Supabase anonymous/public key  
   - Example: `eyJhbGciOiJIUzI1NiIs...` (full JWT token)

## Step 2: Enable GitHub Pages

1. Go to repository **Settings** → **Pages**
2. Under **Source**, select: **GitHub Actions**
3. Save the settings

## Step 3: Deploy Database Policies

Before the first deployment, run this SQL in your Supabase SQL Editor:
```sql
-- Copy the entire content from fix_rls_policies.sql
-- This fixes the Row Level Security policies
```

## Step 4: Trigger Deployment

The deployment will automatically trigger when you:
- Push to the `main` branch
- Create a Pull Request
- Manually trigger via **Actions** tab → **Deploy Flutter Web to GitHub Pages** → **Run workflow**

## Step 5: Access Your App

After successful deployment, your app will be available at:
**https://egneeto.github.io/spark-do/**

## Deployment Features

✅ **Automatic builds** on every push to main
✅ **Production-ready** Flutter web build
✅ **Supabase integration** with secure environment variables
✅ **Optimized for web** with HTML renderer
✅ **Fast deployment** using GitHub Actions

## Troubleshooting

- **Build fails**: Check GitHub Actions logs in the Actions tab
- **App doesn't load**: Verify Supabase secrets are correct
- **Database errors**: Ensure RLS policies are deployed
- **Blank page**: Check browser console for errors

## Manual Deployment Commands

For local testing:
```bash
# Build for web
flutter build web --release --web-renderer html

# Test locally
flutter run -d chrome --web-port 8080
```
