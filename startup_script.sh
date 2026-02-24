echo "# Lab specific ENV vars" >> /etc/bash.bashrc
echo "export BIGTABLE_PROJECT=${projectid}"  >> /etc/bash.bashrc
echo "export BIGTABLE_SUFFIX=${suffix}" >> /etc/bash.bashrc


# Install UV
/usr/bin/curl -LsSf https://astral.sh/uv/install.sh | /usr/bin/sh
/usr/bin/cp /root/.local/bin/uv /usr/local/bin/uv
/bin/chmod 755 /usr/local/bin/uv
rm -rf  /root/.local/bin 2>/dev/null || true

