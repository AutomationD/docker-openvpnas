#!/usr/bin/env bash
## Shell setting
if [[ ! -z "$OPENVPN_DEBUG" ]]; then
    set -ex
fi
export DEBIAN_FRONTEND="noninteractive"


ETC_DIR="/usr/local/openvpn_as/etc"
CONFIG_JSON="${ETC_DIR}/config.json"
AS_CONF="${ETC_DIR}/as.conf"
DB_FILE="${ETC_DIR}/db/config.db"

export SPECIAL_VARS="OPENVPN_ADMIN_USERNAME OPENVPN_ADMIN_PASSWORD OPENVPN_AS_VERSION OPENVPN_HOSTNAME OPENVPN_POST_AUTH_SCRIPT OPENVPN_DUO_INTEGRATION_KEY OPENVPN_DUO_SECRET_KEY OPENVPN_DUO_API_HOSTNAME"

if [[ ! -f "${DB_FILE}" ]]; then
  echo "INIT (since DB file ${DB_FILE} is missing)"
  # Init happens only if db directory is empty, that's why it's ok to force it
  OVPN_INIT_PARAMS="--no_start --batch --no_private --force --local_auth"

  if [[ ! -z ${OPENVPN_HOST__NAME:-} ]]; then
    OVPN_INIT_PARAMS="${OVPN_INIT_PARAMS} --host=${OPENVPN_HOST__NAME}"
  fi

  if [[ ! -z ${OPENVPN_LICENSE:-} ]]; then
    OVPN_INIT_PARAMS="${OVPN_INIT_PARAMS} --license=${OPENVPN_LICENSE}"
  fi

  export OPENVPN_ADMIN_PASSWORD=$(openssl rand -base64 32)
  echo -e "${OPENVPN_ADMIN_PASSWORD}\n${OPENVPN_ADMIN_PASSWORD}" | passwd openvpn

  echo "###########################################################"
  echo "#               = Temporary Credentials =                 #"
  echo "#                                                         #"
  echo "# User: openvpn                                           #"
  echo "# Password: ${OPENVPN_ADMIN_PASSWORD}  #"
  echo "#                                                         #"
  echo "#      Please log in and create a new admin user          #"
  echo "#        and restart a container at least once            #"
  echo "###########################################################"

  ovpn-init ${OVPN_INIT_PARAMS}

else
  # 2nd and all subsequent runs
  echo "Ensure default user is absent"
  userdel -r -f openvpn && (sleep 30 && sacli --user "openvpn" UserPropDelAll) &
  export OPENVPN_BOOT_PAM_USERS__0='#'
fi




if [[ ! -z "$(env | grep -E '^OPENVPN_')" ]]; then
  echo "####################################################"
  echo "#                  ENV config                      #"
  echo "####################################################"
fi

if [[ ! -z ${OPENVPN_DUO_INTEGRATION_KEY} ]]; then
  sed -r -i "s/'<DUO INTEGRATION KEY HERE>'/'${OPENVPN_DUO_INTEGRATION_KEY}'/g" /usr/local/openvpn_as/scripts/duo_openvpn_as.py
fi

if [[ ! -z ${OPENVPN_DUO_SECRET_KEY} ]]; then
  sed -r -i "s/'<DUO INTEGRATION SECRET KEY HERE>'/'${OPENVPN_DUO_SECRET_KEY}'/g" /usr/local/openvpn_as/scripts/duo_openvpn_as.py
fi
if [[ ! -z ${OPENVPN_DUO_API_HOSTNAME} ]]; then
  sed -r -i "s/'<DUO API HOSTNAME HERE>'/'${OPENVPN_DUO_API_HOSTNAME}'/g" /usr/local/openvpn_as/scripts/duo_openvpn_as.py
fi

for VAR in $(env)
do
  if [[ ! -z "$(echo $VAR | grep -E '^OPENVPN_')" ]]; then
    VAR_NAME=$(echo "$VAR" | sed -r "s/OPENVPN_([^=]*)=.*/\1/g" | tr '[:upper:]' '[:lower:]' | sed -r "s/__/\./g")
    VAR_FULL_NAME=$(echo "$VAR" | sed -r "s/([^=]*)=.*/\1/g")

    # Ignore Special Vars
    if [[ ! "${SPECIAL_VARS}" == "*${VAR_NAME}*" ]]; then

      # as.config
      if [[ ! -z "$(cat $AS_CONF |grep -E "^(^|^#*|^#*\s*)$VAR_NAME")" ]]; then
        echo "$VAR_NAME"

        if [[ "$(eval echo \$$VAR_FULL_NAME)" == "#" ]]; then
          # Comment var if value is a hash
          echo "Disabling $VAR_NAME"
          sed -r -i "s/(^#*\s*)($VAR_NAME)\s*=\s*(.*)/# \2=$(eval echo \$$VAR_FULL_NAME|sed -e 's/\//\\\//g')/g" $AS_CONF
        else
          sed -r -i "s/(^#*\s*)($VAR_NAME)\s*=\s*(.*)/\2=$(eval echo \$$VAR_FULL_NAME|sed -e 's/\//\\\//g')/g" $AS_CONF
        fi
      fi

      # config.json
      if [[ ! -z "$(cat $CONFIG_JSON | jq ".Default.\"$VAR_NAME\"")" ]]; then
        echo "$VAR_NAME"
        cat $CONFIG_JSON | jq ".Default.\"$VAR_NAME\" = \"$(eval echo \$$VAR_FULL_NAME|sed -e 's/\//\\\//g')\"" > $CONFIG_JSON
      fi
    fi
  fi
done

echo "####################################################"
echo "#        Starting Openvpn Access Server            #"
echo "#                 v.${OPENVPN_AS_VERSION}                          #"
echo "####################################################"

confdba --load --file=$CONFIG_JSON
openvpnas --nodaemon --umask=0077
