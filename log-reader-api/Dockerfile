# syntax = docker/dockerfile:1.3

FROM python:3.10-slim

# ENVs are built bith buildkit and into secret ENVs
# COPIER_LOGS should have the same value as job and pod manifests volumeMounts
ENV COPIER_LOGS=/tmp/copier-logs

# Allow statements and log messages to immediately appear in the Knative logs
ENV PYTHONUNBUFFERED True

# Copy local code to the container image.
COPY app /log-reader-api/app
COPY tests /log-reader-api/tests
COPY requirements.txt /log-reader-api/requirements.txt
WORKDIR /log-reader-api

# Install production dependencies.
RUN pip install --no-cache-dir -r requirements.txt

# Run the web service on container startup.
# webserver, with 2 workers processes
# For environments with multiple CPU cores, increase the number of workers
# to be equal to the cores available.
ENTRYPOINT ["uvicorn", "--host", "0.0.0.0", "--port", "8000", "--workers", "2", "--reload", "app.main:logreader"]
