curl -s -X DELETE -H "Authorization: Bearer $(<access_token)" http://localhost:3000/redfish/x1000c0s0b1 | jq
curl -s -H "Authorization: Bearer $(<access_token)" http://localhost:3000/redfish | jq

curl -s -H "Authorization: Bearer $(<access_token)" -H "Content-Type: application/json" http://localhost:3000/redfish \
-d '{"RedfishEndpoints":[{
  "ID":"x1000c0s0b1",
  "FQDN":"x1000c0s0b1",
  "RediscoverOnUpdate":true,
  "User":"root",
  "Password":"root_password"
}]}'

curl -s -H "Authorization: Bearer $(<access_token)" http://localhost:3000/redfish | jq
curl -s -H "Authorization: Bearer $(<access_token)" http://localhost:3000/node/x1000c0s0b1n0/power-off | jq
curl -s -H "Authorization: Bearer $(<access_token)" http://localhost:3000/node/x1000c0s0b1n0/power-on | jq
