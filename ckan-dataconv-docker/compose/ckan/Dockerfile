##################
### Build CKAN ###
##################
FROM ubuntu:18.04 as ckan_build

SHELL ["/bin/bash", "-i", "-c"]

# Set src dirs
ENV APP_DIR=/srv/app
ENV SRC_DIR=${APP_DIR}/src
ENV PIP_SRC=${SRC_DIR}

# Set CKAN version to build
ENV GIT_URL=https://github.com/ckan/ckan.git
ENV GIT_BRANCH=ckan-2.9.2
# List of default extensions
ENV DEFAULT_EXTENSIONS envvars
# Locations and tags, please use specific tags or revisions
ENV ENVVARS_GIT_URL=https://github.com/okfn/ckanext-envvars
ENV ENVVARS_GIT_BRANCH=0.0.1
# Get python version from docker-compose
ARG PYTHON_VERSION

# Update system
RUN apt-get -y update
RUN apt-get -y upgrade
RUN apt-get -y autoremove

# Packages to build CKAN requirements and plugins
RUN apt-get -y install apt-utils \
        git \
        curl \
        vim \
        python3 \
        libpq-dev \
        gcc \
        make \
        g++ \
        autoconf \
        automake \
        libtool \
        patch \
        musl-dev \
        libpcre3-dev \
        libpcre3 \
        python3-dev \
        zlib1g-dev\
        libffi-dev \
        libxml2-dev \
        libxslt1-dev \
        libssl-dev \
        libbz2-dev \
        libreadline-dev \
        libsqlite3-dev \
        liblzma-dev

# ================================================================================================
# Install pyenv

RUN git clone https://github.com/pyenv/pyenv.git /.pyenv
ENV PYENV_ROOT /.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv-virtualenv.git $PYENV_ROOT/plugins/pyenv-virtualenv
ENV PATH $PYENV_ROOT/plugins/pyenv-virtualenv/shims:$PYENV_ROOT/plugins/pyenv-virtualenv/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv-update.git $PYENV_ROOT/plugins/pyenv-update
ENV PATH $PYENV_ROOT/plugins/pyenv-update/bin:$PATH
RUN echo eval "$(pyenv init -)" >> /root/.bashrc
RUN echo eval "$(pyenv virtualenv-init -)" >> /root/.bashrc

# Setup ckan environment (python 3.6.11)
RUN pyenv install ${PYTHON_VERSION}
RUN pyenv virtualenv ${PYTHON_VERSION} ckan

# Downgrade setuptools so that CKAN requirements can be built
RUN pyenv activate ckan && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install setuptools==44.1.0 && \
    python3 -m pip install wheel && \
    python3 -m pip install psycopg2 && \
    python3 -m pip install numpy

# ================================================================================================

# Fetch and build CKAN and requirements
RUN pyenv activate ckan && \
    python3 -m pip install -e git+${GIT_URL}@${GIT_BRANCH}#egg=ckan

# Create the src directory
RUN mkdir -p ${APP_DIR} && \
    ln -s $PYENV_ROOT/versions/ckan/src ${SRC_DIR}

# Set default src dir
WORKDIR ${SRC_DIR}

RUN pyenv activate ckan && \
    python3 -m pip wheel --wheel-dir=/wheels -r ckan/requirements.txt && \
    python3 -m pip wheel --wheel-dir=/wheels uwsgi==2.0.19.1 gevent==20.6.2 greenlet==0.4.16 && \
# Fetch and build the default CKAN extensions
    python3 -m pip wheel --wheel-dir=/wheels git+${ENVVARS_GIT_URL}@${ENVVARS_GIT_BRANCH}#egg=ckanext-envvars

############
### MAIN ###
############
FROM ubuntu:18.04

SHELL ["/bin/bash", "-i", "-c"]

ENV APP_DIR=/srv/app
ENV SRC_DIR=/srv/app/src
ENV DATA_DIR=/srv/app/data
ENV PIP_SRC=${SRC_DIR}
ENV CKAN_SITE_URL=http://localhost:5000
ENV CKAN_PLUGINS envvars image_view text_view recline_view ckanext-mysql2mongodb
ARG PYTHON_VERSION

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
        apache2-utils

# ================================================================================================
# Install pyenv

RUN git clone https://github.com/pyenv/pyenv.git /.pyenv
ENV PYENV_ROOT /.pyenv
ENV PATH $PYENV_ROOT/shims:$PYENV_ROOT/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv-virtualenv.git $PYENV_ROOT/plugins/pyenv-virtualenv
ENV PATH $PYENV_ROOT/plugins/pyenv-virtualenv/shims:$PYENV_ROOT/plugins/pyenv-virtualenv/bin:$PATH
RUN git clone https://github.com/pyenv/pyenv-update.git $PYENV_ROOT/plugins/pyenv-update
ENV PATH $PYENV_ROOT/plugins/pyenv-update/bin:$PATH
RUN echo eval "$(pyenv init -)" >> /root/.bashrc
RUN echo eval "$(pyenv virtualenv-init -)" >> /root/.bashrc

# Setup ckan environment (python 3.6.11)
RUN pyenv install ${PYTHON_VERSION}
RUN pyenv virtualenv ${PYTHON_VERSION} ckan

# Downgrade setuptools so that CKAN requirements can be built
RUN pyenv activate ckan && \
    python3 -m pip install --upgrade pip && \
    python3 -m pip install setuptools==44.1.0 && \
    python3 -m pip install wheel

# ================================================================================================

# Get artifacts from build stages
COPY --from=ckan_build /wheels /srv/app/wheels
COPY --from=ckan_build /srv/app/src/ckan /srv/app/src/ckan

# Additional install steps for build stages artifacts
RUN pyenv activate ckan && \
    python3 -m pip install --no-index --find-links=/srv/app/wheels uwsgi gevent

# Create a local user and group to run the app
RUN addgroup --system --gid 92 ckan && \
    # adduser -u 92 -h /srv/app -H -D -S -G ckan ckan
    adduser --home /srv/app --uid 92 --ingroup ckan --system --disabled-password ckan && \
    usermod -aG sudo ckan

ARG CACHEBUST=1
RUN pyenv activate ckan && \
    python3 -m pip install -e git+https://github.com/ligthsworn/ckanext-mysql2mongodb#egg=ckanext-mysql2mongodb --no-cache-dir

ENV LC_ALL=en_US.UTF-8
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US.UTF-8

RUN locale-gen en_US.UTF-8

# Install CKAN
RUN pyenv activate ckan && \
    python3 -m pip install -e /srv/app/src/ckan && \
    cd ${SRC_DIR}/ckan && \
    cp who.ini ${APP_DIR} && \
    python3 -m pip install --no-index --find-links=/srv/app/wheels -r requirements.txt && \
    # Install default CKAN extensions
    python3 -m pip install --no-index --find-links=/srv/app/wheels ckanext-envvars && \
    # Create and update CKAN config
    # Set timezone
    echo "UTC" >  /etc/timezone
RUN pyenv activate ckan && \
    # Generate CKAN config
    ckan generate config ${APP_DIR}/production.ini && \
    # Configure plugins
    ckan config-tool ${APP_DIR}/production.ini "ckan.plugins = ${CKAN_PLUGINS}" && \
    # Create the data directory
    mkdir ${DATA_DIR} && \
    # Webassets can't be loaded from env variables at runtime, it needs to be in the config so that it is created
    ckan config-tool ${APP_DIR}/production.ini "ckan.webassets.path = ${DATA_DIR}/webassets" && \
    # Set the default level for extensions to INFO
    ckan config-tool ${APP_DIR}/production.ini -s logger_ckanext -e level=INFO && \
    # Change ownership to app user
    chown -R ckan:ckan /srv/app

# Remove wheels
RUN rm -rf /srv/app/wheels

# Copy necessary scripts
COPY ckan/setup/app/ ${APP_DIR}

# Create entrypoint directory for children image scripts
ONBUILD RUN mkdir docker-entrypoint.d

# Create afterinit directory for children image scripts
ONBUILD RUN mkdir docker-afterinit.d

RUN mkdir ${APP_DIR}/ext_requirements
COPY ckan/ext_setup/requirements.txt ${APP_DIR}/ext_requirements/

RUN pyenv activate ckan && \
    python3 -m pip install -r ${APP_DIR}/ext_requirements/requirements.txt

RUN apt-get -y update

RUN apt-get install -y --no-install-recommends \
    mysql-client \ 
    openjdk-11-jdk \
    zip \
    freetds-bin \
    ldap-utils \
    libffi6 \
    libsasl2-2 \
    libsasl2-modules \
    libssl1.1 \
    locales  \
    lsb-release \
    sasl2-bin \
    sqlite3 \
    mongo-tools\
    unixodbc

RUN mkdir -p /srv/app/airflow
RUN chmod 777 -R /srv/app/airflow
ENV AIRFLOW_HOME=/srv/app/airflow
RUN pyenv activate ckan && \
    python3 -m pip install apache-airflow && \
    python3 -m pip install psycopg2 && \
    python3 -m pip install numpy

EXPOSE 5000

HEALTHCHECK --interval=10s --timeout=5s --retries=5 CMD curl --fail http://localhost:5000/api/3/action/status_show || exit 1

USER ckan

CMD ["/srv/app/start_ckan.sh"]
