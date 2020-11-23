#!/bin/bash
set -e
set -o pipefail

export KUBECONFIG=/tmp/kubeconfig-admin.yml
SERVICE_ACCOUNT_NAME=$(hostname)
NAMESPACE=$(hostname)
KUBECFG_FILE_NAME="/tmp/kubeconfig.yaml"
TARGET_FOLDER="/tmp"

create_target_folder() {
    echo -n "Creating target directory to hold files in ${TARGET_FOLDER}..."
    mkdir -p "${TARGET_FOLDER}"
    printf "done"
}

create_namespace() {
    echo -n "Creating namespace ${NAMESPACE}..."
    kubectl create namespace ${NAMESPACE}
}

create_service_account() {
    echo -e "\\nCreating a service account in ${NAMESPACE} namespace: ${SERVICE_ACCOUNT_NAME}"
    kubectl create sa "${SERVICE_ACCOUNT_NAME}" --namespace "${NAMESPACE}"
}

create_role_rolebinding() {
    echo -e "\\nCreating a Role and Rolebinding"

    kubectl create role --namespace "${NAMESPACE}"  "${SERVICE_ACCOUNT_NAME}-full-access" --verb=* --resource=*

    kubectl patch role --namespace "${NAMESPACE}"  "${SERVICE_ACCOUNT_NAME}-full-access" --patch '{"rules": [{"apiGroups": ["", "extensions", "apps"],"resources": ["*"],"verbs": ["*"]},{"apiGroups": ["batch"],"resources": ["cron","cronjobs"],"verbs": ["*"]}]}'

    kubectl create rolebinding --namespace "${NAMESPACE}" "${SERVICE_ACCOUNT_NAME}-user" --role="${SERVICE_ACCOUNT_NAME}-full-access" --serviceaccount="${NAMESPACE}:${SERVICE_ACCOUNT_NAME}"

    # clusterrolebindings
    kubectl create clusterrole  "${SERVICE_ACCOUNT_NAME}-read-access" --verb=get,list,watch --resource="*"
    kubectl create clusterrolebinding --namespace "${NAMESPACE}" "${SERVICE_ACCOUNT_NAME}-user-read-access" --clusterrole="${SERVICE_ACCOUNT_NAME}-read-access" --serviceaccount="${NAMESPACE}:${SERVICE_ACCOUNT_NAME}"

}

get_secret_name_from_service_account() {
    echo -e "\\nGetting secret of service account ${SERVICE_ACCOUNT_NAME} on ${NAMESPACE}"
    SECRET_NAME=$(kubectl get sa "${SERVICE_ACCOUNT_NAME}" --namespace="${NAMESPACE}" -o json | jq -r .secrets[].name)
    echo "Secret name: ${SECRET_NAME}"
}

extract_ca_crt_from_secret() {
    echo -e -n "\\nExtracting ca.crt from secret..."
    kubectl get secret --namespace "${NAMESPACE}" "${SECRET_NAME}" -o json | jq \
    -r '.data["ca.crt"]' | base64 --decode > "${TARGET_FOLDER}/ca.crt"
    printf "done"
}

get_user_token_from_secret() {
    echo -e -n "\\nGetting user token from secret..."
    USER_TOKEN=$(kubectl get secret --namespace "${NAMESPACE}" "${SECRET_NAME}" -o json | jq -r '.data["token"]' | base64 --decode)
    printf "done"
}

set_kube_config_values() {
    context=$(kubectl config current-context)
    echo -e "\\nSetting current context to: $context"

    CLUSTER_NAME=$(kubectl config get-contexts "$context" | awk '{print $3}' | tail -n 1)
    echo "Cluster name: ${CLUSTER_NAME}"

    ENDPOINT=$(kubectl config view \
    -o jsonpath="{.clusters[?(@.name == \"${CLUSTER_NAME}\")].cluster.server}")
    echo "Endpoint: ${ENDPOINT}"

    # Set up the config
    echo -e "\\nPreparing k8s-${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-conf"
    echo -n "Setting a cluster entry in kubeconfig..."
    kubectl config set-cluster "${CLUSTER_NAME}" \
    --kubeconfig="${KUBECFG_FILE_NAME}" \
    --server="${ENDPOINT}" \
    --certificate-authority="${TARGET_FOLDER}/ca.crt" \
    --embed-certs=true

    echo -n "Setting token credentials entry in kubeconfig..."
    kubectl config set-credentials \
    "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
    --kubeconfig="${KUBECFG_FILE_NAME}" \
    --token="${USER_TOKEN}"

    echo -n "Setting a context entry in kubeconfig..."
    kubectl config set-context \
    "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
    --kubeconfig="${KUBECFG_FILE_NAME}" \
    --cluster="${CLUSTER_NAME}" \
    --user="${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
    --namespace="${NAMESPACE}"

    echo -n "Setting the current-context in the kubeconfig file..."
    kubectl config use-context "${SERVICE_ACCOUNT_NAME}-${NAMESPACE}-${CLUSTER_NAME}" \
    --kubeconfig="${KUBECFG_FILE_NAME}"
}

set +e

create_target_folder
create_namespace
create_service_account
create_role_rolebinding
get_secret_name_from_service_account
extract_ca_crt_from_secret
get_user_token_from_secret
set_kube_config_values

echo -e "\\nAll done! Test with:"
echo "KUBECONFIG=${KUBECFG_FILE_NAME} kubectl get pods"
echo "you should not have any permissions by default - you have just created the authentication part"
echo "You will need to create RBAC permissions"
# KUBECONFIG=${KUBECFG_FILE_NAME} kubectl get pods
