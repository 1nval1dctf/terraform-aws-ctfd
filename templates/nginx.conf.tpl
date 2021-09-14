proxy_cache_path /var/nginx levels=1:2 keys_zone=ctfd_cache:10m max_size=10g inactive=600m use_temp_path=off;

server {
  listen 80;
  client_max_body_size ${UPLOAD_FILESIZE_LIMIT};
  proxy_cache ctfd_cache;

  # Static serving of theme files, falling back to CTFd
  root ${CTFD_DIR}/CTFd;
  # We don't know the theme name so match anything within a directory called static
  location ~* ^.+\/(static)\/.+$ {
      try_files $uri $uri @backend;
  }

  # Handle Server Sent Events for Notifications
  location /events {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
    proxy_set_header Connection '';
    proxy_http_version 1.1;
    chunked_transfer_encoding off;
    proxy_buffering off;
    proxy_cache off;
    proxy_redirect off;
  }

  # everything else we 'forward' to CTFd
  location / {
      try_files /dev/null @backend;
  }

  location @backend {
    include proxy_params;
    proxy_pass http://unix:/run/gunicorn.sock;
    proxy_headers_hash_max_size 512;
    proxy_headers_hash_bucket_size 128;
    proxy_buffering off;
  }
}