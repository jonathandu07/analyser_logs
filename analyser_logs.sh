#!/bin/bash

# === CONFIGURATION ===
REPO_DIR="/root/analyser_logs"
DATE_DIR="$(date +%F)"
LOGS_DIR="$REPO_DIR/logs/$DATE_DIR"
ARCHIVE_FILE="$REPO_DIR/logs/logs_$DATE_DIR.tar.gz"
LOGFILE="$LOGS_DIR/log_$(date +%F_%Hh%Mm).log"
GIT_LOG_ERR="/root/analyser_logs/git_push_errors.log"

SOURCE_LOGS=(
  "/var/log/auth.log"
  "/var/log/syslog"
  "/var/log/nginx/access.log"
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

# === CRÉATION DU RÉPERTOIRE DU JOUR ===
mkdir -p "$LOGS_DIR"

# === CRÉATION DU RAPPORT DE LOG ===
{
  echo "🛡️ Rapport de sécurité - $(date '+%Y-%m-%d %H:%M:%S')"
  echo "======================================================"

  echo -e "\n📌 Top IPs actives :"
  for LOG in "${SOURCE_LOGS[@]}"; do
    [[ -f "$LOG" ]] && grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$LOG" | sort | uniq -c | sort -nr | head -10
  done

  echo -e "\n🚨 Activité suspecte détectée :"
  for LOG in "${SOURCE_LOGS[@]}"; do
    [[ -f "$LOG" ]] && for keyword in "${KEYWORDS[@]}"; do
      grep "$keyword" "$LOG"
    done
  done
} > "$LOGFILE"

# === SUPPRESSION DES LOGS DE +7 JOURS ===
find "$REPO_DIR/logs" -type f -name "*.log" -mtime +7 -exec rm -f {} \;

# === COMPRESSION DU DOSSIER DU JOUR ===
tar -czf "$ARCHIVE_FILE" -C "$REPO_DIR/logs" "$DATE_DIR"

# (Optionnel) Supprimer les fichiers bruts après compression :
# rm -rf "$LOGS_DIR"

# === GIT COMMIT & PUSH ===
cd "$REPO_DIR"
git add "logs/"
git commit -m "📦 Logs compressés du $DATE_DIR" > /dev/null 2>&1

if ! git push >> "$GIT_LOG_ERR" 2>&1; then
  echo "❌ Échec du git push le $(date '+%Y-%m-%d %H:%M:%S')" >> "$GIT_LOG_ERR"
fi
