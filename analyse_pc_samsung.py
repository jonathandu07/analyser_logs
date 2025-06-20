import platform
import psutil
import cpuinfo
import GPUtil
import os
from datetime import datetime
from tabulate import tabulate
import socket

# 📁 Fichier de log
now = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
log_file = f"rapport_pc_samsung_{now}.txt"

def log(text):
    with open(log_file, "a", encoding="utf-8") as f:
        f.write(text + "\n")
    print(text)

# 🧠 Infos Système
def infos_systeme():
    log("🖥️ Informations système")
    log("=" * 40)
    log(f"Système        : {platform.system()}")
    log(f"Nom d'hôte     : {socket.gethostname()}")
    log(f"Version        : {platform.version()}")
    log(f"Édition        : {platform.platform()}")
    log(f"Architecture   : {platform.machine()}")
    log(f"Nom du PC      : {os.environ.get('COMPUTERNAME')}")
    log(f"Utilisateur    : {os.getlogin()}")
    log("")

# ⚙️ CPU
def analyse_cpu():
    cpu = cpuinfo.get_cpu_info()
    log("🧠 Processeur")
    log("=" * 40)
    log(f"Nom            : {cpu['brand_raw']}")
    log(f"Fréquence      : {psutil.cpu_freq().current:.2f} MHz")
    log(f"Cœurs (logiques/physiques) : {psutil.cpu_count()} / {psutil.cpu_count(logical=False)}")
    log(f"Utilisation (%) : {psutil.cpu_percent(interval=1)}%")
    log("")

# 🔥 GPU (si disponible)
def analyse_gpu():
    gpus = GPUtil.getGPUs()
    if not gpus:
        log("❌ Aucun GPU CUDA détecté.")
        return
    log("🎮 Carte graphique")
    log("=" * 40)
    for gpu in gpus:
        log(f"Nom         : {gpu.name}")
        log(f"Mémoire     : {gpu.memoryUsed}MB / {gpu.memoryTotal}MB")
        log(f"Température : {gpu.temperature} °C")
        log(f"Charge      : {gpu.load * 100:.1f}%")
        log("")

# 💾 Mémoire
def analyse_ram():
    log("🧮 Mémoire RAM")
    log("=" * 40)
    ram = psutil.virtual_memory()
    log(f"Totale       : {ram.total / (1024 ** 3):.2f} GB")
    log(f"Utilisée     : {ram.used / (1024 ** 3):.2f} GB")
    log(f"Libre        : {ram.available / (1024 ** 3):.2f} GB")
    log(f"Pourcentage  : {ram.percent} %")
    log("")

# 🧠 SWAP
def analyse_swap():
    swap = psutil.swap_memory()
    log("🔁 Mémoire swap")
    log("=" * 40)
    log(f"Totale     : {swap.total / (1024 ** 3):.2f} GB")
    log(f"Utilisée   : {swap.used / (1024 ** 3):.2f} GB")
    log(f"Libre      : {swap.free / (1024 ** 3):.2f} GB")
    log(f"Pourcentage: {swap.percent} %")
    log("")

# 📂 Disques
def analyse_disques():
    log("💽 Disques")
    log("=" * 40)
    partitions = psutil.disk_partitions()
    for p in partitions:
        try:
            usage = psutil.disk_usage(p.mountpoint)
            log(f"{p.device} ({p.mountpoint})")
            log(f"  Total      : {usage.total / (1024 ** 3):.2f} GB")
            log(f"  Utilisé    : {usage.used / (1024 ** 3):.2f} GB")
            log(f"  Libre      : {usage.free / (1024 ** 3):.2f} GB")
            log(f"  Pourcentage: {usage.percent} %")
            log("")
        except PermissionError:
            continue

# 🌐 Réseau
def analyse_reseau():
    log("🌐 Réseau")
    log("=" * 40)
    addrs = psutil.net_if_addrs()
    for iface, infos in addrs.items():
        log(f"Interface : {iface}")
        for info in infos:
            if info.family == socket.AF_INET:
                log(f"  Adresse IP    : {info.address}")
                log(f"  Masque        : {info.netmask}")
            elif info.family == psutil.AF_LINK:
                log(f"  MAC           : {info.address}")
    log("")

# 🧾 Processus gourmands
def top_processus():
    log("🔍 Top 10 processus (RAM)")
    log("=" * 40)
    procs = sorted(psutil.process_iter(['pid', 'name', 'memory_info', 'cpu_percent']), key=lambda p: p.info['memory_info'].rss if p.info['memory_info'] else 0, reverse=True)[:10]
    table = []
    for p in procs:
        table.append([
            p.info['pid'],
            p.info['name'],
            f"{p.info['cpu_percent']}%",
            f"{p.info['memory_info'].rss / (1024 ** 2):.2f} MB" if p.info['memory_info'] else "N/A"
        ])
    log(tabulate(table, headers=["PID", "Nom", "CPU", "Mémoire"], tablefmt="github"))
    log("")

# 🏁 Lancement
if __name__ == "__main__":
    log("🛡️ Rapport d’analyse – PC Samsung")
    log("=" * 60)
    log(f"Date : {datetime.now().strftime('%A %d %B %Y, %H:%M:%S')}")
    log("")

    infos_systeme()
    analyse_cpu()
    analyse_gpu()
    analyse_ram()
    analyse_swap()
    analyse_disques()
    analyse_reseau()
    top_processus()

    log("=" * 60)
    log("✅ Rapport terminé.")
