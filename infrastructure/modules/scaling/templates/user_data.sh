#!/bin/bash

# Configurar el nombre del host
INSTANCE_ID=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
hostnamectl set-hostname "${environment}-$INSTANCE_ID"

# Instalar CloudWatch Agent
yum install -y amazon-cloudwatch-agent

# Configurar CloudWatch Agent
cat > /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json << 'EOF'
{
  "agent": {
    "metrics_collection_interval": 60,
    "run_as_user": "root"
  },
  "metrics": {
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "totalcpu": false
      },
      "disk": {
        "measurement": [
          "used_percent",
          "inodes_free"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "diskio": {
        "measurement": [
          "io_time"
        ],
        "metrics_collection_interval": 60,
        "resources": [
          "*"
        ]
      },
      "mem": {
        "measurement": [
          "mem_used_percent"
        ],
        "metrics_collection_interval": 60
      },
      "swap": {
        "measurement": [
          "swap_used_percent"
        ],
        "metrics_collection_interval": 60
      }
    }
  },
  "logs": {
    "logs_collected": {
      "files": {
        "collect_list": [
          {
            "file_path": "/var/log/messages",
            "log_group_name": "/aws/ec2/${environment}/system",
            "log_stream_name": "{instance_id}-system",
            "timestamp_format": "%b %d %H:%M:%S"
          },
          {
            "file_path": "/var/log/secure",
            "log_group_name": "/aws/ec2/${environment}/secure",
            "log_stream_name": "{instance_id}-secure",
            "timestamp_format": "%b %d %H:%M:%S"
          }
        ]
      }
    }
  }
}
EOF

# Iniciar CloudWatch Agent
systemctl enable amazon-cloudwatch-agent
systemctl start amazon-cloudwatch-agent

# Instalar herramientas de monitoreo
yum install -y htop iotop

# Configurar zona horaria
timedatectl set-timezone America/Bogota

# Configurar NTP
yum install -y chrony
systemctl enable chronyd
systemctl start chronyd

# Configurar límites del sistema
cat > /etc/security/limits.d/custom.conf << EOF
* soft nofile 65536
* hard nofile 65536
* soft nproc 65536
* hard nproc 65536
EOF

# Configurar sysctl
cat > /etc/sysctl.d/99-custom.conf << EOF
net.ipv4.tcp_max_syn_backlog = 65536
net.core.somaxconn = 65536
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_max_tw_buckets = 1440000
net.ipv4.tcp_fin_timeout = 15
net.ipv4.tcp_window_scaling = 1
net.ipv4.tcp_keepalive_time = 300
net.ipv4.tcp_keepalive_probes = 5
net.ipv4.tcp_keepalive_intvl = 15
EOF

sysctl -p /etc/sysctl.d/99-custom.conf

# Script de monitoreo personalizado
cat > /usr/local/bin/custom-metrics.sh << 'EOF'
#!/bin/bash

while true; do
  # Obtener métricas de memoria
  MEMORY_USED_PCT=$(free | grep Mem | awk '{print $3/$2 * 100.0}')
  
  # Enviar métricas a CloudWatch
  aws cloudwatch put-metric-data \
    --namespace AWS/EC2 \
    --metric-name MemoryUtilization \
    --value $MEMORY_USED_PCT \
    --unit Percent \
    --dimensions AutoScalingGroupName=$(curl -s http://169.254.169.254/latest/meta-data/tags/instance/aws:autoscaling:groupName) \
    --region ${region}
    
  sleep 60
done
EOF

chmod +x /usr/local/bin/custom-metrics.sh

# Crear servicio systemd para el script de monitoreo
cat > /etc/systemd/system/custom-metrics.service << EOF
[Unit]
Description=Custom Metrics Collection
After=network.target

[Service]
ExecStart=/usr/local/bin/custom-metrics.sh
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl enable custom-metrics
systemctl start custom-metrics 