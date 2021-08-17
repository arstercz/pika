#!/bin/bash
set -e -o pipefail

[ "$DEBUG" ] && set -x

[[ "$#" -ne 2 ]] && {
  echo "must set port and base dir!"
  echo "such as: deploy.sh 9221 /data"
  exit 1
}

if grep -q 'Linux release 7' /etc/redhat-release; then
  echo "starting install..."
else
  echo "$0 only support Redhat/Centos 7 system!"
  exit 1
fi

BASE_PORT="$1"
BASE_DIR="$2"
[[ "$BASE_DIR" ]] || {
  echo "[error] must set BASE dir, such as /data, /export or /web ..."
  exit 1
}


if id -u pika >/dev/null 2>&1; then
  echo "check pika user ok"
else
  echo "create pika user..."
  useradd pika || exit 1
fi

PIKA_DIR="${BASE_DIR}"
if [[ $BASE_DIR =~ /$ ]]; then
  PIKA_DIR+="pika"
else
  PIKA_DIR+="/pika"
fi

if [[ -d "${PIKA_DIR}/db" ]]; then
  echo "$PIKA_DIR is already exists. skip to deploy pika"
  exit 1
else
  mkdir -p ${PIKA_DIR}/{db,dbsync,dump,log,run}
  chown pika.pika -R ${PIKA_DIR}
fi

# deploy pika
if [[ -d "/opt/pika" ]]; then
  echo "already have pika: /opt/pika..."
  echo "change pika.conf ..."
  if sed -i "s#{{path}}#${PIKA_DIR}#g" /opt/pika/conf/pika.conf && \
     sed -i "s#{{port}}#${BASE_PORT}#g" /opt/pika/conf/pika.conf ; then
    echo "sed pika.conf ok."
  else
    echo "sed pika.conf fail, exit..."
    exit 1;
  fi

  chown pika:pika -R /opt/pika

  for x in gperftools gflags glog libzstd protobuf lz4; do
    if rpm -q $x >/dev/null; then
      echo "already install $x"
    else
      rpm -ivh /opt/pika/utils/rpms/${x}*.rpm || {
        echo "install rpm $x error"
        exit 1
      }
    fi
  done
fi

# install systemd
cp -f /opt/pika/systemd/pika.service /usr/lib/systemd/system/pika.service

if [[ "$?" -eq 0 ]]; then
  systemctl daemon-reload
  systemctl start pika
  systemctl status pika
else
  echo "install pika.service error!"
  exit 3
fi
