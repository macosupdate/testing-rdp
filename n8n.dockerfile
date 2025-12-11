FROM n8nio/n8n:1.82.3

# Install required tools
USER root
RUN npm install -g n8n-nodes-sqlite3

# Switch back to n8n user
USER node
