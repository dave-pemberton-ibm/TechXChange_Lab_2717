#!/usr/bin/env bash
set -euo pipefail

# Repo settings
USER="dave-pemberton-ibm"
REPO="TechXChange_Lab_2717"
BRANCH="main"
BASE_URL="https://raw.githubusercontent.com/$USER/$REPO/$BRANCH"

# Files to download
FILES=(
  "EmployeeData.zip"
  "package-install.sh"
)

echo "----------------------------------"
echo "🧪 TechXChange lab 2717"
echo "--------------------------------- "
echo " "
echo "Downloading Assets for local runtime"
echo "Using Repo: $BASE_URL"
echo " " 
# Download each file
for file in "${FILES[@]}"; do
  URL="$BASE_URL/$file"
  echo "🌐 Downloading $file ..."
  
  # Attempt download
  if curl -s -fSL "$URL" -o "$file"; then
    echo "✅ Successfully downloaded $file."
  else
    echo "❌ Failed to download $file."
  fi

  echo
done

chmod +x *.sh
echo " "
echo "🏁 Completed 🏁"

