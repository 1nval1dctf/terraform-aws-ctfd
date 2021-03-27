#cloud-config

packages:
 - redis-tools
 - mysql-client
 - gunicorn
 - python3-dev
 - python3-pip
 - nginx
 - unzip
 - curl
 - libxml2-dev
 - libxslt1-dev
 - python3-lxml

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
-   encoding: b64
    content: ${CLOUDWATCH_AGENT}
    path: /opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json

runcmd:
 # stop nginx while we set up a few things
 - [ systemctl, stop, nginx ]
 # Install aws cli
 - [ curl, "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip", -o, "awscliv2.zip" ]
 - [ unzip, -qq, awscliv2.zip ]
 - [ ./aws/install ]
 - [ rm, -rf, aws ]
 - [ rm, awscliv2.zip ]
 # Install cloudwatch agent
 - [ curl, "--location", "https://s3.amazonaws.com/amazoncloudwatch-agent/ubuntu/amd64/latest/amazon-cloudwatch-agent.deb", -o, "amazon-cloudwatch-agent.deb" ]
 - [ dpkg, -i, -E, "amazon-cloudwatch-agent.deb" ]
 # Setup git
 - [ git, config, --system, user.name, "cloud-init" ]
 - [ git, config, --system, user.email, "cloud-init@gitlab.com" ]
 # Get ctfd
 - [ git, clone, "-b", "${CTFD_VERSION}", "--depth", "1", "${CTFD_REPO}", "${CTFD_DIR}" ]
 # Extract the CTFd overlay on top of the checkout
 - [ aws, s3, cp, "s3://${CTFD_OVERLAY}", "ctfd_overlay.tar.gz" ]
 - [ tar, -xzf, "ctfd_overlay.tar.gz", -C, "${CTFD_DIR}" ]
 # Install CTFd requirements
 - [ pip3, install, -r, "${CTFD_DIR}/requirements.txt" ]
 # Set permissions for ctdf and create log dirs
 - [ chown, -R, "${SERVICE_USER}:${SERVICE_GROUP}", "${CTFD_DIR}" ]
 - [ mkdir, -p, "${LOG_DIR}" ]
 - [ chown, -R, "${SERVICE_USER}:${SERVICE_GROUP}", "${LOG_DIR}" ]
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
 # Setup cloudwatch metrics
 - [ /opt/aws/amazon-cloudwatch-agent/bin/amazon-cloudwatch-agent-ctl, -a, fetch-config, -m, ec2, -c, file:/opt/aws/amazon-cloudwatch-agent/etc/amazon-cloudwatch-agent.json, -s ]
 # This will trigger CTFd to start up
 - [ sudo, -u, ${SERVICE_USER}, curl, --unix-socket, /run/gunicorn.sock, http ]
 # start nginx again now that we are ready to serve CTFd
 - [ systemctl, start, nginx ]
