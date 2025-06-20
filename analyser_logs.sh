#!/bin/bash

# 📁 Répertoire local du dépôt
REPO_DIR="/home/jonathan/analyser_logs"
cd "$REPO_DIR" || exit 1

# 🕒 Timestamp
DATE=$(date +"%Y-%m-%d_%Hh%Mm")
FILENAME="log_${DATE}.log"
LOGFILE="${REPO_DIR}/${FILENAME}"

# 📂 Fichiers à analyser
LOGS=(
  "/var/log/auth.log"
  "/var/log/nginx/access.log"
  "/var/log/syslog"
)

# 🔍 Mots-clés suspects
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

# 🛡️ Génération du rapport
echo "🛡️ Rapport de sécurité généré le $(date '+%Y-%m-%d %H:%M:%S')" > "$LOGFILE"
echo "======================================================" >> "$LOGFILE"
echo -e "\n📌 Top IP actives :" >> "$LOGFILE"
for LOG in "${LOGS[@]}"; do
  [[ -f "$LOG" ]] && grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$LOG" | sort | uniq -c | sort -nr | head -10 >> "$LOGFILE"
done

echo -e "\n🚨 Tentatives suspectes détectées :" >> "$LOGFILE"
for LOG in "${LOGS[@]}"; do
  [[ -f "$LOG" ]] && for keyword in "${KEYWORDS[@]}"; do
    grep "$keyword" "$LOG" >> "$LOGFILE"
  done
done

# ✅ Ajout dans Git
git add "$FILENAME"
git commit -m "🔐 Rapport du $DATE"
git push origin main

echo "✅ Rapport $FILENAME généré et poussé sur GitHub"
