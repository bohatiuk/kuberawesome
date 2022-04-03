<code>
kind create cluster --config cluster.yaml
</code>

metrics server

<code>
helm upgrade --install --namespace kube-system metrics-server bitnami/metrics-server --set apiService.create=true --set extraArgs.kubelet-insecure-tls=true --set extraArgs.kubelet-preferred-address-types=InternalIP
</code>

nginx ingress controller

<code>
kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/main/deploy/static/provider/kind/deploy.yaml
</code>

metallb

<code>
helm install metallb metallb/metallb -f metallb.yaml

</code>