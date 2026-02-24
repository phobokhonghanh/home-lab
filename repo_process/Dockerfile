#############################
# Python Job
#############################
# Start with Python 3.11.9 (Bullseye-based) as the base image
FROM python:3.11.9-slim-bullseye as pyjob
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
RUN pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

# Download and install Apache Spark
RUN wget https://archive.apache.org/dist/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && tar -xzf spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz -C /opt/ \
    && rm spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION}.tgz \
    && mv /opt/spark-${SPARK_VERSION}-bin-hadoop${HADOOP_VERSION} /opt/spark

COPY . .
RUN sh scripts/build-project.sh \
    && python3 scripts/init_package.py

#############################
# Custom Bitnami/Spark
#############################
FROM bitnamilegacy/spark:3.5.1 as bitnami-spark-custom
USER root
WORKDIR /opt/home-lab/repo_process

COPY ./requirements.txt .

RUN apt update -y \
    && pip install --no-cache-dir --upgrade pip setuptools wheel \
    && pip install --no-cache-dir -r requirements.txt

COPY . .
RUN sh scripts/build-project.sh \
    && python3 scripts/init_package.py

#############################
# Jupyter Lab
#############################
FROM bitnamilegacy/spark:3.5.1 as jupyter-lab

USER root
WORKDIR /opt/home-lab/repo_process

COPY requirements.txt .
RUN apt update -y \
    && pip install --no-cache-dir jupyterlab==4.2.0 \
    && pip install --no-cache-dir -r requirements.txt

ENV PYTHONPATH="${PYTHONPATH}:/opt/home-lab/repo_process"

COPY . .
RUN sh scripts/build-project.sh \
    && python3 scripts/init_package.py

EXPOSE 8888
