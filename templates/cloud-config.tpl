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
 # stop nginx while we set up a few things
 - [ systemctl, stop, nginx ]
 - [ pip3, install, awslogs ]
 - [ git, config, --system, user.name, "cloud-init" ]
 - [ git, config, --system, user.email, "cloud-init@gitlab.com" ]
 # Get ctfd and install requirements
 - [ git, clone, "-b", "${CTFD_VERSION}", "--depth", "1", "https://github.com/CTFd/CTFd.git", ${CTFD_DIR} ]
 - [ pip3, install, -r, ${CTFD_DIR}/requirements.txt ]
 # Set permissions for ctdf and create log dirs
 - [ chown, -R, "${SERVICE_USER}:${SERVICE_GROUP}", ${CTFD_DIR} ]
 - [ mkdir, -p, ${LOG_DIR} ]
 - [ chown, -R, "${SERVICE_USER}:${SERVICE_GROUP}", ${LOG_DIR} ]
 # Check the db is up.
 - [ .${SCRIPTS_DIR}/db_check.sh ]
 # initialise the db.
 - [ .${SCRIPTS_DIR}/db_upgrade.sh ]
 # setup nginx
 - [ rm, /etc/nginx/sites-enabled/default ]
 - [ rm, /etc/nginx/sites-available/default ]
 - [ ln, -s, /etc/nginx/sites-available/ctfd, /etc/nginx/sites-enabled ]
 # used for nginx cache
 - [ mkdir, /var/nginx ]
 - [ chown, ${SERVICE_USER}, /var/nginx ]
 # Setup our services to manage ctfd on demand
 - [ systemctl, daemon-reload ]
 - [ systemctl, start, gunicorn.socket ]
 - [ systemctl, enable, gunicorn.socket ]
 # This will trigger CTFd to start up
 - [ sudo, -u, ${SERVICE_USER}, curl, --unix-socket, /run/gunicorn.sock, http ]
 # start nginx again now that we are ready to serve CTFd
 - [ systemctl, start, nginx ]
