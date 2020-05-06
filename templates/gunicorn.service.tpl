[Unit]
Description=Gunicorn instance to serve ctfd
Requires=gunicorn.socket
After=network.target

[Service]
Type=notify
User=${SERVICE_USER}
Group=${SERVICE_GROUP}
WorkingDirectory=${CTFD_DIR}
ExecStart=${SCRIPTS_DIR}/gunicorn.sh
ExecReload=/bin/kill -s HUP $MAINPID
KillMode=mixed
TimeoutStopSec=5
PrivateTmp=true
TimeoutStartSec=120


[Install]
WantedBy=multi-user.target