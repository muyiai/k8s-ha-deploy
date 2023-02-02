#!/bin/bash
#File    :   pre.sh
#Time    :   2023/02/02 18:04:34
#Author  :   Zuo Yang
#Version :   1.0
#Contact :   zuoyang_pku@163.com
#License :   (C)Copyright 2021-2025, yzuo
#Desc    :   None

# 所有机器均需要安装
echo "step1 关闭防火墙"
systemctl disable firewalld
systemctl stop firewalld
echo "success 关闭防火墙"

echo "step2 安装iptables"
yum -y install iptables-services
# 在 iptables 添加规则，开放 6443 端口，在 /etc/sysconfig/iptables 文件内容中修改
# 添加 6443 端口开放记录(在 COMMIT 前面添加)
# -A INPUT -m state --state NEW -m tcp -p tcp --dport 6443 -j ACCEPT
systemctl start iptables
systemctl enable iptables
iptables -F
service iptables save
iptables -L
echo "success 安装iptables"

echo "step3 关闭selinux"
# 临时禁用selinux
setenforce 0
# 永久关闭 修改/etc/sysconfig/selinux文件设置
sed -i 's/SELINUX=enforcing/SELINUX=disabled/g' /etc/sysconfig/selinux
sed -i "s/SELINUX=enforcing/SELINUX=disabled/g" /etc/selinux/config
echo "success 关闭selinux"

echo "step4 禁用交换分区"
swapoff -a
# 永久禁用，打开/etc/fstab注释掉swap那一行。
sed -i 's/.*swap.*/#&/g' /etc/fstab
echo "success 禁用交换分区"

echo "step5 执行配置CentOS阿里云源"
rm -rfv /etc/yum.repos.d/*
curl -o /etc/yum.repos.d/CentOS-Base.repo http://mirrors.aliyun.com/repo/Centos-7.repo
echo "success 执行配置CentOS阿里云源"

echo "step6 时间同步"
yum install -y chrony
systemctl enable chronyd.service
systemctl restart chronyd.service
systemctl status chronyd.service

echo "step7 更新内核"
curl -o /etc/yum.repos.d/epel.repo http://mirrors.aliyun.com/repo/epel-7.repo
rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
yum install -y https://www.elrepo.org/elrepo-release-7.0-4.el7.elrepo.noarch.rpm
# 设置内核
#更新yum源仓库
yum -y update
#查看可用的系统内核包
yum --disablerepo="*" --enablerepo=elrepo-kernel list available
#安装内核，注意先要查看可用内核，我安装的是5.19版本的内核
yum --enablerepo=elrepo-kernel install  kernel-ml -y
# yum --enablerepo=elrepo-kernel install kernel-ml -y 
#查看目前可用内核
awk -F\' '$1=="menuentry " {print i++ " : " $2}' /etc/grub2.cfg
echo "使用序号为0的内核，序号0是前面查出来的可用内核编号"
grub2-set-default 0
#生成 grub 配置文件并重启
grub2-mkconfig -o /boot/grub2/grub.cfg
echo "success 更新内核"

# 集群内无法 ping 通 ClusterIP（或 ServiceName）
echo "step6 配置服务器支持开启ipvs"
cat > /etc/sysconfig/modules/ipvs.modules <<EOF
#!/bin/bash
modprobe -- ip_vs
modprobe -- ip_vs_rr
modprobe -- ip_vs_wrr
modprobe -- ip_vs_sh
modprobe -- nf_conntrack_ipv4
EOF
chmod 755 /etc/sysconfig/modules/ipvs.modules && bash /etc/sysconfig/modules/ipvs.modules && lsmod | grep -e ip_vs -e nf_conntrack_ipv4

yum install -y ipset ipvsadm
echo "success 配置服务器支持开启ipvs"

sh ipv4_bridged.sh

echo "重启服务器"
# reboot
