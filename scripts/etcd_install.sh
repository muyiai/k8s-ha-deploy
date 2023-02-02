#!/bin/bash
#File    :   etcd_install.sh
#Time    :   2023/02/02 18:15:36
#Author  :   Zuo Yang
#Version :   1.0
#Contact :   yzuo@wuyacapital.com
#License :   (C)Copyright 2021-2025, yzuo
#Desc    :   None

echo "step1 配置"
etcd1=192.168.20.1
etcd2=192.168.20.2
etcd3=192.168.20.3

TOKEN=abcd1234
ETCDHOSTS=($etcd1 $etcd2 $etcd3)
NAMES=("master01" "master02" "master03")
for i in "${!ETCDHOSTS[@]}"; do
HOST=${ETCDHOSTS[$i]}
NAME=${NAMES[$i]}
cat << EOF > /tmp/$NAME.conf
# [member]
ETCD_NAME=$NAME
ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
ETCD_LISTEN_PEER_URLS="http://$HOST:2380"
ETCD_LISTEN_CLIENT_URLS="http://$HOST:2379,http://127.0.0.1:2379"
#[cluster]
ETCD_INITIAL_ADVERTISE_PEER_URLS="http://$HOST:2380"
ETCD_INITIAL_CLUSTER="${NAMES[0]}=http://${ETCDHOSTS[0]}:2380,${NAMES[1]}=http://${ETCDHOSTS[1]}:2380,${NAMES[2]}=http://${ETCDHOSTS[2]}:2380"
ETCD_INITIAL_CLUSTER_STATE="new"
ETCD_INITIAL_CLUSTER_TOKEN="$TOKEN"
ETCD_ADVERTISE_CLIENT_URLS="http://$HOST:2379"
EOF
done
ls /tmp/master*
scp /tmp/master02.conf $etcd2:/etc/etcd/etcd.conf
scp /tmp/master03.conf $etcd3:/etc/etcd/etcd.conf
mv /tmp/master01.conf /etc/etcd/etcd.conf
rm -f /tmp/master*.conf

echo "step2 分别在每台机器启动etcd服务"
# systemctl enable etcd --now

echo "step3 验证etcd集群"
# etcdctl member list
# etcdctl cluster-health