#!/bin/bash
echo "--> Adding helper for IP retrieval"
sudo tee /etc/profile.d/ips.sh > /dev/null <<EOF
function private_ip {
  curl -s http://169.254.169.254/latest/meta-data/local-ipv4
}
function public_ip {
  curl -s http://169.254.169.254/latest/meta-data/public-ipv4
}
EOF

source /etc/profile.d/ips.sh

echo "--> Updating apt-cache"
apt-get -y update

echo "--> Installing common dependencies"
apt-get -y install \
  unzip ntp dnsmasq dnsmasq-base dnsutils

echo "--> Setting hostname..."
echo "${node_name}" | sudo tee /etc/hostname
sudo hostname -F /etc/hostname

echo "--> Adding hostname to /etc/hosts"
sudo tee -a /etc/hosts > /dev/null <<EOF
# For local resolution
$(private_ip)  ${node_name} ${node_name}.node.consul
EOF

systemctl enable ntp.service
systemctl start ntp.service
systemctl enable dnsmasq
systemctl restart dnsmasq


curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
sudo apt-get -qq -y update
