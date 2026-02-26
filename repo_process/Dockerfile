#############################
# Python Job
#############################
# Start with Python 3.11.9 (Bullseye-based) as the base image
FROM python:3.11.9-slim-bullseye AS pyjob
WORKDIR /opt/home-lab/repo_process
# ENV PS1="root@\h: # "
# Set environment variables for Spark installation
ENV SPARK_VERSION=3.5.1 \
    HADOOP_VERSION=3 \
    SPARK_HOME=/opt/spark \
    JAVA_HOME=/usr/lib/jvm/java-11-openjdk-amd64 \
    PATH=$SPARK_HOME/bin:$JAVA_HOME/bin:$PATH

# Install system dependencies and packages
COPY ./requirements.txt .

RUN apt-get update && apt-get install -y \
    openjdk-11-jdk \
    curl \
    wget \
    unzip \
    && rm -rf /var/lib/apt/lists/*
RUN python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel \
    && python3 -m pip install --no-cache-dir -r requirements.txt python-dateutil

# Use bitnamilegacy/spark:3.5.1 to copy Spark binaries instead of downloading
COPY --from=bitnamilegacy/spark:3.5.1 /opt/bitnami/spark /opt/spark

COPY . .
RUN sh scripts/build-project.sh \
    && python3 scripts/init_package.py

#############################
# Custom Bitnami/Spark
#############################
FROM bitnamilegacy/spark:3.5.1 AS bitnami-spark-custom
USER root
WORKDIR /opt/home-lab/repo_process

COPY ./requirements.txt .

RUN apt update -y \
    && python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel \
    && python3 -m pip install --no-cache-dir -r requirements.txt python-dateutil

COPY . .
RUN sh scripts/build-project.sh \
    && python3 scripts/init_package.py

#############################
# Jupyter Lab
#############################
FROM bitnamilegacy/spark:3.5.1 AS jupyter-lab

USER root
WORKDIR /opt/home-lab/repo_process

COPY requirements.txt .
RUN apt update -y \
    && python3 -m pip install --no-cache-dir --upgrade pip setuptools wheel \
    && python3 -m pip install --no-cache-dir jupyterlab==4.2.0 \
    && python3 -m pip install --no-cache-dir -r requirements.txt python-dateutil

ENV PYTHONPATH="${PYTHONPATH}:/opt/home-lab/repo_process"

COPY . .
RUN sh scripts/build-project.sh \
    && python3 scripts/init_package.py

EXPOSE 8888
