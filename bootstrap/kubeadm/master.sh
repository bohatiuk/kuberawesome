#!/bin/bash

echo "--preflight checks"
grep -i ubuntu /etc/issue
if [ $? -ne 0 ]; then echo "ubuntu only supported"; exit 1; fi
version=$1
if [ -z "$version" ]; then version="latest"; echo "kubernetes version not supplied, using latest"; fi
echo "kubernetes version $version-00 will be installed"
echo "preflight checks--"

echo "--disabling swap"
swapoff -a
echo "disabling swap--"

echo "--installing cointainerd"
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
sudo apt-get update
sudo apt-get install -y containerd
sudo mkdir -p /etc/containerd
containerd config default | sudo tee /etc/containerd/config.toml
sudo systemctl restart containerd
echo "installing cointainerd--"

echo "--containerd status"
echo $(systemctl status containerd)
echo "containerd status--"

echo "--installing kubelet, kubeadmin, kubectl @$version"
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
sudo apt-get install -y kubelet="$version-00" kubeadm="$version-00" kubectl="$version-00"
sudo apt-mark hold kubelet kubeadm kubectl
echo "installing kubelet, kubeadmin, kubectl--"

echo "--initializing cluster"
sudo kubeadm init
echo "initializing cluster--"

echo "--saving default admin user kubeconfig to $HOME/.kube"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "saving default admin user kubeconfig--"

echo "--installing weave-net CNI plugin"
echo "note: incoming port 6783 must be opened"
wget https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n') -O ~/weave.yaml
kubectl apply -f ~/weave.yaml

echo "check status of weave via:"
echo "kubectl exec -n kube-system WEAVE_MASTER weave -- /home/weave/weave --local status"
echo "installing weave-net CNI plugin--"

echo "--adding bash completion"
source <(kubectl completion bash)
echo "source <(kubectl completion bash)" >> ~/.bashrc
echo "adding bash completion--"

echo "--getting join command for worker"
kubeadm token create --print-join-command
echo "getting join command for worker--"


