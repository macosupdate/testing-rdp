FROM scratch

WORKDIR /app

# Copy file SQLite đã mã hoá
COPY firefox.tar.gz.age /app/firefox.tar.gz.age
