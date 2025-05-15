#!/bin/bash

export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=hms
export SUSHY_URL="http://localhost:8000"

HOSTS_FILE="/etc/hosts"
DOMAIN_NAME="foobar.openchami.cluster"

KEYS_PATH="keys"

docker_yml=(
	"base"
	"volumes-certs"
	"postgres"
	"jwt-security"
	"haproxy-api-gateway"
	"openchami-svcs"
	"autocert"
	"coredhcp"
	"pcs"
	"vault"
	"etcd"
	"rfe"
	"sushy"
	"manta"
	"configurator"
)

_get_docker_list() {
	for yml in ${docker_yml[@]}; do
		echo "-f ${yml}.yml"
	done
}

_manta_configs() {
	mkdir -p configs-manta
	cat >configs-manta/config.toml <<-EOF
		log = "info"

		site = "ochami"

		parent_hsm_group = "nodes_free"

		audit_file = "/tmp/manta_audit.log"

		[sites]

		[sites.ochami]

		backend = "ochami"

		shasta_base_url = "https://${DOMAIN_NAME}:443"
		root_ca_cert_file = "/root/cacert.pem"
	EOF
}

prestart_service() {
	_manta_configs

	local LIST_YAML=("-f" "autocert.yml" "-f" "acme-register.yml" "-f" "volumes-certs.yml")
	docker compose \
		"${LIST_YAML[@]}" \
		up -d

	while IFS= read -r result; do
		break
	done < <(docker events --filter "container=${DOMAIN_NAME}" --filter "event=die")

	docker compose \
		"${LIST_YAML[@]}" \
		down
}

start_service() {
	until docker compose \
		$(_get_docker_list) \
		up -d; do
		docker compose \
			$(_get_docker_list) \
			down
	done
}

generate_file() {
	source bash_functions.sh
	gen_access_token >access_token
	get_ca_cert >cacert.pem
}

vault_configure_jwt() {
	if docker exec -e VAULT_TOKEN=$VAULT_TOKEN vault vault auth list --format json | jq -e 'has("jwt/")'; then
		return
	fi

	docker exec -e VAULT_TOKEN=$VAULT_TOKEN vault vault auth enable -path=jwt jwt
	docker exec -e VAULT_TOKEN=$VAULT_TOKEN vault vault write auth/jwt/role/test-role policies="metrics" user_claim="sub" role_type="jwt" bound_audiences="test"
	cat >policy.yml <<-\EOF
		path "secret/hms-creds" {
		capabilities = ["read", "list"]
		}
	EOF
	docker cp policy.yml vault:/policy.yml
	docker exec -e VAULT_TOKEN=hms vault vault policy write metrics /policy.yml
	docker cp $KEYS_PATH/public_key.pem vault:/public_key.pem
	docker exec -e VAULT_TOKEN=hms vault vault write auth/jwt/config jwt_supported_algs=RS256 jwt_validation_pubkeys=@/public_key.pem
}

vault_create_keystore() {
	docker exec -e VAULT_TOKEN=$VAULT_TOKEN vault vault secrets disable secret
	docker exec -e VAULT_TOKEN=$VAULT_TOKEN vault vault secrets enable \
		-path "secret/hms-creds" \
		-version=1 kv
}

smd_populate() {
	# populate like this [docker compose][1] do
	# 1: https://github.com/OpenCHAMI/power-control/blob/main/docker-compose.test.ct.yaml#L108

	curl -X POST -d '{"RedfishEndpoints":[{
	  "ID":"x1000c0s0b1",
	  "FQDN":"x1000c0s0b1",
	  "RediscoverOnUpdate":true,
	  "User":"root",
	  "Password":"root_password"
	}]}' http://localhost:27779/hsm/v2/Inventory/RedfishEndpoints
}

add_ip_domain_name() {
	if [ -e "${HOSTS_FILE}" ] && ! grep "${DOMAIN_NAME}" "${HOSTS_FILE}" >/dev/null; then
		echo "127.0.0.1 ${DOMAIN_NAME}" | sudo tee -a "${HOSTS_FILE}" >/dev/null
	fi
}

main() {
	prestart_service
	start_service
	generate_file
	vault_configure_jwt
	vault_create_keystore
	smd_populate
	add_ip_domain_name
	docker cp cacert.pem manta-ws:/root
}

main
