#!/bin/bash
#File    :   cri_install.sh
#Time    :   2023/02/02 18:06:51
#Author  :   Zuo Yang
#Version :   1.0
#Contact :   zuoyang_pku@163.com
#License :   (C)Copyright 2021-2025, yzuo
#Desc    :   None

# 1、使用docker engine作为CRI, 使用docker进行容器管理
# 安装docker所需的工具
yum install -y yum-utils device-mapper-persistent-data lvm2 bash-completion net-tools gcc
# 配置阿里云的docker源
yum-config-manager --add-repo http://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo
yum install -y docker-ce
echo "先同步主节点/etc/docker/damon.json文件到目标机器，启动docker"
systemctl daemon-reload
systemctl enable docker && systemctl start docker && systemctl status docker

# 安装cri-dockerd，参考：https://github.com/Mirantis/cri-dockerd
git clone https://github.com/Mirantis/cri-dockerd.git
# 编译安装需要使用go环境，安装go环境
yum install -y golang
# vim /etc/profile
# 添加
export GOROOT=/usr/lib/golang
export GOPATH=/home/gopath/
export GO111MODULE=on
export PATH=$PATH:$GOROOT/bin:$GOPATH/bin
# source /etc/profile
# 
go env -w GOPROXY=https://goproxy.io,direct
cd cri-dockerd
mkdir bin
go get && go build -o bin/cri-dockerd
# mkdir -p /usr/local/bin
mkdir -p /usr/local/bin
install -o root -g root -m 0755 bin/cri-dockerd /usr/local/bin/cri-dockerd
cp -a packaging/systemd/* /etc/systemd/system
sed -i -e 's,/usr/bin/cri-dockerd,/usr/local/bin/cri-dockerd,' /etc/systemd/system/cri-docker.service
# 修改/etc/systemd/system/cri-docker.service
echo "修改/etc/systemd/system/cri-docker.service"
echo "将下段命令复制到上述文件对应的位置:"
echo "ExecStart=/usr/local/bin/cri-dockerd --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.7"
vim /etc/systemd/system/cri-docker.service
# ExecStart=/usr/local/bin/cri-dockerd --network-plugin=cni --pod-infra-container-image=registry.aliyuncs.com/google_containers/pause:3.7

systemctl daemon-reload
systemctl enable cri-docker.service
systemctl enable --now cri-docker.socket
systemctl status cri-docker.service
systemctl status cri-docker.socket