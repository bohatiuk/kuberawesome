# Kubernetes installation with kubeadm

### **required components**

1. container runtime
2. kubelet
3. kube-proxy as pods
4. kubeapi, sched, cm, etcd as pods on master node

Kubelet deploys static pods (normally: APi server → scheduler (on which node to schedule) → kubelet)

Deployed static pods can’t be controlled via apiserver, only via kubelet. Such pods are suffixed with node hostname and have IP address of the node.

### TLS 
Apiserver needs to autorize every client, same etcd needs to authorize apiserver
Each component gets a certtificate signed by same CA (certificate for CA is self signed by Kubernetes)

1. generate self-signed CA certificate for whole Kuberneyes cluster - “cluster root CA”
2. sign all client and server certs with it

### prerequisites (both master and worker):

- unique hostname
- same network (public or private)
- disabled swap
- required inbounds ports are open:

### install containerd (on each node):

1. save file with kernel modules needed for containerd

```
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
```

1. load those modules

```
sudo modprobe overlay && sudo modprobe br_netfilter
```

3.  setup required sysctl params, these persist across reboots

```
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
```

1. apply sysctl params

```bash
sudo sysctl --system
```

1. install containerd

```bash
sudo apt-get update && sudo apt-get install -y containerd
```

1. configure containerd

```bash
sudo mkdir -p /etc/containerd && containerd config default | sudo tee /etc/containerd/config.toml
```

1. restart containerd

```bash
sudo systemctl restart containerd
```

script:

```bash
#!/bin/bash
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
sudo modprobe overlay && sudo modprobe br_netfilter
cat <<EOF | sudo tee /etc/sysctl.d/99-kubernetes-cri.conf
net.bridge.bridge-nf-call-iptables  = 1
net.ipv4.ip_forward                 = 1
net.bridge.bridge-nf-call-ip6tables = 1
EOF
sudo sysctl --system
sudo apt-get update && sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd && containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
echo $(systemctl status containerd)
```

### install kubelet, kubeadm, kubectl (on each node):

1. update apt package index and install prerequisite packages needed

```bash
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
```

1. download the Google Cloud public signing key:

```bash
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
```

1. add kubernetes app repository

```bash
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

1. update apt package index and install packages

```bash
sudo apt-get update && \
sudo apt-get install -y kubelet kubeadm kubectl && \
sudo apt-mark hold kubelet kubeadm kubectl
```

script:

```bash
#!/bin/bash
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet kubeadm kubectl 
sudo apt-mark hold kubelet kubeadm kubectl
echo $(systemctl status kubelet)
```

code=exited, status=1/FAILURE is expected as kubelet waits for kubeadm init to initialize the cluster

### initialize cluster:

```bash
sudo kubeadm init
```

1. [init] ← identifies which version of kubernetes to use
2. [preflight] ← pulls images for kubernetes components
3. [certs] >- creates /etc/kubernetes/pki with:
- kubernetes root CA and key, apiserver cert and key
- apiserver cert and key
- apiserver-kubelet-client - client cert and key for apiserver to authorize against kubelet
- front-proxy-ca, front-proxy-client
- etcd/ca, etcd/server, etcd/peer, etcd/healthcheck-client
- apiserver-etcd-client
- sa - service account cert and key used by kubeapi pod
1. [kubeconfig] ← save kubeconfigs for admin, kubelet, controller-manager, scheduler
2. [kubelet-start] ← generating kubelet config /var/lib/kubelet/config.yaml and starting kubelet service
3. [control-plane] ← creating pods from /etc/kubernetes/manifests
4. [etcd] generating pod manifest for etcd into /etc/kubernetes/manifests
5. [wait-control-plane] ← awaiting pods from /etc/kubernetes/manifests to boot up
6. [apiclient] ← acknowledgement of control plane components being healthy
7. [upload-config] ← creating kubeadm-config cm in kube-system ns
8. [kubelet] ← creating cm kubelet-config in kube-system ns from [kubelet-start] file
9. [mark-control-plane] ← marking the node master as control-plane by adding the labels: [[node-role.kubernetes.io/master(deprecated)](http://node-role.kubernetes.io/master(deprecated)) [node-role.kubernetes.io/control-plane](http://node-role.kubernetes.io/control-plane) [node.kubernetes.io/exclude-from-external-load-balancers](http://node.kubernetes.io/exclude-from-external-load-balancers)], marking the node master as control-plane by adding the taints [[node-role.kubernetes.io/master:NoSchedule](http://node-role.kubernetes.io/master:NoSchedule)]
10. 

[bootstrap-token] Using token: heftyz.vini4th4wtzlr2pi
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace

1. [kubelet-finalize] ← generate /etc/kubernetes/kubelet.conf kubeconfig
2. [addons] ← adding CoreDNS, kube-proxy addons (these are regular pods)

add default admin user:

```bash
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

### install cni plugin/addon

[https://kubernetes.io/docs/concepts/cluster-administration/addons/](https://kubernetes.io/docs/concepts/cluster-administration/addons/)

for weave port 6783 port needs to be open

```bash
wget https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n') -O ~/weave.yaml
kubectl apply -f ~/weave.yaml
```

### print command for joining cluster for worker nodes

```bash
kubeadm token create --print-join-command
kubeadm join 164.92.234.78:6443 --token jponsi.9ay64qb1iyhps7zc --discovery-token-ca-cert-hash sha256:1e129afc3a6f06d34bfc1cee019f258f56b3416807b72fe90a51df173b259fdd
```

add kubectl completion for bash:

```bash
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
```