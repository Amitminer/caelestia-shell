#!/bin/bash

# Check for uncommitted changes
if [[ -n $(git status --porcelain) ]]; then
  echo "You have uncommitted changes. Please commit or stash them before updating."
  exit 1
fi

# Fetch upstream changes
git fetch upstream || { echo "Failed to fetch upstream."; exit 1; }

# Checkout main branch
git checkout main || { echo "Failed to checkout main branch."; exit 1; }

# Merge upstream changes into main
if ! git merge upstream/main; then
  echo "Merge conflict or failure! Resolve manually."
  exit 1
fi

# Push updated main to your fork's origin
git push origin main || { echo "Failed to push to origin."; exit 1; }

echo "Fork updated successfully."
