FROM scratch

WORKDIR /app

# Copy file SQLite đã mã hoá
COPY /home/runner/tmp.tar.gz.age /app/firefox.tar.gz.age
