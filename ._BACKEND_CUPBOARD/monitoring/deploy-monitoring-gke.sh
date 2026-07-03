#!/usr/bin/env bash
set -euo pipefail

NAMESPACE=monitoring
PROM_HELM_RELEASE=prometheus
GRAFANA_ADMIN_PASSWORD=admin
PROM_OPERATOR_CHART=prometheus-community/kube-prometheus-stack

echo "1) Create namespace"
kubectl apply -f monitoring/k8s/namespace.yaml

echo "2) Ensure Helm repo is present"
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update

if ! helm status ${PROM_HELM_RELEASE} -n ${NAMESPACE} >/dev/null 2>&1; then
  echo "3) Installing Prometheus Operator into namespace ${NAMESPACE}"
  helm install ${PROM_HELM_RELEASE} ${PROM_OPERATOR_CHART} --namespace ${NAMESPACE} --create-namespace \
    --set grafana.adminPassword=${GRAFANA_ADMIN_PASSWORD} \
    --wait
else
  echo "Prometheus Operator release ${PROM_HELM_RELEASE} already installed in ${NAMESPACE}"
fi

echo "4) Apply Service and ServiceMonitor manifests"
kubectl apply -f monitoring/k8s/service-backend-metrics.yaml
kubectl apply -f monitoring/k8s/servicemonitor-backend.yaml
kubectl apply -f monitoring/k8s/prometheus-secret.yaml || true

echo "5) Wait for ServiceMonitor to be visible"
sleep 5
for i in {1..24}; do
  if kubectl -n ${NAMESPACE} get servicemonitor >/dev/null 2>&1; then
    echo "ServiceMonitor present."
    break
  fi
  sleep 5
done

echo "6) Port-forward Grafana and Prometheus for quick validation (background)"
GRAFANA_SVC=$(kubectl -n ${NAMESPACE} get svc -l app.kubernetes.io/name=grafana -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")
PROM_SVC=$(kubectl -n ${NAMESPACE} get svc -l app.kubernetes.io/name=prometheus -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || echo "")

if [[ -n "${GRAFANA_SVC}" ]]; then
  kubectl -n ${NAMESPACE} port-forward svc/${GRAFANA_SVC} 3000:80 >/dev/null 2>&1 &
  echo "Grafana port-forwarded to http://localhost:3000 (admin:${GRAFANA_ADMIN_PASSWORD})"
fi

if [[ -n "${PROM_SVC}" ]]; then
  kubectl -n ${NAMESPACE} port-forward svc/${PROM_SVC} 9090:9090 >/dev/null 2>&1 &
  echo "Prometheus port-forwarded to http://localhost:9090"
fi

echo "Done. Inspect Prometheus and Grafana, then import dashboards and verify targets."
