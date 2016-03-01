#!/bin/sh
sudo -s
cat <<EOF >/usr/sbin/startup;
#!/bin/sh
/usr/bin/zerotier-cli join e5cd7a9e1c87b1c8
/usr/local/bin/weave launch 104.215.253.187 > /weaveip
/usr/local/bin/scope launch
EOF

cat <<EOF >/etc/systemd/system/onboot.service;
[Unit]
Description=start klouds stack
Requires=/etc/systemd/system/zerotier-one.service

[Service]
ExecStart=/usr/sbin/startup

[Install]
WantedBy=multi-user.target
EOF
