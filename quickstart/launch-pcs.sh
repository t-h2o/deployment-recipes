POWER_CONTROL_BIN="power-control"
KEYS_PATH="keys"

export SMS_SERVER="http://localhost:27779"
export VAULT_ENABLED=true
export VAULT_ADDR="http://localhost:8200"
export VAULT_KEYPATH="secret/hms-creds" # hms-creds
export API_URL="http://localhost"
export API_SERVER_PORT="28007"
export API_BASE_PATH="/v1"
export CRAY_VAULT_JWT_FILE="${KEYS_PATH}"/token
export CRAY_VAULT_ROLE_FILE="${KEYS_PATH}"/role
export CRAY_VAULT_AUTH_PATH=auth/jwt/login
export LOG_LEVEL=DEBUG1

# From pcs Dockerfile
export SERVICE_RESERVATION_VERBOSITY="DEBUG"
export TRS_IMPLEMENTATION="LOCAL"
export STORAGE="ETCD"
export ETCD_HOST="localhost"
export ETCD_PORT="2379"
export HSMLOCK_ENABLED="true"

# From pcs docker-compose.test.ct.yaml
export VAULT_TOKEN="hms"
export VAULT_SKIP_VERIFY=true
export PCS_POWER_SAMPLE_INTERVAL="5"

./${POWER_CONTROL_BIN}
