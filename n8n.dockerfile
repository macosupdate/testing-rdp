FROM n8nio/n8n:1.123.5

# Install required tools
USER root
RUN mkdir ~/.n8n/nodes \
    && cd ~/.n8n/nodes \
    && npm install n8n-nodes-sqlite3

# Switch back to n8n user
USER node
