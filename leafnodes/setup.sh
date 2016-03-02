#!/bin/sh
#UPDATING DEBIAN
apt update
apt upgrade -y
apt install -y moreutils nfs-client linux-image-4.3.0
sudo mkdir /storage
echo "192.168.191.53:/storage   /var/lib/docker   nfs    auto  0  0" >> /etc/fstab
wget get.docker.io
sh index.html
mkdir -p /opt/bin
mkdir /ips

#DOWNLOADING NETWORK COMPONENTS
curl -L git.io/weave -o /usr/local/bin/weave
wget -O /usr/local/bin/scope https://git.io/scope
wget https://download.zerotier.com/dist/zerotier-one_1.1.4_amd64.deb
wget -N -P /opt/bin https://github.com/kelseyhightower/setup-network-environment/releases/download/v1.0.0/setup-network-environment

#MARKING NETWORK COMPONENTS RUNNABLE
chmod a+x /usr/local/bin/weave
chmod a+x /usr/local/bin/scope
chmod a+x /opt/bin/setup-network-environment

#INSTALLING ZEROTIER
dpkg -i zerotier-one_1.1.4_amd64.deb

#ZEROTIER SYSTEMD UNIT
cat <<EOF >/etc/systemd/system/zerotier.service
[Unit]
Description=ZeroTier
After=network-online.target
Before=docker.service
Requires=network-online.target
[Service]
ExecStart=/usr/bin/zerotier-cli join e5cd7a9e1c87b1c8
RemainAfterExit=yes
[Install]
WantedBy=multi-user.target
EOF

#SYSTEMD UNIT FOR kelseyhightower'S NETWORK-ENVIORNMENT-SERVICE WHICH ENSURES THAT IP ADDRESSES ARE ACCESSIBLE AT /etc/network-environment
cat <<EOF >/etc/systemd/system/setup-network-environment.service
[Unit]
Description=Setup Network Environment
Documentation=https://github.com/kelseyhightower/setup-network-environment
Requires=network-online.target
Before=docker.socket
Before=docker.service
After=network-online.target
[Service]
ExecStart=/opt/bin/setup-network-environment
RemainAfterExit=yes
Type=oneshot
[Install]
WantedBy=multi-user.target
EOF

#DOCKER SYSTEMD UNIT FILE, LAUNCHES DOCKER WITH PORT OPEN ON ZEROTIER ADDRESS REPORTED BY network-environment-service
cat <<EOF >/lib/systemd/system/docker.service;
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target docker.socket
After=setup-network-environment.service
After=network-online.target
Requires=docker.socket
[Service]
Type=notify
EnvironmentFile=/etc/network-environment
ExecStart=/usr/bin/docker daemon -H fd:// -H ${ZT0_IPV4}:2375
MountFlags=slave
LimitNOFILE=1048576
LimitNPROC=1048576
LimitCORE=infinity
TimeoutStartSec=0
[Install]
WantedBy=multi-user.target
EOF

#ONBOOT SYSTEMD UNIT FILE, RUNS KLOUDS' ONBOOT SCRIPT, WHICH CONNECTS THE VM TO KLOUDS' NETWORK
cat <<EOF >/etc/systemd/system/onboot.service;
[Unit]
Description=start klouds stack
After=docker.service
After=network-online.target
After=zerotier.service
Requires=/etc/systemd/system/zerotier-one.service
Requires=docker.service
[Service]
ExecStart=/usr/bin/onboot
[Install]
WantedBy=multi-user.target
EOF

#ONBOOT SCRIPT
cat <<EOF >/usr/bin/onboot;
#!/bin/sh
/usr/local/bin/weave launch weave.klouds.org
weave expose > /ips/weave
/usr/local/bin/scope launch
ifdata -pa zt0 > /ips/zt0
EOF

chmod a+x /usr/bin/onboot
systemctl enable onboot.service
systemctl enable docker.service
systemctl enable setup-network-environment.service
systemctl enable zerotier.service
