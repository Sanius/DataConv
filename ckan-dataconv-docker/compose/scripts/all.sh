#!/bin/bash
exec "/srv/app/airflow-entrypoint.sh" && exec "/srv/app/start_ckan.sh"