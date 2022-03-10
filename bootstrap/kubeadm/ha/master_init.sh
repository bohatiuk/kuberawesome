#!/bin/bash

ERR=`tput setaf 1`
TXT=`tput setaf 2`
WARN=`tput setaf 3`
RST=`tput sgr0`
PORTS="                             
6443 -> kubernetes API server       
2379-2380 -> etcd server client API 
10250 -> kubelet API                
10259 -> kube-scheduler             
10257 -> kube-controller-manager    
6783 -> weave CNI                   
"

echo "$TXT--preflight checks$RST"
echo "OS:"
grep -i ubuntu /etc/issue
if [ $? -ne 0 ]; then echo "${ERR}--ubuntu only supported--$RST"; exit 1; fi
echo "${WARN}--following inbound ports must be open on the node$RST"
echo "$PORTS"
echo "${WARN}following inbound ports must be open on the node--$RST"
version="$1"
if [ -z "$1" ]; then version="latest"; echo "--${WARN}kubernetes version not supplied, using latest--$RST"; fi
if [ -z "$LB_ENDPOINT" ]; then echo "${ERR}--LB_ENDPOINT not specified--$RST"; exit 1; fi
echo "${WARN}--installing net utils${RST}"
sudo apt-get install -y net-tools
echo "${WARN}installing net utils--${RST}"
echo "preflight checks--$RST"

echo "$TXT--disabling swap$RST"
swapoff -a
echo "${TXT}disabling swap--$RST"

echo "$TXT--installing cointainerd$RST"
cat <<EOF | sudo tee /etc/modules-load.d/containerd.conf
overlay
br_netfilter
EOF
echo "\n"
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
echo "${TXT}installing cointainerd--$RST"

echo "$TXT--containerd status$RST"
echo $(systemctl status containerd)
echo "${TXT}containerd status--$RST"

echo "$TXT--installing kubelet, kubeadm, kubectl $RST"
sudo apt-get update && sudo apt-get install -y apt-transport-https ca-certificates curl jq
sudo curl -fsSLo /usr/share/keyrings/kubernetes-archive-keyring.gpg https://packages.cloud.google.com/apt/doc/apt-key.gpg
echo "deb [signed-by=/usr/share/keyrings/kubernetes-archive-keyring.gpg] https://apt.kubernetes.io/ kubernetes-xenial main" | sudo tee /etc/apt/sources.list.d/kubernetes.list
sudo apt-get update
if [ "$version" = "latest" ]; then version=$(apt list -a | grep kubeadm | cut -d" " -f2 | head -n 1); fi
sudo apt-get install -y kubelet="$version" kubeadm="$version" kubectl="$version"
sudo apt-mark hold kubelet kubeadm kubectl
echo "${TXT}installing kubelet, kubeadm, kubectl @$version--$RST"

echo "$TXT--initializing cluster$RST"
sudo kubeadm init --control-plane-endpoint="$LB_ENDPOINT" --upload-certs --pod-network-cidr=10.244.0.0/16
echo "${TXT}initializing cluster--$RST"

echo "$TXT--saving default admin user kubeconfig to $HOME/.kube$RST"
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
echo "${TXT}saving default admin user kubeconfig--$RST"

echo "$TXT--installing weave-net CNI plugin$RST"
wget https://cloud.weave.works/k8s/net?k8s-version=$(kubectl version | base64 | tr -d '\n') -O ~/weave.yaml
kubectl apply -f ~/weave.yaml

echo "check status of weave via:"
echo "kubectl exec -n kube-system WEAVE_MASTER weave -- /home/weave/weave --local status"
echo "${WARN}--see: https://www.weave.works/docs/net/latest/troubleshooting--${RST}"
echo "installing weave-net CNI plugin--$RST"