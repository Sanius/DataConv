
############
### MAIN ###
############
FROM ubuntu:20.04

SHELL ["/bin/bash", "-i", "-c"]

# Build-time variables
ARG PYTHON_VERSION=${PYTHON_VERSION}
ARG CKAN_SITE_URL=${CKAN_SITE_URL}
ARG CKAN_PLUGINS=${CKAN_PLUGINS}
# Environment variables
ENV APP_DIR=/srv/app
ENV SRC_DIR=/srv/app/src
ENV DATA_DIR=/srv/app/data
ENV PIP_SRC=${SRC_DIR}
# Set CKAN version to build
ENV GIT_URL=https://github.com/ckan/ckan.git
ENV GIT_BRANCH=ckan-2.9.2
# CKAN extension
ENV ENVVARS_GIT_URL=https://github.com/okfn/ckanext-envvars
ENV ENVVARS_GIT_BRANCH=0.0.1
WORKDIR ${APP_DIR}

RUN apt-get -y update
# Install necessary packages to run CKAN
RUN apt-get install -y --no-install-recommends tzdata
RUN apt-get install -y apt-utils \
        git \
        curl \
        vim \
        gettext \
        gcc \
        make \
        g++ \
        autoconf \
        automake \
        libtool \
        locales \
        patch \
        python3 \
        python3-dev \
        python3-distutils \
        python3-apt \
        libpq-dev \
        postgresql-client \
        libmagic-dev \
        musl-dev \
        libpcre3 \
        libpcre3-dev \
        libxml2 \
        libxml2-dev \
        zlib1g-dev\
        libffi-dev \
        libxslt1-dev \
        libssl-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        liblzma-dev \
        apache2-utils \
        mysql-client \ 
        openjdk-11-jdk \
        zip \
        freetds-bin \
        ldap-utils \
        libffi-dev \
        libsasl2-2 \
        libsasl2-modules \
        libssl1.1 \
        locales  \
        lsb-release \
        sasl2-bin \
        sqlite3 \
        mongo-tools\
        unixodbc
# Create a local user and group to run the app
RUN addgroup --system --gid 92 ckan && \
    # adduser -u 92 -h /srv/app -H -D -S -G ckan ckan
    adduser --home /srv/app --uid 92 --ingroup ckan --system --disabled-password ckan && \
    usermod -aG sudo ckan && \
    chown ckan:ckan /srv/app

USER ckan

# ================================================================================================
# Install pyenv

RUN git clone https://github.com/pyenv/pyenv.git ${APP_DIR}/.pyenv
ENV PYENV_ROOT ${APP_DIR}/.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv-virtualenv.git $PYENV_ROOT/plugins/pyenv-virtualenv
ENV PATH $PYENV_ROOT/plugins/pyenv-virtualenv/shims:$PYENV_ROOT/plugins/pyenv-virtualenv/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv-update.git $PYENV_ROOT/plugins/pyenv-update
ENV PATH $PYENV_ROOT/plugins/pyenv-update/bin:$PATH
RUN echo eval "$(pyenv init --path)" >>  ${APP_DIR}/.bashrc
RUN echo eval "$(pyenv init -)" >>  ${APP_DIR}/.bashrc
RUN echo eval "$(pyenv virtualenv-init -)" >>  ${APP_DIR}/.bashrc

# Setup ckan environment (python 3.6.11)
RUN pyenv install ${PYTHON_VERSION}
RUN pyenv virtualenv ${PYTHON_VERSION} ckan

# ================================================================================================

# ================================================================================================
# Build ckan

# Downgrade setuptools so that CKAN requirements can be built
RUN pyenv activate ckan && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install setuptools==44.1.0 && \
    python3 -m pip install wheel && \
    python3 -m pip install psycopg2 && \
    python3 -m pip install psycopg2-binary && \
    python3 -m pip install numpy

# Create the src directory
RUN ln -s $PYENV_ROOT/versions/ckan/src ${SRC_DIR}
# Set default src dir
WORKDIR ${SRC_DIR}

USER root
RUN chown ckan:ckan $PYENV_ROOT/versions/ckan/src
USER ckan
RUN pyenv activate ckan && \
    # Fetch and build CKAN and requirements
    python3 -m pip install -e git+${GIT_URL}@${GIT_BRANCH}#egg=ckan && \
    python3 -m pip install uwsgi==2.0.19.1 gevent==20.6.2 greenlet==0.4.16

# ================================================================================================

# ================================================================================================
# Build ckan extensions

RUN chown ckan:ckan ${SRC_DIR}
RUN pyenv activate ckan && \
    python3 -m pip install -e git+https://github.com/Sanius/ckanext-mysql2mongodb@develop#egg=ckanext-mysql2mongodb --no-cache-dir

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

USER root
RUN locale-gen en_US.UTF-8 && \
    # Set timezone
    echo "UTC" >  /etc/timezone
USER ckan

# Install CKAN
RUN pyenv activate ckan && \
    python3 -m pip install -e /srv/app/src/ckan && \
    python3 -m pip install -r /srv/app/src/ckan/requirements.txt && \
    cd ${SRC_DIR}/ckan && \
    cp who.ini ${APP_DIR}

COPY ckan/setup/app/ ${APP_DIR}

RUN mkdir -p ${DATA_DIR}

# ================================================================================================

# ================================================================================================
# Build ckan extensions

WORKDIR ${APP_DIR}
# Copy necessary scripts
RUN mkdir -p ${APP_DIR}/ext_requirements
COPY ckan/ext_setup/requirements.txt ${APP_DIR}/ext_requirements/

# Create entrypoint directory for children image scripts
ONBUILD RUN mkdir docker-entrypoint.d

# Create afterinit directory for children image scripts
ONBUILD RUN mkdir docker-afterinit.d

RUN pyenv activate ckan && \
    python3 -m pip install -r ${APP_DIR}/ext_requirements/requirements.txt

USER root

RUN apt-get -y update

USER ckan
RUN mkdir -p /srv/app/airflow
RUN chmod 777 -R /srv/app/airflow
ENV AIRFLOW_HOME=/srv/app/airflow
RUN pyenv local ckan && \
    python3 -m pip install --upgrade https://github.com/pajachiet/pymongo-schema/archive/master.zip
USER root
RUN chown ckan:ckan /srv/app/airflow
RUN chmod ugo+rwx /srv/app/airflow
USER ckan

EXPOSE 5000

HEALTHCHECK --interval=10s --timeout=5s --retries=5 CMD curl --fail http://localhost:5000/api/3/action/status_show || exit 1

CMD ["/srv/app/start_ckan.sh"]
