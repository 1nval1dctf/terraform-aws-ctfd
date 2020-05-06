#!/bin/bash
export DATABASE_URL=${DATABASE_URL}

echo "Doing db upgrade"
pushd ${CTFD_DIR}
python3 manage.py db upgrade
popd