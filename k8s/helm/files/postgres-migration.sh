set -o pipefail

# This script gets included by the migration job that migrates the postgres database from DoguV2 to DoguV3
# see ../templates/postgres-migration-job.yaml for the configuration
echo "Starting postgres migration job"
echo "Source configuration:"
echo "SOURCE_POSTGRESQL_HOST=${SOURCE_POSTGRESQL_HOST}"
echo "SOURCE_POSTGRESQL_PORT=${SOURCE_POSTGRESQL_PORT}"
echo "SOURCE_POSTGRESQL_DATABASE=${SOURCE_POSTGRESQL_DATABASE}"
echo "SOURCE_POSTGRESQL_USERNAME=${SOURCE_POSTGRESQL_USERNAME}"
if [ -n "${SOURCE_POSTGRESQL_PASSWORD:-}" ]; then
  echo "SOURCE_POSTGRESQL_PASSWORD=******"
else
  echo "SOURCE_POSTGRESQL_PASSWORD="
fi

echo "Target configuration:"
echo "TARGET_POSTGRESQL_HOST=${TARGET_POSTGRESQL_HOST}"
echo "TARGET_POSTGRESQL_PORT=${TARGET_POSTGRESQL_PORT}"
echo "TARGET_POSTGRESQL_DATABASE=${TARGET_POSTGRESQL_DATABASE}"
echo "TARGET_POSTGRESQL_USERNAME=${TARGET_POSTGRESQL_USERNAME}"
if [ -n "${TARGET_POSTGRESQL_PASSWORD:-}" ]; then
  echo "TARGET_POSTGRESQL_PASSWORD=******"
else
  echo "TARGET_POSTGRESQL_PASSWORD="
fi

dump_file=$(mktemp /tmp/nexus-postgres-migration.XXXXXX)
trap 'rm -f "$dump_file"' EXIT

echo "Creating source database dump"
PGPASSWORD="${SOURCE_POSTGRESQL_PASSWORD}" pg_dump \
  --format=custom \
  --verbose \
  -h "${SOURCE_POSTGRESQL_HOST}" \
  -p "${SOURCE_POSTGRESQL_PORT}" \
  -U "${SOURCE_POSTGRESQL_USERNAME}" \
  -d "${SOURCE_POSTGRESQL_DATABASE}" \
  -f "$dump_file"

echo "Importing dump into target database"
PGPASSWORD="${TARGET_POSTGRESQL_PASSWORD}" pg_restore \
  --verbose \
  --no-owner \
  --no-acl \
  --exit-on-error \
  --single-transaction \
  -h "${TARGET_POSTGRESQL_HOST}" \
  -p "${TARGET_POSTGRESQL_PORT}" \
  -U "${TARGET_POSTGRESQL_USERNAME}" \
  -d "${TARGET_POSTGRESQL_DATABASE}" \
  "$dump_file"

echo "Successfully migrated the Nexus database to a new postgres"
exit 0
