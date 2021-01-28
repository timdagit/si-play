# *****************************************************************************************
# First build image containing required packages
# *****************************************************************************************
FROM python:3.7-slim-buster AS BUILDER

WORKDIR /opt/app
RUN mkdir packages
RUN mkdir config
RUN mkdir data
RUN mkdir logs
RUN mkdir oracle

# Need these for PG build or unzip for Ora, but none of this is copied to final image so
# not a big issue!
RUN 	apt-get update
RUN 	apt-get dist-upgrade -y
RUN 	apt-get install -y gcc libpq-dev unzip
RUN 	apt-get clean

# Need these 3 lines for Oracle client Apps !!!
COPY    instantclient-basiclite-linuxx64.zip oracle
RUN     unzip oracle/instantclient-basiclite-linuxx64.zip -d oracle/
RUN     rm -f oracle/instantclient-basiclite-linuxx64.zip

COPY    requirements.txt .
RUN 	pip install --no-cache-dir --upgrade pip
RUN 	pip install --prefix=/opt/app/packages --no-cache-dir -r requirements.txt


# *****************************************************************************************
# Now create final image based on minimal parent and copying required packages from BUILDER
# *****************************************************************************************
FROM python:3.7-slim-buster

WORKDIR /opt/app
COPY --from=BUILDER /opt/app .

# Need libpq-dev library for Postgres client Apps !!!
#RUN 	apt-get update && apt-get install -y libpq-dev

# Need the libaio1 library for Oracle client Apps !!!
#RUN 	apt-get update && apt-get install -y libaio1

# Need libpq-dev AND libaio1 libraries for Apps using both Postgres and Oracle !!!
RUN 	apt-get update && apt-get install -y libpq-dev libaio1

COPY dbprofiles.yml config/dbprofiles.yml
COPY etl_config.json config/etl_config.json
COPY log_config.json config/log_config.json
COPY sde_apps_pipeline_import sde_apps_pipeline_import

ENV PYTHONPATH "${PYTHONPATH}:/opt/app/packages/lib/python3.7/site-packages/:/opt/app/sde_apps_pipeline_import/"
ENV PATH "${PATH}:/opt/app/packages/bin/"
ENV LD_LIBRARY_PATH "/opt/app/oracle/instantclient_19_9:${LD_LIBRARY_PATH}"

ENTRYPOINT [ "python", "-m", "sde_apps_pipeline_import.cli" ]

#CMD [ "ops_mpan_address" ]

#CMD [ "python", "-m", "sde_apps_pipeline_import.sde_pipeline_import" ]
