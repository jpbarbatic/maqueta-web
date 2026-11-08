#!/bin/bash

notificar(){
   
   if command -v notify-send > /dev/null 2>&1 
   then
      notify-send "$1" "$2"
   fi
}

cat << 'EOF'
 ____  _                            _                    _       
/ ___|(_)_ __   ___ _ __ ___  _ __ (_)______ _ _ __   __| | ___  
\___ \| | '_ \ / __| '__/ _ \| '_ \| |_  / _` | '_ \ / _` |/ _ \ 
 ___) | | | | | (__| | | (_) | | | | |/ / (_| | | | | (_| | (_) |
|____/|_|_| |_|\___|_|  \___/|_| |_|_/___\__,_|_| |_|\__,_|\___/  _________|\
__        __   _             _         _____ _____ ____          |           \
\ \      / /__| |__   __   _(_) __ _  |  ___|_   _|  _ \    /|___|_____ ___  /
 \ \ /\ / / _ \ '_ \  \ \ / / |/ _` | | |_    | | | |_) |  /           |   |/
  \ V  V /  __/ |_) |  \ V /| | (_| | |  _|   | | |  __/   \  _________|
   \_/\_/ \___|_.__/    \_/ |_|\__,_| |_|     |_| |_|       \|         
                                                             
EOF

if ! command -v lftp > /dev/null 2>&1
then
   echo "El programa lftp no está instalado. Ejecute:"
   echo "- Ubuntu/Debian: apt install lftp"
   echo "- Red Hat/Fedora: yum install lftp"
   read -p '¿Quiere instalarlo? (s/n): ' res

   if [[ $res =~ ^[Ss]$ ]]; then
      echo "Instando lftp"
      DISTRO=$(lsb_release -is 2>/dev/null)
      INSTALADOR='apt'
      case "$DISTRO" in
         Fedora)
            INSTALADOR='yum'
            ;;
      esac

      sudo $INSTALADOR install lftp
   fi
fi

if [ ! -f .env ]; then
      echo "FTP_HOST=
FTP_USER=
FTP_PASS=
FTP_LOCAL=
FTP_REMOTE=
URL=" > .env
   echo "El fichero .env ha sido creado. Edítalo con la configuración de FTP"
   exit
fi

# Crea el fichero .ftpignore si no existe
if [ ! -f .ftpignore ]; then
   touch .ftpignore
fi

. .env

if [[ -z "${FTP_HOST}" || -z "${FTP_LOCAL}" || -z "${FTP_PASS}" || -z "${FTP_REMOTE}" || -z "${FTP_USER}" ]]; then
   echo "Error: Revisa que .env contenga todos los parámetros rellenos."
   exit 1
fi

EXCLUDE=''
if [ -f '.ftpignore' ]; then
   while IFS= read -r linea; do
      [[ "$linea" == \#* ]] && continue
      echo "Ignorando $linea"
      EXCLUDE="$EXCLUDE-x ${linea} "
   done < '.ftpignore'
fi
notificar "Sincronización" "Iniciada"

echo "Conectando con $FTP_HOST"
lftp -c "open -u $FTP_USER,$FTP_PASS $FTP_HOST; mirror -v -R -p $EXCLUDE $FTP_LOCAL $FTP_REMOTE; quit"
echo "Sincronización finalizada"

notificar "Sincronización" "Finalizada"

if [ -n ${URL} ]; then
echo "Acceder en : ${URL}"
fi
