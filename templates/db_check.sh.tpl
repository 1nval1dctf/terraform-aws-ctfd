# Check that the database is available
if [ -n "${DATABASE_HOST}" ]
    then
    echo "Waiting for ${DATABASE_HOST}:${DATABASE_PORT} to be ready"
    while ! mysqladmin ping -h "${DATABASE_HOST}" -P "${DATABASE_PORT}" --silent; do
        # Show some progress
        echo -n '.';
        sleep 1;
    done
    echo "${DATABASE_HOST} is ready"
    # Give it another second.
    sleep 1;
fi