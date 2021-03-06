#!/bin/bash
set -e

key=$1
slice=$2
tarfile=$3
environment=$4

echo "DEPLOY Deploying $3 to $2 using key $1"

echo "DEPLOY stopping server HELLO"

(./stop.sh $key $slice || echo 'DEPLOY Could not stop server')

echo "DEPLOY Checking for running start-local.py"

# Only bail if there is still a process around
set +e
pid=`ssh $SSH_OPTS -i "$key" ubuntu@$slice pgrep -f start-local.py`
set -e

echo "pid: $pid"
if [ -n "$pid" ]
    then
    echo "DEPLOY ERROR There is still a server process around"; exit 1
fi

echo "DEPLOY Starting to copy files"


ssh $SSH_OPTS -i "$key" ubuntu@$slice 'rm -rf ~/one-click-cd-demo'
ssh $SSH_OPTS -i "$key" ubuntu@$slice 'mkdir ~/one-click-cd-demo'
scp $SSH_OPTS -i "$key" dist/$tarfile ubuntu@$slice:~/one-click-cd-demo
ssh $SSH_OPTS -i "$key" ubuntu@$slice "cd ~/one-click-cd-demo && tar xfz $tarfile && sudo mv ~/one-click-cd-demo/server-scripts/one-click-cd-demo /etc/init.d/ && sudo update-rc.d one-click-cd-demo defaults"
ssh $SSH_OPTS -i "$key" ubuntu@$slice "cd ~/one-click-cd-demo && sed -i -e 's/\${ENV}/$environment/g' static/*html"

echo "DEPLOY starting server"
./start.sh $key $slice
