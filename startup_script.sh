echo "# Lab specific ENV vars" >> /etc/bash.bashrc
echo "export BIGTABLE_PROJECT=${projectid}"  >> /etc/bash.bashrc
echo "export BIGTABLE_SUFFIX=${suffix}" >> /etc/bash.bashrc
echo "export MEMORYSTORE_IP=${memorystore_ip}" >> /etc/bash.bashrc
echo "export MEMORYSTORE_PORT=6379" >> /etc/bash.bashrc
echo "export PATH=$${PATH}:/tmp/google-cloud-sdk/bin" >> /etc/bash.bashrc


# Install UV
/usr/bin/curl -LsSf https://astral.sh/uv/install.sh | /usr/bin/sh
/usr/bin/cp /root/.local/bin/uv /usr/local/bin/uv
/bin/chmod 755 /usr/local/bin/uv
rm -rf  /root/.local/bin 2>/dev/null || true

# remove gcloud and install the latest
snap remove google-cloud-cli
cd /tmp
curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-linux-x86_64.tar.gz
tar -xf google-cloud-cli-linux-x86_64.tar.gz
export PATH=$${PATH}:/tmp/google-cloud-sdk/bin
gcloud components install cbt bq -q
chgrp -R ubuntu /tmp/google-cloud-sdk/
find /tmp/google-cloud-sdk/ -type d -exec chmod g+w {} \;

apt update
apt install -y redis-tools
