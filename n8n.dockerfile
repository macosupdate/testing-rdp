FROM n8nio/n8n:1.123.5

# Switch to root to install packages
USER root

# Create folder & fix permissions
RUN mkdir -p /home/node/.n8n/nodes \
    && chown -R node:node /home/node/.n8n

# Install custom nodes under "node" user
USER node

RUN cd /home/node/.n8n/nodes \
    && npm init -y \
    && npm install n8n-nodes-sqlite3
