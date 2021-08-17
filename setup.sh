#!/bin/bash

[ "$DEBUG" ] && set -e

INFRAS="$1"
[[ "$INFRAS" ]] || {
  echo "[error] must set system infrastructure's type, such as R640, KVM..."
  exit 1
}

if [[ -r "utils/rpms/gperftools-2.7-1.amd64.rpm" && -r "utils/rpms/gperftools-devel-2.7-1.amd64.rpm" ]]; then
  echo "+- install gperftools to enable tcmalloc for pika!"

  n_fail=0
  for x in gperftools-libs gperftools-devel; do
    if rpm -q $x >/dev/null; then
      if rpm -q gperftools-devel-2.7-1.amd64 >/dev/null; then
        echo "already install gperftools-devel-2.7-1"
      else
        echo "already install $x, need uninstall $x..."
        n_fail=1
      fi
    fi
  done
  [[ $n_fail -gt 0 ]] && {
    echo "quite ..."
    exit 1
  }

  rpm -ivh utils/rpms/gperftools-2.7-1.amd64.rpm
  rpm -ivh utils/rpms/gperftools-devel-2.7-1.amd64.rpm
else
  echo "[error] should install gperftools(> 2.6.x)"
  exit 3
fi

yum -y install gflags-devel snappy-devel glog-devel protobuf-devel \
            zlib-devel lz4-devel libzstd-devel gcc gcc-c++

[[ "$?" -ne 0 ]] && {
  echo "dependency install error. exit ..."
  exit 4
}

TARNAME="pika-v3.4.0-${INFRAS}.tar.gz"
make -j4

if [[ -d "output" ]]; then
  mv output pika
  cp -a systemd pika/
  cp -a utils pika/
  tar czf $TARNAME pika
  echo 
fi

if [[ -e "$TARNAME" ]]; then
  echo "generate ${TARNAME} ok."
  echo
fi
