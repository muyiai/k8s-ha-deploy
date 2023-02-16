# 容器存储接口（CSI）

## 简介

容器存储接口（Container Storage Interface），简称 CSI，CSI 试图建立一个行业标准接口的规范，借助 CSI 容器编排系统（CO）可以将任意存储系统暴露给自己的容器工作负载。

csi 卷类型是一种 out-tree（即跟其它存储插件在同一个代码路径下，随 Kubernetes 的代码同时编译的） 的 CSI 卷插件，用于 Pod 与在同一节点上运行的外部 CSI 卷驱动程序交互。部署 CSI 兼容卷驱动后，用户可以使用 csi 作为卷类型来挂载驱动提供的存储。

CSI 持久化卷支持是在 Kubernetes v1.9 中引入的，作为一个 alpha 特性，必须由集群管理员明确启用。换句话说，集群管理员需要在 apiserver、controller-manager 和 kubelet 组件的 “--feature-gates =” 标志中加上 “CSIPersistentVolume = true”。

CSI 持久化卷具有以下字段可供用户指定：

driver：一个字符串值，指定要使用的卷驱动程序的名称。必须少于 63 个字符，并以一个字符开头。驱动程序名称可以包含 “。”、“ - ”、“_” 或数字。
volumeHandle：一个字符串值，唯一标识从 CSI 卷插件的 CreateVolume 调用返回的卷名。随后在卷驱动程序的所有后续调用中使用卷句柄来引用该卷。
readOnly：一个可选的布尔值，指示卷是否被发布为只读。默认是 false。

## 使用说明

下面将介绍如何使用 CSI。

### 动态配置

可以通过为 CSI 创建插件 StorageClass 来支持动态配置的 CSI Storage 插件启用自动创建/删除 。

例如，以下 StorageClass 允许通过名为 com.example.team/csi-driver 的 CSI Volume Plugin 动态创建 “fast-storage” Volume。

```yaml
kind: StorageClass
apiVersion: storage.k8s.io/v1
metadata:
  name: fast-storage
provisioner: com.example.team/csi-driver
parameters:
  type: pd-ssd
```

要触发动态配置，请创建一个 PersistentVolumeClaim 对象。例如，下面的 PersistentVolumeClaim 可以使用上面的 StorageClass 触发动态配置。

```yaml
apiVersion: v1
kind: PersistentVolumeClaim
metadata:
  name: my-request-for-storage
spec:
  accessModes:
  - ReadWriteOnce
  resources:
    requests:
      storage: 5Gi
  storageClassName: fast-storage
```

当动态创建 Volume 时，通过 CreateVolume 调用，将参数 type：pd-ssd 传递给 CSI 插件 com.example.team/csi-driver 。作为响应，外部 Volume 插件会创建一个新 Volume，然后自动创建一个 PersistentVolume 对象来对应前面的 PVC 。然后，Kubernetes 会将新的 PersistentVolume 对象绑定到 PersistentVolumeClaim，使其可以使用。

如果 fast-storage StorageClass 被标记为默认值，则不需要在 PersistentVolumeClaim 中包含 StorageClassName，它将被默认使用。

### 预配置 Volume

您可以通过手动创建一个 PersistentVolume 对象来展示现有 Volumes，从而在 Kubernetes 中暴露预先存在的 Volume。例如，暴露属于 com.example.team/csi-driver 这个 CSI 插件的 existingVolumeName Volume：

```yaml
apiVersion: v1
kind: PersistentVolume
metadata:
  name: my-manually-created-pv
spec:
  capacity:
    storage: 5Gi
  accessModes:
    - ReadWriteOnce
  persistentVolumeReclaimPolicy: Retain
  csi:
    driver: com.example.team/csi-driver
    volumeHandle: existingVolumeName
    readOnly: false
```

### 附着和挂载

您可以在任何的 pod 或者 pod 的 template 中引用绑定到 CSI volume 上的 PersistentVolumeClaim。

```yaml
kind: Pod
apiVersion: v1
metadata:
  name: my-pod
spec:
  containers:
    - name: my-frontend
      image: dockerfile/nginx
      volumeMounts:
      - mountPath: "/var/www/html"
        name: my-csi-volume
  volumes:
    - name: my-csi-volume
      persistentVolumeClaim:
        claimName: my-request-for-storage
```

当一个引用了 CSI Volume 的 pod 被调度时， Kubernetes 将针对外部 CSI 插件进行相应的操作，以确保特定的 Volume 被 attached、mounted， 并且能被 pod 中的容器使用。

# ceph-csi

Ceph CSI 插件在支持 CSI 的 Container Orchestrator (CO) 和 Ceph 集群之间实现接口。它们支持动态配置 Ceph 卷并将它们附加到工作负载。

对ceph存储的RBD或cephFS分别提供了对应接口，本文主要介绍**ceph-csi-rbd**接口的安装部署。

[ceph-csi github](https://github.com/ceph/ceph-csi)

部署文档参考：[ceph-csi-rbd部署](https://github.com/ceph/ceph-csi/blob/devel/docs/deploy-rbd.md)

**注意：部署之前需要保证已经搭建好了ceph集群**

我们搭建好的ceph集群信息如下

```yaml
"clusterID": "21217f8a-8597-4734-acf6-05e9251ce8ac",
"monitors": [
  "192.168.0.13:6789",
  "192.168.0.14:6789",
  "192.168.0.15:6789"
  ]
```

## k8s部署

[yaml文件的配置模板](https://github.com/ceph/ceph-csi/tree/devel/deploy/rbd/kubernetes)

创建namespace

```yaml
kubectl create namespace ceph-csi-rbd
```

### **ceph配置**

* `csi-config-map.yaml`这里需要把ceph集群ID以及IP:Port加入到配置中

```yaml
---
apiVersion: v1
kind: ConfigMap
data:
  config.json: |-
    [
      {
        "clusterID": "21217f8a-8597-4734-acf6-05e9251ce8ac",
        "monitors": [
           "192.168.0.13:6789",
  	   "192.168.0.14:6789",
  	   "192.168.0.15:6789"
        ]
      }
    ]
metadata:
  name: ceph-csi-config
  namespace: ceph-csi-rbd
```

* `secret.yaml`  ceph集群的账号信息
* `ceph-config.yaml` ceph config

```yaml
apiVersion: v1
kind: ConfigMap
data:
  ceph.conf: |
    [global]
    auth_cluster_required = cephx
    auth_service_required = cephx
    auth_client_required = cephx
    # Workaround for http://tracker.ceph.com/issues/23446
    fuse_set_user_groups = false
    # ceph-fuse which uses libfuse2 by default has write buffer size of 2KiB
    # adding 'fuse_big_writes = true' option by default to override this limit
    # see https://github.com/ceph/ceph-csi/issues/1928
    fuse_big_writes = true
  # keyring is a required key and its value should be empty
  keyring: |
metadata:
  name: ceph-config
  namespace: ceph-csi-rbd
```

* `storageclass.yaml` 主要是配置clusterID与pool
  pool需要在ceph集群中创建
  在ceph集群中创建rbd存储池的方法

  ```bash
  ceph osd pool create rbd-k8s 256 256
  ceph osd pool application enable rbd-k8s rbd
  ceph osd pool ls detail
  rbd ls rbd-k8s
  ```

### 安装

**Create CSIDriver object:**

```bash
kubectl create -f deploy/csidriver.yaml -n ceph-csi-rbd
```

**Deploy RBACs for sidecar containers and node plugins:**

```bash
kubectl create -f deploy/csi-provisioner-rbac.yaml -n ceph-csi-rbd
kubectl create -f deploy/csi-nodeplugin-rbac.yaml -n ceph-csi-rbd
```

**Deploy ConfigMap for CSI plugins:**

```bash
kubectl create -f deploy/csi-config-map.yaml -n ceph-csi-rbd
```

**Deploy Ceph configuration ConfigMap for CSI pods:**

```shell
kubectl create -f deploy/ceph-config.yaml -n ceph-csi-rbd
```

**Deploy CSI sidecar containers:**

```bash
kubectl create -f deploy/csi-rbdplugin-provisioner.yaml -n ceph-csi-rbd
```

**Deploy CSI **driver**:**

```bash
kubectl create -f deploy/csi-rbdplugin.yaml -n ceph-csi-rbd
```

### 验证

```bash
kubectl get all -n ceph-csi-rbd
NAME                                             READY   STATUS    RESTARTS        AGE
pod/csi-rbdplugin-2ndxj                          3/3     Running   0               5d3h
pod/csi-rbdplugin-6qgx6                          3/3     Running   0               5d3h
pod/csi-rbdplugin-cjqlx                          3/3     Running   0               5d3h
pod/csi-rbdplugin-h4l4c                          3/3     Running   0               5d3h
pod/csi-rbdplugin-provisioner-5fc5bb7dbc-6p49q   7/7     Running   0               5d3h
pod/csi-rbdplugin-provisioner-5fc5bb7dbc-jcp88   7/7     Running   2               5d3h
pod/csi-rbdplugin-xlbjp                          3/3     Running   3 (4d21h ago)   5d3h

NAME                                TYPE        CLUSTER-IP      EXTERNAL-IP   PORT(S)    AGE
service/csi-metrics-rbdplugin       ClusterIP   10.96.151.212   <none>        8080/TCP   5d3h
service/csi-rbdplugin-provisioner   ClusterIP   10.107.93.250   <none>        8080/TCP   5d3h

NAME                           DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR   AGE
daemonset.apps/csi-rbdplugin   5         5         5       5            5           <none>          5d3h

NAME                                        READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/csi-rbdplugin-provisioner   2/2     2            2           5d3h

NAME                                                   DESIRED   CURRENT   READY   AGE
replicaset.apps/csi-rbdplugin-provisioner-5fc5bb7dbc   2         2         2       5d3h

```

说明安装成功

参考：
1 https://www.cnblogs.com/LiuChang-blog/p/15694898.html
2 https://github.com/ceph/ceph-csi/blob/devel/examples/README.md#deploying-the-storage-class
