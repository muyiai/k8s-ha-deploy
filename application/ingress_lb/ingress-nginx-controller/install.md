<!--
 * @Date: 2022-08-27 19:54:18
 * @Author: Zuo Yang
 * @Email: git config user.email
 * @LastEditors: Zuo Yang
 * @LastEditTime: 2022-08-27 20:25:58
 * @FilePath: /k8s/cluster/ingress-nginx/ingress-nginx-controller/install.md
-->
# add repo
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update
# install command
kubectl create namespace ingress-nginx
helm upgrade --install ingress-nginx . -f ./ci/daemonset-prod.yaml --namespace ingress-nginx
#
