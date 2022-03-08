<h2>Initialize master node from master.sh script</h2>

<code>./master.sh $VERSION</code>

$VERSION can be any valid package version in the format X.Y.Z-A

if script is ran without this parameter then latest version will be used

<h2>Initialize worker nodes from worker.sh script</h2>

On the stage "getting join command for worker" join command will be printed out which can be used like this

<code>KUBEADM_JOIN_COMMAND=$COMMAND ./worker.sh $VERSION</code>

<h3>Notes</h3>

Only 1 master any workers setup is supported. To join another master node:
https://stackoverflow.com/questions/51126164/how-do-i-find-the-join-command-for-kubeadm-on-the-master