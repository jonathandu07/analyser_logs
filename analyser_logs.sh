#!/bin/bash

# === CONFIGURATION ===
DOSSIER_REPO="/root/analyser_logs"
DATE_FR="$(date +%d-%m-%Y)"
HEURE_FR="$(date +%Hh%Mm)"
DOSSIER_JOUR="$DOSSIER_REPO/logs/$DATE_FR"
ARCHIVE="$DOSSIER_REPO/logs/journal_$DATE_FR.tar.gz"
FICHIER_LOG="$DOSSIER_JOUR/journal_${DATE_FR}_${HEURE_FR}.log"
FICHIER_ERREUR_GIT="$DOSSIER_REPO/journal_erreurs_git.log"

FICHIERS_SOURCE=(
  "/var/log/auth.log"
  "/var/log/syslog"
  "/var/log/nginx/access.log"
)

MOTS_CLES=(
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

# === CRÉATION DU DOSSIER DU JOUR ===
mkdir -p "$DOSSIER_JOUR"

# === GÉNÉRATION DU RAPPORT ===
{
  echo "🛡️ Rapport de sécurité – $(date '+%d/%m/%Y à %Hh%M')"
  echo "=========================================================="

  echo -e "\n📌 Uptime et charge système :"
  uptime

  echo -e "\n📌 Connexions SSH actives :"
  who

  echo -e "\n📌 Derniers redémarrages :"
  last reboot | head -10

  echo -e "\n📌 Utilisation disque :"
  df -h

  echo -e "\n📌 Utilisation mémoire (RAM + Swap) :"
  free -h

  echo -e "\n📌 Détail mémoire :"
  total=$(free -m | awk '/^Mem:/ {print $2}')
  used=$(free -m | awk '/^Mem:/ {print $3}')
  swap_total=$(free -m | awk '/^Swap:/ {print $2}')
  swap_used=$(free -m | awk '/^Swap:/ {print $3}')
  printf "RAM utilisée : %s MiB / %s MiB (%.2f%%)\n" "$used" "$total" "$(echo "$used * 100 / $total" | bc -l)"
  printf "SWAP utilisée : %s MiB / %s MiB (%.2f%%)\n" "$swap_used" "$swap_total" "$(echo "$swap_used * 100 / $swap_total" | bc -l)"

  echo -e "\n📌 Top 10 processus utilisant le plus de RAM :"
  ps -eo user,pid,%mem,rss,comm --sort=-%mem | head -11

  echo -e "\n📌 Nombre total de processus par utilisateur (top 5) :"
  ps -eo user= | sort | uniq -c | sort -nr | head -5

  echo -e "\n📌 Consommation mémoire par type de processus :"
  ps -eo comm,%mem --sort=-%mem | grep -v COMMAND | \
    awk '{arr[$1]+=$2} END {for (p in arr) printf "%-20s : %.2f%%\n", p, arr[p]}' | sort -k3 -nr | head -15

  echo -e "\n📌 Top processus gourmands CPU :"
  ps aux --sort=-%cpu | head -10

  echo -e "\n📌 Ports ouverts (hors localhost) :"
  ss -tuln | grep -v "127.0.0.1"

  echo -e "\n📌 Services en échec :"
  systemctl --failed

  echo -e "\n📌 Derniers paquets installés :"
  grep " install " /var/log/dpkg.log | tail -10 2>/dev/null || echo "Fichier dpkg.log non disponible."

  echo -e "\n📌 Utilisateurs système :"
  cut -d: -f1 /etc/passwd | sort

  echo -e "\n📌 Utilisateurs autorisés sudo :"
  getent group sudo

  echo -e "\n📌 Tentatives sudo échouées :"
  journalctl _COMM=sudo | grep 'authentication failure' | tail -20 2>/dev/null || echo "Pas de journal sudo disponible."

  echo -e "\n📌 IPs actives dans les logs :"
  for FICHIER in "${FICHIERS_SOURCE[@]}"; do
    [[ -f "$FICHIER" ]] && grep -Eo '([0-9]{1,3}\.){3}[0-9]{1,3}' "$FICHIER" | sort | uniq -c | sort -nr | head -10
  done

  echo -e "\n🚨 Recherche d’activité suspecte :"
  for FICHIER in "${FICHIERS_SOURCE[@]}"; do
    [[ -f "$FICHIER" ]] && for mot in "${MOTS_CLES[@]}"; do
      echo -e "\n🔎 $mot dans $FICHIER :"
      grep --color=never "$mot" "$FICHIER" | tail -10
    done
  done
} > "$FICHIER_LOG"

# === NETTOYAGE DES LOGS DE PLUS DE 7 JOURS ===
find "$DOSSIER_REPO/logs" -type f -name "*.log" -mtime +7 -exec rm -f {} \;

# === COMPRESSION DU JOURNAL DU JOUR ===
tar -czf "$ARCHIVE" -C "$DOSSIER_REPO/logs" "$DATE_FR"

# === COMMIT ET ENVOI GIT ===
cd "$DOSSIER_REPO"
git add logs/
git commit -m "📦 Journaux complets du $DATE_FR" > /dev/null 2>&1

if ! git push >> "$FICHIER_ERREUR_GIT" 2>&1; then
  echo "❌ Échec de l’envoi Git le $(date '+%d/%m/%Y à %Hh%M')" >> "$FICHIER_ERREUR_GIT"
fi
