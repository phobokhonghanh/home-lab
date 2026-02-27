#############################
# Airflow Custom
#############################
FROM apache/airflow:2.10.3 AS airflow_custom

USER root
WORKDIR /opt/home-lab/repo_workflow

COPY ./requirements.txt .
COPY ./constraints.txt .

USER airflow

RUN python3 -m pip install --no-cache-dir --upgrade pip wheel \
    && python3 -m pip install --no-cache-dir -r requirements.txt

COPY --chown=airflow:airflow . .
RUN sh scripts/build-project.sh \
    && python3 scripts/init_package.py

# Force-pin setuptools AFTER editable install upgraded it
RUN python3 -m pip install --no-cache-dir --force-reinstall "setuptools==70.0.0"
