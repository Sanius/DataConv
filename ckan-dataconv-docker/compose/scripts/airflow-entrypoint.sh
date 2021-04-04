#!/bin/bash
export AIRFLOW_HOME="/srv/app/airflow"

if [ ! -d $AIRFLOW_HOME ]
then
    mkdir $AIRFLOW_HOME
fi

if [ ! -f $AIRFLOW_HOME/"airflow.cfg" ] 
then
    python3 -m airflow db init
fi

# airflow db reset
python3 -m airflow db init

# airflow scheduler
python3 -m  airflow scheduler

# airflow webserver
python3 -m airflow webserver


