# syntax=docker/dockerfile:1
ARG MLFLOW_VERSION=2.15.0
FROM python:3.11-slim

ARG MLFLOW_VERSION
ENV PIP_NO_CACHE_DIR=1

RUN apt-get update && apt-get install -y --no-install-recommends \
    curl ca-certificates build-essential && \
    rm -rf /var/lib/apt/lists/*

RUN pip install --upgrade pip && \
    pip install "mlflow==${MLFLOW_VERSION}" psycopg2-binary boto3

EXPOSE 5000
CMD ["mlflow", "server", "--host", "0.0.0.0", "--port", "5000"]
