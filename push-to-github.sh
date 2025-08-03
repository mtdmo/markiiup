#!/bin/bash

# Replace YOUR_USERNAME with your GitHub username
# This script helps push your markiiup project to GitHub

echo "Please enter your GitHub username:"
read GITHUB_USERNAME

echo "Please enter your repository name (default: markiiup):"
read REPO_NAME
REPO_NAME=${REPO_NAME:-markiiup}

# Add remote origin
git remote add origin https://github.com/$GITHUB_USERNAME/$REPO_NAME.git

# Rename branch to main (if needed)
git branch -M main

# Push to GitHub
git push -u origin main

echo "✅ Successfully pushed to GitHub!"
echo "🔗 Your repository is now available at: https://github.com/$GITHUB_USERNAME/$REPO_NAME"