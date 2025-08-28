#!/bin/bash
set -e

# Branch where PR is coming from
BRANCH="build/UAT"

echo "🔄 Fetching latest branches..."
git fetch origin

echo "🌿 Checking out PR branch: $BRANCH"
git checkout $BRANCH

echo "🔀 Merging main into $BRANCH..."
git merge origin/main || true

# Check if README.md has a conflict
if grep -q '<<<<<<<' README.md; then
  echo "⚠️ Conflict detected in README.md, resolving intelligently..."

  python3 <<'EOF'
import re

with open("README.md", "r", encoding="utf-8") as f:
    content = f.read()

# Regex to capture conflict blocks
pattern = re.compile(r"<<<<<<< HEAD\n(.*?)\n=======\n(.*?)\n>>>>>>>.*", re.DOTALL)

def resolve_conflict(head, main):
    head, main = head.strip(), main.strip()

    # Rule 1: If both are identical → keep one
    if head == main:
        return head

    # Rule 2: If one contains the other → keep the superset
    if head in main:
        return main
    if main in head:
        return head

    # Rule 3: Otherwise, merge both (stacked with newline)
    return head + "\n" + main

def replacer(match):
    head, main = match.group(1), match.group(2)
    return resolve_conflict(head, main)

resolved = pattern.sub(lambda m: replacer(m), content)

with open("README.md", "w", encoding="utf-8") as f:
    f.write(resolved)

print("✅ README.md conflict resolved intelligently.")
EOF

  git add README.md
  git commit -m "🤖 Auto-resolved README.md conflict"
  git push origin $BRANCH
else
  echo "✅ No conflict found in README.md"
fi

echo "🎉 Script finished. PR should now be mergeable."
