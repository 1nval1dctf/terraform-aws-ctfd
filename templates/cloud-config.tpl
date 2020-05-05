#cloud-config

packages:
 - redis-tools
 - mysql-client
 - gunicorn
 - python3-dev
 - python3-pip
 - nginx

bootcmd:
 - [ mkdir, -p, ${SCRIPTS_DIR} ]

write_files:
-   encoding: b64
    content: ${GUNICORN}
    #owner: ubuntu:www-data
    path: ${SCRIPTS_DIR}/gunicorn.sh
    permissions: '0755'
-   encoding: b64
    content: ${GUNICORN_CONF}
    path: /etc/tmpfiles.d/gunicorn.conf
-   encoding: b64
    content: ${GUNICORN_SERVICE}
    path: /etc/systemd/system/gunicorn.service
-   encoding: b64
    content: ${GUNICORN_SOCKET}
    path: /etc/systemd/system/gunicorn.socket
-   encoding: b64
    content: ${NGINX_CONF}
    path: /etc/nginx/sites-available/ctfd
-   encoding: b64
    content: ${DB_CHECK}
    path: ${SCRIPTS_DIR}/db_check.sh
    permissions: '0755'
-   encoding: b64
    content: ${DB_UPGRADE}
    path: ${SCRIPTS_DIR}/db_upgrade.sh
    permissions: '0755'

runcmd:
 - [ pip3, install, awslogs ]
 - [ git, config, --system, user.name, "cloud-init" ]
 - [ git, config, --system, user.email, "cloud-init@gitlab.com" ]
 # used for nginx cache
 - [ mkdir, /var/nginx ]
 - [ chown, www-data, /var/nginx ]
 - [ mkdir, -p, ${LOG_DIR} ]
 - [ chown, -R, "www-data:www-data", ${LOG_DIR} ]
 # Get ctfd and install requirements
 - [ git, clone, "-b", "${CTFD_VERSION}", "--depth", "1", "https://github.com/CTFd/CTFd.git", ${CTFD_DIR} ]
 - [ pip3, install, -r, ${CTFD_DIR}/requirements.txt ]
 # Check the db is up.
 - [ .${SCRIPTS_DIR}/db_check.sh ]
 # initalise the db.
 - [ .${SCRIPTS_DIR}/db_upgrade.sh ]
 - [ rm, /etc/nginx/sites-enabled/default ]
 - [ rm, /etc/nginx/sites-available/default ]
 - [ ln, -s, /etc/nginx/sites-available/ctfd, /etc/nginx/sites-enabled ]
 - [ systemctl, daemon-reload ]
 - [ systemctl, start, gunicorn.socket ]
 - [ systemctl, enable, gunicorn.socket ]
 - [ systemctl, restart, nginx ]
