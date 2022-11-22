#!/bin/bash

# If Splunk UF is not yet installed, download, install, and start it
if [[ ! -n "${SPLUNK_UF_INSTALLED}" ]]; then
    # Download Universal Forwarder
    echo "Splunk Universal Forwarder not installed - Downloading and installing Splunk Universal Forwarder now"
    sudo wget -O splunkforwarder-9.0.2-17e00c557dc1-Linux-x86_64.tgz "https://download.splunk.com/products/universalforwarder/releases/9.0.2/linux/splunkforwarder-9.0.2-17e00c557dc1-Linux-x86_64.tgz"

    # Move package and update env variable
    echo "Extracting Splunk Forwarder package to /opt"
    sudo tar xvzf splunkforwarder-9.0.2-17e00c557dc1-Linux-x86_64.tgz --directory /opt

    # Create Splunk user and group
    echo "Adding user called 'splunk' and user group"
    sudo useradd -m splunk
    sudo groupadd splunk
    sudo chown -R splunk:splunk /opt/splunkforwarder
    export SPLUNK_HOME=/opt/splunkforwarder

    # Start universal forwarder
    # by running the 'start' command as non-root user
    echo "Starting Splunk Forwarder"
    sudo $SPLUNK_HOME/bin/splunk enable boot-start -systemd-managed 0 -user splunk --accept-license
    sudo -u splunk $SPLUNK_HOME/bin/splunk start

    # sudo -u splunk echo "[user_info]\nUSERNAME = admin\PASSWORD = changeme\n" > /opt/splunkforwarder/etc/system/local/user-seed.conf

    export SPLUNK_UF_INSTALLED=1
fi

# Sanity check
if [[ -d "/opt/splunkforwarder" ]]; then
    export SPLUNK_HOME=/opt/splunkforwarder
    sudo chown -R splunk:splunk /opt/splunkforwarder
fi

echo "Starting Splunk. If Splunk is already running, this will result in an error, but that's okay..."
sudo -u splunk $SPLUNK_HOME/bin/splunk start

# Print user warning
echo "If you haven't done it already, please configure receiving on the receiving Splunk instance(s)."

# User input - get address of forward-server
echo "Please specify the path to the files you want to monitor, e.g. '/opt/log/www2/access.log'."
read path_to_files_to_monitor

# User input - get index name
echo "Please specify the name of the receiving index, e.g. 'main' or 'test'."
read index_name

# User input - if sourcetype is known, get it
echo "If the sourcetype of the data to be forwarded is know, please specify it here. Otherwise just hit ENTER."
read sourcetype

# User input - get forward-server
echo "Please enter the address of the server that is meant to receive the data in the form <ip address>:<port number>, e.g. '10.1.2.3:9997'."
read forward_server

# Add forward server and monitor
sudo -u splunk $SPLUNK_HOME/bin/splunk add forward-server $forward_server
if [ -z "${sourcetype}" ]; then
    sudo -u splunk $SPLUNK_HOME/bin/splunk add monitor $path_to_files_to_monitor -index $index_name
else
    sudo -u splunk $SPLUNK_HOME/bin/splunk add monitor $path_to_files_to_monitor -sourcetype $sourcetype -index $index_name
fi

# Restart Splunk
sudo -u splunk $SPLUNK_HOME/bin/splunk restart