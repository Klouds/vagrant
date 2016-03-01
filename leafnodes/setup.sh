#!/bin/sh
sudo -s
apt update
apt upgrade -y
apt install -y moreutils
wget get.docker.io
sh index.html
curl -L git.io/weave -o /usr/local/bin/weave
chmod a+x /usr/local/bin/weave
wget -O /usr/local/bin/scope https://git.io/scope
chmod a+x /usr/local/bin/scope
wget https://download.zerotier.com/dist/zerotier-one_1.1.4_amd64.deb
dpkg -i zerotier-one_1.1.4_amd64.deb
mkdir /ifs
ifdata -pa zt0 > /ifs/ztip.chicken


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
systemctl enable onboot.service
