# 🚀 GitHub Pages Deployment Guide

## Prerequisites
1. Your repository is already on GitHub: ✅ https://github.com/Egneeto/spark-do
2. You have a Supabase project set up: ✅
3. Supabase credentials are configured in `lib/config/supabase_config.dart`: ✅

## Step 1: Enable GitHub Pages

1. Go to: https://github.com/Egneeto/spark-do/settings/pages
2. Under **"Source"**, select: **"GitHub Actions"**
3. Save the settings

## Step 2: Deploy Database Policies

Before the first deployment, run this SQL in your Supabase SQL Editor:
```sql
-- Copy the entire content from fix_rls_policies.sql
-- This fixes the Row Level Security policies
```

## Step 3: Trigger Deployment

The deployment will automatically trigger when you:
- Push to the `main` branch
- Create a Pull Request
- Manually trigger via **Actions** tab → **Deploy Flutter Web to GitHub Pages** → **Run workflow**

## Step 4: Access Your App

After successful deployment, your app will be available at:
**https://egneeto.github.io/spark-do/**

## Deployment Features

✅ **Automatic builds** on every push to main
✅ **Production-ready** Flutter web build  
✅ **Optimized for web** with HTML renderer
✅ **Fast deployment** using GitHub Actions
✅ **No secrets required** - credentials are in the code

## Configuration

The app is configured with:
- **Supabase URL**: https://ftmxbyonwjhzrzwatwin.supabase.co
- **App Domain**: https://egneeto.github.io/spark-do/
- **Anonymous editing**: Disabled by default
- **Share link expiration**: Disabled

## Troubleshooting

- **Build fails**: Check GitHub Actions logs in the Actions tab
- **App doesn't load**: Verify Supabase project is active
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
