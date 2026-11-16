#!/bin/bash
# Runs once when the instance first boots: installs Nginx and serves a simple page
dnf install -y nginx

cat > /usr/share/nginx/html/index.html <<'HTML'
<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Monitored Web Server</title>
  <style>
    body { font-family: system-ui, sans-serif; max-width: 640px; margin: 15vh auto; padding: 0 1rem; }
    code { background: #eee; padding: 2px 6px; border-radius: 4px; }
  </style>
</head>
<body>
  <h1>Monitored Web Server</h1>
  <p>This page is served by <code>Nginx</code> on an Amazon EC2 instance.</p>
  <p>The instance, network and alarms are all created with Terraform.</p>
</body>
</html>
HTML

systemctl enable --now nginx