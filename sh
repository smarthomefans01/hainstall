#!/bin/bash

# 修改dtb名称

#!/bin/bash

# Set timezone to Asia/Shanghai
echo "Setting timezone to Asia/Shanghai..."
sudo timedatectl set-timezone Asia/Shanghai

# Install NTP service if not already installed
echo "Installing NTP service..."
sudo apt-get install -y ntp

# Configure NTP server for China
echo "Configuring NTP server for China..."
sudo sed -i '/pool 0.debian.pool.ntp.org iburst/d' /etc/ntp.conf
echo "server 0.cn.pool.ntp.org iburst" | sudo tee -a /etc/ntp.conf

# Enable and start NTP service
echo "Enabling and starting NTP service..."
sudo systemctl enable ntp
sudo systemctl start ntp

# Check NTP service status
echo "Checking NTP service status..."
sudo systemctl status ntp

# Add a note to the user
echo "The system will now synchronize time with NTP server on boot."

# End of the bash script



# 1.给盒子命名
hostnamectl set-hostname smarthomefansbox

# 2.修改主板名称
sudo nano /etc/update-motd.d/10-uname

# 3.修改密码

# 4. 修改apt源

# Backup the original sources.list
cp /etch/apt/sources.list /etch/apt/sources.list.backup

# Replace the sources list with Tsinghua University's sources for Debian Bookworm
cat > /etc/apt/sources.list << EOF
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian-security bookworm-security main contrib non-free
deb https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free
deb-src https://mirrors.tuna.tsinghua.edu.cn/debian/ bookworm-updates main contrib non-free
EOF

# 5.修改 armbian源

# Update package lists
apt update

# Upgrade all packages
apt upgrade -y

# Attempt to fix broken installs first
apt --fix-broken install -y

# 6.Install required packages
apt-get install armbian-config -y

# 7.Install additional necessary packages
apt install apparmor cifs-utils curl dbus jq libglib2.0-bin lsb-release network-manager nfs-common systemd-journal-remote systemd-resolved udisks2 wget -y

# Check for successful installation of packages
if [ $? -ne 0 ]; then
    echo "Error installing necessary packages, attempting to fix..."
    apt --fix-broken install -y
    # If still failing, exit to prevent further errors
    if [ $? -ne 0 ]; then
        echo "Failed to fix broken installations, exiting..."
        exit 1
    fi
fi

# 8.Use sed to update the PRETTY_NAME field in /etc/os-release for Debian 12 (Bookworm)

sed -i 's#^PRETTY_NAME=".*"#PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"#' /etc/os-release
echo "extraargs=apparmor=1 security=apparmor systemd.unified_cgroup_hierarchy=false" >> /boot/armbianEnv.txt


#9. Install Docker
curl -fsSL get.docker.com -o get-docker.sh
sh get-docker.sh --mirror Aliyun

# Check Docker installation success
if [ $? -ne 0 ]; then
    echo "Error installing Docker, attempting to fix..."
    apt --fix-broken install -y
    exit 1
fi
# 10.修改docker源

# Download and install the Home Assistant OS Agent
wget https://github.com/home-assistant/os-agent/releases/download/1.6.0/os-agent_1.6.0_linux_aarch64.deb && dpkg -i os-agent_1.6.0_linux_aarch64.deb || apt --fix-broken install -y

# Download and install the Home Assistant Supervised Debian package
wget -O homeassistant-supervised.deb https://github.com/home-assistant/supervised-installer/releases/latest/download/homeassistant-supervised.deb && dpkg -i homeassistant-supervised.deb || apt --fix-broken install -y

# 还原ha

# Final check for any unresolved dependencies
apt --fix-broken install -y

# Path to the daemon.json file
DAEMON_JSON_FILE="/etc/docker/daemon.json"

# Read the existing daemon.json file
if [ -f "$DAEMON_JSON_FILE" ]; then
    # Add the registry-mirrors key with the desired mirror URLs
    cat <<EOF > "$DAEMON_JSON_FILE"
{
    "log-driver": "journald",
    "storage-driver": "overlay2",
    "ip6tables": true,
    "experimental": true,
    "log-opts": {
        "tag": "{{.Name}}"
    },
    "registry-mirrors": [
        "https://dockerproxy.com",
        "https://docker.m.daocloud.io",
        "https://docker.nju.edu.cn"
    ]
}
EOF

    echo "Chinese Docker registry mirrors added to $DAEMON_JSON_FILE"
else
    echo "Error: $DAEMON_JSON_FILE does not exist."
fi
sudo systemctl restart docker


ha jobs options --ignore-conditions healthy
ha backups restore d7514368 --password smb20240420


