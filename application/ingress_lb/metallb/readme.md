<!--
 * @Date: 2022-08-12 17:19:14
 * @Author: Zuo Yang
 * @Email: git config user.email
 * @LastEditors: Zuo Yang
 * @LastEditTime: 2022-08-12 17:19:15
 * @FilePath: /k8s/cluster/ingress-nginx/metallb/readme.md
-->
1、安装yaml: metallb-native.yaml 
2、分配IP池yaml: iptool.yaml
安装参考：
https://platform9.com/blog/using-metallb-to-add-the-loadbalancer-service-to-kubernetes-environments/
https://blog.cnscud.com/k8s/2021/09/17/k8s-metalb.html
# 安装步骤
```bash
kubectl create namespace metallb-system
kubectl apply -f metallb-native.yaml -n metallb-system
kubectl apply -f iptool.yaml -n metallb-system
```
