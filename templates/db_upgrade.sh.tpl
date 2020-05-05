#!/bin/bash
export DATABASE_URL=${DATABASE_URL}

echo "Doing db upgrade"
python3 /opt/ctfd/manage.py db upgrade