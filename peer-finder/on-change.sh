#!/bin/bash

echo "do onChange"
#! /bin/bash

# Copyright 2016 The Kubernetes Authors.
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# This script writes out a mysql galera config using a list of newline seperated
# peer DNS names it accepts through stdin.

# /etc/mysql is assumed to be a shared volume so we can modify my.cnf as required
# to keep the config up to date, without wrapping mysqld in a custom pid1.
# The config location is intentionally not /etc/mysql/my.cnf because the
# standard base image clobbers that location.

if [ ! -d /etc/mysql/conf.d/my.cnf ]; then
    cp /mnt/tmp/temp.cnf /etc/mysql/conf.d/my.cnf
    echo "copy my.cnf"
fi

CFG=/etc/mysql/conf.d/my.cnf

#cat ${CFG}

function join {
    local IFS="$1"; shift; echo "$*";
}

HOSTNAME=$(hostname)
# Parse out cluster name, from service name:
CLUSTER_NAME="$(hostname -f | cut -d'.' -f2)"
echo "CLUSTER_NAME = ${CLUSTER_NAME}"
while read -ra LINE; do
    echo "[MyLog] found peer ${LINE}"
    if [[ "${LINE}" == *"${HOSTNAME}"* ]]; then
        MY_NAME=$LINE
    else
        PEERS=("${PEERS[@]}" $LINE)
    fi
    
done

echo "[MyLog] peers are ${PEERS[*]}"

WSREP_CLUSTER_ADDRESS=$(join , "${PEERS[@]}")

echo "[MyLog] after shit peers are ${PEERS[*]}"

echo "MY_NAME = ${MY_NAME}"
echo "CLUSTER_NAME = ${CLUSTER_NAME}"
echo "WSREP_CLUSTER_ADDRESS = ${WSREP_CLUSTER_ADDRESS}"

sed -i -e "s|^wsrep_node_address=.*$|wsrep_node_address=${MY_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_name=.*$|wsrep_cluster_name=${CLUSTER_NAME}|" ${CFG}
sed -i -e "s|^wsrep_cluster_address=.*$|wsrep_cluster_address=gcomm://${WSREP_CLUSTER_ADDRESS}|" ${CFG}

# PEER_ARGS="--wsrep-new-cluster --wsrep_cluster_name=$CLUSTER_NAME --wsrep-cluster-address=gcomm://# $WSREP_CLUSTER_ADDRESS --wsrep_node_address=$MY_NAME"

# cat ${CFG}

# don't need a restart, we're just writing the conf in case there's an
# unexpected restart on the node.
