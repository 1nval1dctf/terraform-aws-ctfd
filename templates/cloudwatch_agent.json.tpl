{
  "metrics": {
    "aggregation_dimensions": [
      ["InstanceId"],
      ["AutoScalingGroupName"]
    ],
    "append_dimensions": {
      "AutoScalingGroupName": "$${aws:AutoScalingGroupName}",
      "InstanceId": "$${aws:InstanceId}"
    },
    "metrics_collected": {
      "cpu": {
        "measurement": [
          "cpu_usage_idle",
          "cpu_usage_iowait",
          "cpu_usage_user",
          "cpu_usage_system"
        ],
        "metrics_collection_interval": 60,
        "resources": ["*"],
        "totalcpu": true
      },
      "disk": {
        "measurement": [
          "used_percent",
          "inodes_free"
        ],
        "metrics_collection_interval": 60,
        "resources": ["/"]
      },
      "diskio": {
        "measurement": [
          "io_time"
        ],
        "metrics_collection_interval": 60,
        "resources": ["/"]
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
            "file_path": "/var/log/nginx/access.log",
            "log_group_name": "/CTFd/{instance_id}/nginx/logs",
            "log_stream_name": "access.log",
            "timestamp_format": "[%d/%b/%Y:%H:%M:%S %z]"
          },
          {
            "file_path": "/var/log/nginx/error.log",
            "log_group_name": "/CTFd/{instance_id}/nginx/logs",
            "log_stream_name": "error.log",
            "timestamp_format": "[%d/%b/%Y:%H:%M:%S %z]"
          },
          {
            "file_path": "${ACCESS_LOG}",
            "log_group_name": "/CTFd/{instance_id}/gunicorn/logs",
            "log_stream_name": "access.log",
            "timestamp_format": "[%Y-%b-%d %H:%M:%S %z]"
          },
          {
            "file_path": "${ERROR_LOG}",
            "log_group_name": "/CTFd/{instance_id}/gunicorn/logs",
            "log_stream_name": "error.log",
            "timestamp_format": "[%Y-%b-%d %H:%M:%S %z]"
          }
        ]
      }
    },
    "log_stream_name": "/CTFd/{instance_id}",
    "force_flush_interval" : 15
  }
}