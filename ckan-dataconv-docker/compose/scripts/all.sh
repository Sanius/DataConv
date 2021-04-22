#!/bin/bash
bash -i "/srv/app/start_ckan.sh" && bash -i "/srv/app/airflow-entrypoint.sh"