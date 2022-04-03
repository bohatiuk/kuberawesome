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
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/addons/kiali.yaml
</code>

metallb

<code>
helm install metallb metallb/metallb -f metallb.yaml

</code>

<code>
helm repo add istio https://istio-release.storage.googleapis.com/charts
helm repo update
helm install istio-base istio/base -n istio-system --create-namespace
helm install istiod istio/istiod -n istio-system --wait
helm install istio-ingress istio/gateway -n istio-ingress --create-namespace
</code>

<code>
helm install \
  --namespace istio-system \
  --set auth.strategy="anonymous" \
  --repo https://kiali.org/helm-charts \
  kiali \
  kiali-server
</code>

easy install propmetheus, grafana, jaeger
<code>
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/addons/prometheus.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/addons/grafana.yaml
kubectl apply -f https://raw.githubusercontent.com/istio/istio/release-1.13/samples/addons/jaeger.yaml
</code>

TBD
<code>
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts 
helm repo update
helm install prometheus-grafana prometheus-community/kube-prometheus-stack --namespace istio-system --set namespaceOverride=istio-system

</code>
