#!/bin/bash

if [ "$(id -u)" -ne 0 ]; then
    echo "This script must be run with administrator/root privileges. Please use sudo:"
    echo "sudo ./start.sh"
    exit 1
fi

STACKFLOW_CURRENT_VERSION="0.0.3"

RED='\e[31m'
GREEN='\e[32m'
YELLOW='\e[33m'
BLUE='\e[34m'
CYAN='\e[36m'

NC='\e[0m'

HELP_MESSAGE="
Welcome to ${CYAN}StackFlow Control Plane${NC} v$STACKFLOW_CURRENT_VERSION.
Type ".help" for more information.

Usage:
    stackflow help                                show this message.
    stackflow start                               start the cluter kubernetes and interface web stackflow.
    stackflow delete [<cluster name>]             delete the cluter kubernetes and stop interface web stackflow.
"

start() {
    echo "cluster name:"
    read CLUSTER_NAME

    echo "user name: "
    read USER_NAME

    echo "password: "
    read PASSWORD

    echo "ambient: "
    read AMBIENT

    echo ""

    cd /opt/stackflow

    HOST_KUBE_API="127.0.0.1"
    HOST_KUBE_API_PORT="6550"

    #execute k3d 
    echo "
    apiVersion: k3d.io/v1alpha5
    kind: Simple # internally, we also have a Cluster config, which is not yet available externally
    metadata:
        name: mycluster
    servers: 1
    agents: 2 
    kubeAPI: 
        host: \"$HOST_KUBE_API\"
        hostIP: \"$HOST_KUBE_API\"
        hostPort: \"$HOST_KUBE_API_PORT\"
    " > /opt/stackflow/config.yaml

    #configure cluster
    echo "configuring cluster $CLUSTER_NAME..."
    k3d cluster create $CLUSTER_NAME --config /opt/stackflow/config.yaml > /dev/null 2>&1
    kubectl config use-context k3d-$CLUSTER_NAME > /dev/null 2>&1
    kubectl create serviceaccount -n default admin > /dev/null 2>&1
    kubectl create clusterrolebinding -n default admin --clusterrole cluster-admin --serviceaccount=default:admin > /dev/null 2>&1
    echo "configurited cluster."

    echo ""

    #start cloud deploy project
    echo "starting project cloud deploy..."
    echo -e "JWT_SECRET=$PASSWORD \nMEMORY_NAME=sda1 \nSTACKFLOW_USER_NAME=$USER_NAME \nSTACKFLOW_PASSWORD=$PASSWORD \nNEXT_PUBLIC_ENVIRONMENT=$AMBIENT \nNEXT_PUBLIC_CLUSTER_NAME=$CLUSTER_NAME \nCLUSTER_NAME=$CLUSTER_NAME \nCLUSTER_SERVER=http://$HOST_KUBE_API:$HOST_KUBE_API_PORT \nTOKEN_SERVICE_ACCOUNT_CLUSTER=$(kubectl create token admin)" > .env
    npm run build > /dev/null 2>&1
    pm2 delete "pedreiro web" > /dev/null 2>&1
    pm2 start ecosystem.config.js --env production > /dev/null 2>&1

    #apply migrations
    node --no-warnings --env-file=.env migrations/migration_user.ts  > /dev/null 2>&1
    node --no-warnings --env-file=.env migrations/migration_log.ts > /dev/null 2>&1

    echo "stackflow started in http://localhost:3000."
    echo ""
}

delete() {
    CLUSTER_NAME=$1

    if [ "$CLUSTER_NAME" = "" ]
    then
        echo "input name of cluster."
        exit 1
    fi

    echo "deleting cluster ..."
    kubectl delete serviceaccount admin > /dev/null 2>&1 
    kubectl delete clusterrolebinding -n default admin > /dev/null 2>&1 
    k3d cluster delete $CLUSTER_NAME > /dev/null 2>&1 
    pm2 stop "pedreiro web" > /dev/null 2>&1

    echo "deleted cluster."
}

COMMAND=$1

if [ "$COMMAND" = "start" ]
then
    start
    exit 1
fi

if [ "$COMMAND" = "delete" ]
then
    delete $2
    exit 1
fi

if [ "$COMMAND" = "help" ]
then
    echo -e "$HELP_MESSAGE"
    exit 1
fi

echo -e "$HELP_MESSAGE"