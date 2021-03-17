proxy_cache_path /var/nginx levels=1:2 keys_zone=ctfd_cache:10m max_size=10g inactive=600m use_temp_path=off;

server {
  listen 80;
  client_max_body_size ${UPLOAD_FILESIZE_LIMIT};
  proxy_cache ctfd_cache;

  # Static serving of theme files
  # We don't know the theme name so match anything within a directory called static
  location ~* ^.+\/(static)\/.+$ {
    root ${CTFD_DIR}/CTFd;
  }

  location / {
    include proxy_params;
    proxy_headers_hash_max_size 512;
    proxy_headers_hash_bucket_size 128;
    proxy_buffering off;
    # as per http://docs.gunicorn.org/en/stable/deploy.html will stop ctfd from generating http links in https responses
    proxy_set_header X-Forwarded-Proto $scheme;

    proxy_pass http://unix:/run/gunicorn.sock;
  }
}