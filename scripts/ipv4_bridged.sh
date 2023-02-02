#!/bin/bash
#File    :   ipv4_bridged.sh
#Time    :   2023/02/02 18:06:02
#Author  :   Zuo Yang
#Version :   1.0
#Contact :   yzuo@wuyacapital.com
#License :   (C)Copyright 2021-2025, yzuo
#Desc    :   None
cat <<EOF | sudo tee /etc/modules-load.d/k8s.conf
overlay
br_netfilter
EOF

sudo modprobe overlay
sudo modprobe br_netfilter

# sysctl params required by setup, params persist across reboots
cat <<EOF | sudo tee /etc/sysctl.d/k8s.conf
net.bridge.bridge-nf-call-iptables  = 1
net.bridge.bridge-nf-call-ip6tables = 1
net.ipv4.ip_forward                 = 1
EOF

# Apply sysctl params without reboot
sudo sysctl --system
