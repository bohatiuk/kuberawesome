<h2>Initialize master node from master.sh script</h2>

<code>./master.sh $VERSION</code>

$VERSION can be any valid package version in the format X.Y.Z-A

if script is ran without this parameter then latest version will be used

<h2>Initialize worker nodes from worker.sh script</h2>

On the stage "getting join command for worker" join command will be printed out which can be used 
with 

<code>KUBEADM_JOIN_COMMAND=$COMMAND ./worker.sh $VERSION</code>