#!/bin/bash
set -e

# Configuration
# These environment variables are available in the GitHub Actions context
REPO_URL="https://x-access-token:${GITHUB_TOKEN}@github.com/${GITHUB_REPOSITORY}.git"
PAGES_BRANCH="gh-pages"
CHARTS_DIR=".cr-release-packages"
INDEX_DIR="gh-pages-repo"
GITHUB_PAGES_URL="https://$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f1).github.io/$(echo "$GITHUB_REPOSITORY" | cut -d'/' -f2)/"

echo "Starting GitHub Pages publication..."
echo "Repository: $GITHUB_REPOSITORY"
echo "Pages URL: $GITHUB_PAGES_URL"

# Clone gh-pages branch
echo "Cloning $PAGES_BRANCH branch..."
rm -rf "$INDEX_DIR"
git clone --branch "$PAGES_BRANCH" --single-branch --depth 1 "$REPO_URL" "$INDEX_DIR" || {
    echo "Branch $PAGES_BRANCH not found. Creating it..."
    mkdir -p "$INDEX_DIR"
    cd "$INDEX_DIR"
    git init
    git checkout -b "$PAGES_BRANCH"
    git remote add origin "$REPO_URL"
    cd ..
}

# Copy charts
echo "Copying charts to $INDEX_DIR..."
cp "$CHARTS_DIR"/*.tgz "$INDEX_DIR/"
if ls "$CHARTS_DIR"/*.prov 1> /dev/null 2>&1; then
  cp "$CHARTS_DIR"/*.prov "$INDEX_DIR/"
fi

# Update index
echo "Updating Helm repo index..."
helm repo index "$INDEX_DIR" --url "$GITHUB_PAGES_URL" --merge "$INDEX_DIR/index.yaml"

# Push changes
cd "$INDEX_DIR"
echo "Committing and pushing changes..."
if [ -z "$(git status --porcelain)" ]; then
  echo "No changes to commit."
else
  git config user.name "$GITHUB_ACTOR"
  git config user.email "$GITHUB_ACTOR@users.noreply.github.com"
  git add .
  git commit -m "Update Helm repository index [skip ci]"
  git push "$REPO_URL" "$PAGES_BRANCH"
  echo "Successfully pushed to $PAGES_BRANCH"
fi
