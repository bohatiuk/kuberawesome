<h1>Standalone mode</h1>

<h2>master node</h2>

<code>
wget https://github.com/bohatiuk/kuberawesome/blob/main/bootstrap/kubeadm/standalone/master.sh -O ~/install.sh

~/install.sh 1.23.0-00
</code>

if script is ran without version parameter then the latest version will be used

<h2>worker node</h2>

On the stage "getting join command for worker" join command will be printed out which can be used like this

<code>
wget https://github.com/bohatiuk/kuberawesome/blob/main/bootstrap/kubeadm/worker.sh -O ~/install.sh

KUBEADM_JOIN_COMMAND="kubeadm join ENDPOINT --token TOKEN --discovery-token-ca-cert-hash CA_HASH" ~/install.sh 1.23.0-00
</code>

<h1>HA mode</h1>
<h2>master node</h2>

<code>
wget https://github.com/bohatiuk/kuberawesome/blob/main/bootstrap/kubeadm/ha/master_init.sh -O ~/install.sh

LB_ENDPOINT="1.1.1.1:6443" ~/install.sh 1.23.0-00
</code>

KUBEADM_JOIN_COMMAND will be outputed on "initializing cluster" stage

<h2>other master nodes</h2>

<code>
wget https://github.com/bohatiuk/kuberawesome/blob/main/bootstrap/kubeadm/ha/master_join.sh -O ~/install.sh

KUBEADM_JOIN_COMMAND="kubeadm join ENDPOINT --token TOKEN --discovery-token-ca-cert-hash CA_HASH  --control-plane --certificate-key KEY" ~/install.sh 1.23.0-00
</code>

<h2>worker node</h2>

<code>
wget https://github.com/bohatiuk/kuberawesome/blob/main/bootstrap/kubeadm/worker.sh -O ~/install.sh

KUBEADM_JOIN_COMMAND="kubeadm join ENDPOINT --token TOKEN --discovery-token-ca-cert-hash CA_HASH" ~/install.sh 1.23.0-00
</code>
