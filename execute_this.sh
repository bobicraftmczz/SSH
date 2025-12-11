#!/bin/bash

# ==========================
#        ENYXDEV PRO
# ==========================

# ─── Colores ───
RED="\e[31m"
GREEN="\e[32m"
YELLOW="\e[33m"
CYAN="\e[36m"
WHITE="\e[97m"
BOLD="\e[1m"
RESET="\e[0m"

# ─── Rutas ───
MC_DIR="$HOME/minecraft-server"
JAR_FILE="$MC_DIR/server.jar"
BACKUP_DIR="$MC_DIR/backups"
FM_PORT=8080
RAM="8G"

# ─── Logo ───
show_logo() {
  clear
  echo -e "${RED}${BOLD}"
  echo "██████████████████████████████████████"
  echo "███         ENYXDEV PRO PANEL       ███"
  echo "██████████████████████████████████████"
  echo -e "${RESET}"
  sleep 5
}

# ─── Validaciones ───
check_requirements() {
  if ! command -v node &>/dev/null; then
    echo -e "${YELLOW}Instalando NodeJS...${RESET}"
    curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
    sudo apt install -y nodejs
  fi

  if ! command -v npm &>/dev/null; then
    echo -e "${RED}npm no disponible. Instalación falló.${RESET}"
    exit 1
  fi
}

# ─── Detector de Java ───
autodetect_java() {
  echo -e "${CYAN}Actualizando Java automáticamente...${RESET}"
  sudo apt purge -y openjdk-* 2>/dev/null
  sudo apt install -y default-jre
  java -version
  sleep 2
}

# ─── Inicio servidor ───
start_server() {
  if [[ ! -f "$JAR_FILE" ]]; then
    echo -e "${RED}Servidor no encontrado.${RESET}"
    sleep 2
    return
  fi

  echo -e "${GREEN}Iniciando servidor con $RAM de RAM...${RESET}"
  cd "$MC_DIR" || exit
  java -Xms$RAM -Xmx$RAM -jar "$JAR_FILE" nogui
}

# ─── Reparación ───
repair_server() {
  echo -e "${CYAN}Reparando servidor...${RESET}"
  mkdir -p "$MC_DIR"
  echo "eula=true" > "$MC_DIR/eula.txt"
  chmod -R 755 "$MC_DIR"
  echo -e "${GREEN}Servidor reparado.${RESET}"
  sleep 2
}

# ─── Backup ───
backup_world() {
  if [[ ! -d "$MC_DIR/world" ]]; then
    echo -e "${RED}No existe mundo para respaldar.${RESET}"
    sleep 2
    return
  fi

  mkdir -p "$BACKUP_DIR"
  FILE="$BACKUP_DIR/world-$(date +%F_%H-%M).tar.gz"
  tar -czf "$FILE" "$MC_DIR/world"
  echo -e "${GREEN}Backup creado: $FILE${RESET}"
  sleep 2
}

# ─── Borrado seguro ───
delete_server() {
  echo -e "${RED}Escribe ELIMINAR para continuar:${RESET}"
  read -r CONF

  if [[ "$CONF" == "ELIMINAR" ]]; then
    rm -rf "$MC_DIR"
    echo -e "${GREEN}Servidor eliminado.${RESET}"
  else
    echo -e "${YELLOW}Cancelado.${RESET}"
  fi
  sleep 2
}

# ─── File Manager ───
start_file_manager() {
  echo -e "${CYAN}Iniciando File Manager WEB...${RESET}"

  if ! command -v file-manager &>/dev/null; then
    echo -e "${YELLOW}Instalando file-manager...${RESET}"
    npm install -g https://github.com/serverwentdown/file-manager.git
  fi

  # Buscar puerto libre
  PORT=$FM_PORT
  while lsof -i:$PORT &>/dev/null; do
    PORT=$((PORT+1))
  done

  # Ejecutar File Manager
  file-manager -d "$MC_DIR" -p $PORT >/dev/null 2>&1 &

  sleep 2

  # IP de tailscale
  if command -v tailscale &>/dev/null; then
    TS_IP=$(tailscale ip -4)
    echo -e "${GREEN}Acceso (Tailscale): http://$TS_IP:$PORT${RESET}"
  else
    echo -e "${YELLOW}Tailscale no instalado.${RESET}"
  fi

  echo -e "${GREEN}Local: http://localhost:$PORT${RESET}"
  sleep 3
}

# ─── Menú ───
menu() {
  while true; do
    clear
    echo -e "${RED}${BOLD}========= ENYXDEV PRO =========${RESET}"
    echo -e "${CYAN}1)${WHITE} Iniciar Servidor (30GB RAM)"
    echo -e "${CYAN}2)${WHITE} Reparar Servidor"
    echo -e "${CYAN}3)${WHITE} Respaldar Mundo"
    echo -e "${CYAN}4)${WHITE} Actualizar Java"
    echo -e "${CYAN}5)${WHITE} File Manager Web"
    echo -e "${CYAN}6)${WHITE} Borrar Servidor"
    echo -e "${CYAN}0)${WHITE} Salir"
    echo -e "${RED}==============================${RESET}"
    read -rp "Opción: " OPT

    case "$OPT" in
      1) start_server ;;
      2) repair_server ;;
      3) backup_world ;;
      4) autodetect_java ;;
      5) start_file_manager ;;
      6) delete_server ;;
      0) exit ;;
      *) echo -e "${RED}Opción inválida${RESET}"; sleep 1 ;;
    esac
  done
}

# ─── Inicio ───
check_requirements
show_logo
menu
