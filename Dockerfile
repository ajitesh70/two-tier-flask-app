FROM python:3.9-slim

WORKDIR /app

# Install minimal dependencies needed for mysqlclient
RUN apt-get update \
    && apt-get install -y default-libmysqlclient-dev gcc pkg-config \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt .

RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["python", "app.py"]
