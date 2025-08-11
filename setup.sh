#!/usr/bin/env bash
set -euo pipefail

# Repo settings
USER="dave-pemberton-ibm"
REPO="TechXChange_Lab_2717"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$USER/$REPO/$BRANCH"

# Files to download
FILES=(
  "LabNewsFeed.zip"
  "package-install.sh"
)

# Download each file
for file in "${FILES[@]}"; do
  URL="$BASE_URL/$file"
  echo "Downloading $file from $URL..."
  
  # Attempt download
  if curl -fSL "$URL" -o "$file"; then
    echo "✔ Successfully downloaded $file."
  else
    echo "✖ Failed to download $file."
  fi

  echo
done

chmod +x *.sh

