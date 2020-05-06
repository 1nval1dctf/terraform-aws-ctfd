[Unit]
Description=gunicorn socket

[Socket]
ListenStream=/run/gunicorn.sock
User=${SERVICE_USER}

[Install]
WantedBy=sockets.target