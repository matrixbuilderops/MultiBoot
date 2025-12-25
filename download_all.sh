#!/bin/bash
cd /media/phantom-orchestrator/BitcoinNode/AI\ Projects/MultiBoot/AsahiRepos_Complete
count=0
total=$(wc -l < repo_list.txt)

while IFS= read -r repo; do
    count=$((count + 1))
    echo "[$count/$total] Cloning: $repo"
    git clone --depth 1 https://github.com/AsahiLinux/$repo.git 2>&1 | grep -E "Cloning|done|fatal|already exists"
    sleep 3
done < repo_list.txt

echo ""
echo "✅ DOWNLOAD COMPLETE!"
echo "Total repos: $(ls -1 | grep -v "repo_list.txt" | grep -v "download_all.sh" | wc -l)"
