FROM python:3.11-slim

WORKDIR /app

# Install system-level build dependencies for packages like google-re2
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    g++ \
    libabsl-dev \
    pybind11-dev \
    libre2-dev \
    && rm -rf /var/lib/apt/lists/*

COPY requirements.txt /app/
RUN pip install --no-cache-dir -r requirements.txt

COPY . /app/

RUN mkdir -p /app/data && chmod 777 /app/data

EXPOSE 8000

CMD ["gunicorn", "--worker-class=sync", "--workers=15", "--bind=0.0.0.0:8000", "--timeout=1800", "--max-requests=1000", "--max-requests-jitter=50", "--graceful-timeout=300", "--keep-alive=5", "--worker-connections=1000", "wsgi:application"]
