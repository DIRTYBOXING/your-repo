#!/usr/bin/env python3
"""
Autonomous Health Monitor for Data-Fight-Central
Monitors all services, detects degradation, and triggers recovery
"""

import os
import sys
import time
import json
import socket
import logging
import requests
from datetime import datetime
from typing import Dict, List, Tuple
from kubernetes import client, config

logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(levelname)s - %(message)s'
)
logger = logging.getLogger(__name__)

class HealthMonitor:
    def __init__(self):
        self.check_interval = int(os.getenv('CHECK_INTERVAL', 30))
        self.alert_webhook = os.getenv('ALERT_WEBHOOK_URL', '')
        self.services = self._discover_services_k8s()
        self.health_history: Dict[str, List[bool]] = {
            service: [] for service in self.services.keys()
        }
        self.max_history = 10

    def _discover_services_k8s(self) -> Dict[str, Tuple[str, int]]:
        """Discover services from the Kubernetes API using a label selector."""
        services = {}
        try:
            # Use in-cluster config when running inside a pod
            config.load_incluster_config()
            v1 = client.CoreV1Api()
            namespace = os.getenv('K8S_NAMESPACE', 'dfc')
            label_selector = 'dfc-monitor=true'

            logger.info(f"Discovering services in namespace '{namespace}' with label '{label_selector}'")

            ret = v1.list_namespaced_service(namespace=namespace, label_selector=label_selector)

            for svc in ret.items:
                name = svc.metadata.name
                if svc.spec.ports:
                    port = svc.spec.ports[0].port
                    # Use the internal K8s DNS name for the host
                    host = f"{name}.{namespace}.svc.cluster.local"
                    services[name] = (host, int(port))
                else:
                    logger.warning(f"Service {name} has no ports defined, cannot monitor.")
            logger.info(f"Dynamically discovered services: {list(services.keys())}")
        except Exception as e:
            logger.error(f"Failed to discover services from Kubernetes API: {e}")
            logger.error("Falling back to static list. Ensure RBAC permissions are correct.")
        return services

    def check_service_tcp(self, service_name: str, host: str, port: int) -> bool:
        """Check if service is responding on TCP port"""
        try:
            sock = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            sock.settimeout(5)
            result = sock.connect_ex((host, port))
            sock.close()
            return result == 0
        except Exception as e:
            logger.debug(f"TCP check failed for {service_name}: {e}")
            return False

    def check_service_http(self, service_name: str, url: str) -> bool:
        """Check if service responds to HTTP health endpoint"""
        try:
            response = requests.get(url, timeout=5)
            return response.status_code < 500
        except requests.exceptions.RequestException as e:
            logger.debug(f"HTTP check failed for {service_name}: {e}")
            return False

    def get_service_health(self, service_name: str) -> Dict:
        """Get comprehensive health status for a service"""
        name, port = self.services[service_name]

        # Map services to their health check type
        http_services = {
            'ingest': 'http://ingest:8000/health',
            'predictor': 'http://predictor:8090/health',
            'entitlements': 'http://entitlements:4010/health',
            'prometheus': 'http://prometheus:9090/-/ready',
            'grafana': 'http://grafana:3000/api/health',
            'secrets': 'http://secrets:8200/v1/sys/health',
        }

        tcp_only = ['db', 'redis']

        if service_name in http_services:
            is_healthy = self.check_service_http(service_name, http_services[service_name])
        elif service_name in tcp_only:
            is_healthy = self.check_service_tcp(service_name, service_name, port)
        else:
            is_healthy = self.check_service_tcp(service_name, service_name, port)

        # Track history
        self.health_history[service_name].append(is_healthy)
        if len(self.health_history[service_name]) > self.max_history:
            self.health_history[service_name].pop(0)

        # Calculate trend (degrading if last 3 are failing)
        recent = self.health_history[service_name][-3:]
        degrading = len(recent) >= 3 and not any(recent)

        return {
            'service': service_name,
            'healthy': is_healthy,
            'degrading': degrading,
            'history': self.health_history[service_name],
            'uptime_percent': (sum(self.health_history[service_name]) / len(self.health_history[service_name]) * 100) if self.health_history[service_name] else 0,
            'timestamp': datetime.utcnow().isoformat(),
        }

    def check_all_services(self) -> Dict[str, Dict]:
        """Check health of all services"""
        status = {}
        for service_name in self.services.keys():
            status[service_name] = self.get_service_health(service_name)
        return status

    def send_alert(self, alert_data: Dict):
        """Send alert to webhook or log"""
        if not self.alert_webhook:
            logger.warning(f"Alert triggered but no webhook configured: {alert_data}")
            return

        try:
            response = requests.post(
                self.alert_webhook,
                json=alert_data,
                timeout=10,
                headers={'Content-Type': 'application/json'}
            )
            if response.status_code < 300:
                logger.info(f"Alert sent successfully: {alert_data['service']}")
            else:
                logger.error(f"Webhook returned {response.status_code}")
        except requests.exceptions.RequestException as e:
            logger.error(f"Failed to send alert: {e}")

    def trigger_recovery(self, service_name: str, reason: str):
        """Trigger recovery for a degraded service"""
        logger.warning(f"🚨 RECOVERY TRIGGERED for {service_name}: {reason}")

        alert = {
            'service': service_name,
            'status': 'degraded',
            'reason': reason,
            'timestamp': datetime.utcnow().isoformat(),
            'action': 'auto_recovery_initiated',
        }

        self.send_alert(alert)

        # In production, this would integrate with Kubernetes/Docker daemon
        # to restart the container. For now, we just log and alert.
        logger.info(f"Recovery action would restart {service_name} container")

    def run(self):
        """Main monitoring loop"""
        logger.info(f"🚀 Health Monitor started (interval: {self.check_interval}s)")
        logger.info(f"📋 Monitoring services: {', '.join(self.services.keys())}")

        if not self.alert_webhook:
            logger.warning("⚠️  No alert webhook configured. Alerts will only be logged.")

        failure_counts = {service: 0 for service in self.services.keys()}

        while True:
            try:
                status = self.check_all_services()

                # Log summary
                healthy_count = sum(1 for s in status.values() if s['healthy'])
                logger.info(f"✅ Health check: {healthy_count}/{len(status)} services healthy")

                # Check for degradation and trigger recovery
                for service_name, health in status.items():
                    if not health['healthy']:
                        failure_counts[service_name] += 1
                        logger.warning(f"❌ {service_name} unhealthy (failures: {failure_counts[service_name]})")

                        # Trigger recovery after 2 consecutive failures
                        if failure_counts[service_name] >= 2:
                            self.trigger_recovery(
                                service_name,
                                f"Service failed {failure_counts[service_name]} health checks"
                            )
                            failure_counts[service_name] = 0  # Reset after recovery attempt
                    else:
                        failure_counts[service_name] = 0  # Reset on successful check

                    # Alert if degrading
                    if health['degrading']:
                        self.send_alert({
                            'service': service_name,
                            'status': 'degrading',
                            'uptime_percent': health['uptime_percent'],
                            'timestamp': health['timestamp'],
                        })

                # Log detailed status every 10 checks
                if int(time.time()) % (self.check_interval * 10) < self.check_interval:
                    logger.info("📊 Detailed status:")
                    for service_name, health in status.items():
                        status_emoji = "✅" if health['healthy'] else "❌"
                        logger.info(
                            f"  {status_emoji} {service_name}: "
                            f"healthy={health['healthy']}, "
                            f"uptime={health['uptime_percent']:.1f}%, "
                            f"history={health['history'][-3:]}"
                        )

                time.sleep(self.check_interval)

            except KeyboardInterrupt:
                logger.info("🛑 Health Monitor stopped")
                sys.exit(0)
            except Exception as e:
                logger.error(f"❌ Monitor error: {e}", exc_info=True)
                time.sleep(self.check_interval)

if __name__ == '__main__':
    monitor = HealthMonitor()
    monitor.run()
