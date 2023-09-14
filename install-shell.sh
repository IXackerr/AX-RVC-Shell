#!/bin/sh

#############################
# Alpine Linux Installation #
#############################

# Define the root directory to /home/container.
# We can only write in /home/container and /tmp in the container.
ROOTFS_DIR="/home/container"

# Download & decompress the Alpine linux root file system if not already installed.
if [ ! -e /home/container/.installed ]; then
    # Download Alpine Linux root file system.
    curl -Lo /tmp/rootfs.tar.gz \
    "https://dl-cdn.alpinelinux.org/alpine/v3.18/releases/x86_64/alpine-minirootfs-3.18.3-x86_64.tar.gz"
    # Extract the Alpine Linux root file system.
    tar -xzf /tmp/rootfs.tar.gz -C /home/container
fi

################################
# Package Installation & Setup #
################################

# Download static APK-Tools temporarily because minirootfs does not come with APK pre-installed.
if [ ! -e /home/container/.installed ]; then
    # Download the packages from their sources.
    curl -Lo /tmp/apk-tools-static.apk "https://dl-cdn.alpinelinux.org/alpine/v3.18/main/x86_64/apk-tools-static-2.14.0-r2.apk"
    curl -Lo /tmp/gotty.tar.gz "https://github.com/sorenisanerd/gotty/releases/download/v1.5.0/gotty_v1.5.0_linux_arm64.tar.gz"
    curl -Lo /home/container/usr/local/bin/proot "https://github.com/proot-me/proot/releases/download/v5.3.0/proot-v5.3.0-x86_64-static"
    # Extract everything that needs to be extracted.
    tar -xzf /tmp/apk-tools-static.apk -C /tmp/
    tar -xzf /tmp/gotty.tar.gz -C /home/container/usr/local/bin
    # Install base system packages using the static APK-Tools.
    /tmp/sbin/apk.static -X "https://dl-cdn.alpinelinux.org/alpine/v3.18/main/" -U --allow-untrusted --root /home/container add alpine-base apk-tools
    # Make PRoot and GoTTY executable.
    chmod 755 /home/container/usr/local/bin/proot /home/container/usr/local/bin/gotty
fi

# Clean-up after installation complete & finish up.
if [ ! -e /home/container/.installed ]; then
    # Add DNS Resolver nameservers to resolv.conf.
    printf "nameserver 1.1.1.1\nnameserver 1.0.0.1" > ${ROOTFS_DIR}/etc/resolv.conf
    # Wipe the files we downloaded into /tmp previously.
    rm -rf /tmp/apk-tools-static.apk /tmp/rootfs.tar.gz /tmp/sbin
    # Create .installed to later check whether Alpine is installed.
    touch /home/container/.installed
fi

# Print some useful information to the terminal before entering PRoot.
# This is to introduce the user with the various Alpine Linux commands.
clear && cat << EOF
                                                                                                
 ▄▄▄      ▒██   ██▒    ██▀███   ██▒   █▓ ▄████▄       ██████  ██░ ██ ▓█████  ██▓     ██▓    
▒████▄    ▒▒ █ █ ▒░   ▓██ ▒ ██▒▓██░   █▒▒██▀ ▀█     ▒██    ▒ ▓██░ ██▒▓█   ▀ ▓██▒    ▓██▒    
▒██  ▀█▄  ░░  █   ░   ▓██ ░▄█ ▒ ▓██  █▒░▒▓█    ▄    ░ ▓██▄   ▒██▀▀██░▒███   ▒██░    ▒██░    
░██▄▄▄▄██  ░ █ █ ▒    ▒██▀▀█▄    ▒██ █░░▒▓▓▄ ▄██▒     ▒   ██▒░▓█ ░██ ▒▓█  ▄ ▒██░    ▒██░    
 ▓█   ▓██▒▒██▒ ▒██▒   ░██▓ ▒██▒   ▒▀█░  ▒ ▓███▀ ░   ▒██████▒▒░▓█▒░██▓░▒████▒░██████▒░██████▒
 ▒▒   ▓▒█░▒▒ ░ ░▓ ░   ░ ▒▓ ░▒▓░   ░ ▐░  ░ ░▒ ▒  ░   ▒ ▒▓▒ ▒ ░ ▒ ░░▒░▒░░ ▒░ ░░ ▒░▓  ░░ ▒░▓  ░
  ▒   ▒▒ ░░░   ░▒ ░     ░▒ ░ ▒░   ░ ░░    ░  ▒      ░ ░▒  ░ ░ ▒ ░▒░ ░ ░ ░  ░░ ░ ▒  ░░ ░ ▒  ░
  ░   ▒    ░    ░       ░░   ░      ░░  ░           ░  ░  ░   ░  ░░ ░   ░     ░ ░     ░ ░   
      ░  ░ ░    ░        ░           ░  ░ ░               ░   ░  ░  ░   ░  ░    ░  ░    ░  ░
                                                                          

 Welcome to AX RVC Shell!
 
EOF

###########################
# Start PRoot environment #
###########################

# This command starts PRoot and binds several important directories
# from the host file system to our special root file system.
/home/container/usr/local/bin/proot \
--rootfs="${ROOTFS_DIR}" \
--link2symlink \
--kill-on-exit \
--root-id \
--cwd=/root \
--bind=/proc \
--bind=/dev \
--bind=/sys \
--bind=/tmp \
/bin/sh
