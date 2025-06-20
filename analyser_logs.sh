#!/bin/bash

REPO_DIR="/home/jonathan/logs-securite"
RAPPORT="$REPO_DIR/security_report_$(date +%F).log"
DATE=$(date "+%Y-%m-%d %H:%M:%S")

LOGS=(
  "/var/log/auth.log"
  "/var/log/nginx/access.log"
  "/var/log/syslog"
)

KEYWORDS=(
  "Failed password"
  "Invalid user"
  "authentication failure"
  "Did not receive identification string"
  "possible break-in attempt"
  "403"
  "404"
  "SQL syntax"
  "wp-login"
)

# 📄 Création du rapport
echo -e "\n🛡️ Rapport de sécurité - $DATE" > "$RAPPORT"
echo "==================================================" >> "$RAPPORT"

echo "📌 IP les plus actives :" >> "$RAPPORT"
for LOG in "${LOGS[@]}"; do
  [[ -f "$LOG" ]] && grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$LOG" | sort | uniq -c | sort -nr | head -10 >> "$RAPPORT"
done

echo -e "\n🚨 Activités suspectes :" >> "$RAPPORT"
for LOG in "${LOGS[@]}"; do
  [[ -f "$LOG" ]] && for keyword in "${KEYWORDS[@]}"; do
    grep "$keyword" "$LOG" >> "$RAPPORT"
  done
done

# 🚀 Push vers GitHub
cd "$REPO_DIR"
git add "$RAPPORT"
git commit -m "📝 Rapport du $DATE"
git push origin main
