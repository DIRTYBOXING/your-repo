#!/usr/bin/env bash
set -euo pipefail

echo "1) Docker version"
docker version || { echo "docker CLI/daemon not available"; exit 2; }

echo
echo "2) Docker info (summary)"
docker info --format 'Server={{.ServerVersion}} OS={{.OperatingSystem}} Arch={{.Architecture}} Cgroup={{.CgroupDriver}}'

echo
echo "3) Running containers"
docker ps --format 'table {{.Names}}\t{{.Status}}\t{{.Image}}'

echo
echo "4) Critical containers"
missing=0
for c in ws-gateway feed-service entitlement media-ingest; do
  if docker ps --filter "name=${c}" --format '{{.Names}}' | grep -q "${c}"; then
    echo "OK ${c}"
  else
    echo "MISSING ${c}"
    missing=1
  fi
done

echo
echo "5) Disk usage"
docker system df

echo
if [[ "$missing" == "1" ]]; then
  echo "Docker health completed with missing critical containers"
  exit 1
fi

echo "Docker health check completed"
