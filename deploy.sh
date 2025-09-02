#!/bin/bash

# SparkDo - GitHub Pages Deployment Script
echo "Building SparkDo for GitHub Pages deployment..."

# Build the Flutter web app
echo "Building Flutter web app..."
flutter build web --release

# Create docs directory for GitHub Pages (if using docs folder)
if [ ! -d "docs" ]; then
    mkdir docs
fi

# Copy web build to docs directory
echo "Copying build files..."
cp -r build/web/* docs/

echo "Build complete! Files are ready in the 'docs' directory."
echo ""
echo "To deploy to GitHub Pages:"
echo "1. Commit and push the 'docs' directory to your GitHub repository"
echo "2. Go to your repository settings on GitHub"
echo "3. Navigate to 'Pages' section"
echo "4. Set source to 'Deploy from a branch'"
echo "5. Select 'main' branch and '/docs' folder"
echo "6. Save the settings"
echo ""
echo "Your app will be available at: https://your-username.github.io/your-repo-name/"
echo ""
echo "Don't forget to update the base URL in lib/services/todo_service.dart!"
