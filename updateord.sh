# #!/bin/bash

# Creating folder structure for storing orderer MSP data
mkdir -p backup/organizations/ordererOrganizations

# Creating folder structure for storing peer MSP data
mkdir -p backup/organizations/peerOrganizations

# Stopping the 'orderer.example.com' container (if running)
docker stop orderer.example.com

# For backing up the ledger data
docker cp orderer.example.com:/var/hyperledger/production/orderer/ backup/orderer/

# For backing up the MSP data
cp -r organizations/ordererOrganizations/example.com backup/organizations/ordererOrganizations

# Remove the orderer container
docker rm -f orderer.example.com

# Inside 'test-network/compose/compose-test-net.yaml' file
# Modify 'image' field of 'orderer.example.com' service(working)
sed -i 's/image: hyperledger\/fabric-orderer:.*/image: hyperledger\/fabric-orderer:2.5.2/' compose/compose-test-net.yaml



# Define the new volumes section(working)
new_volumes="      - ../backup/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/msp:/var/hyperledger/orderer/msp
      - ../backup/organizations/ordererOrganizations/example.com/orderers/orderer.example.com/tls/:/var/hyperledger/orderer/tls
      - ../backup/orderer:/var/hyperledger/production/orderer "   

# Define the path to your YAML file
yaml_file="compose/compose-test-net.yaml"

# Use awk to replace the volumes section in the YAML file with proper indentation
awk -v new_volumes="$new_volumes" '
  /^services:/ { services=1 }
  services && /^  orderer.example.com:/ { orderer=1 }
  orderer && /^    volumes:/ {
    print
    while (getline) {
      if (/^[[:space:]]*-/) {
        continue
      } else {
        print new_volumes
        orderer=0
        break
      }
    }
  }
  /^    -/ { next }  # Skip any existing volume lines
  1
' "$yaml_file" > "$yaml_file.tmp"

# Rename the temporary file to the original filename
mv "$yaml_file.tmp" "$yaml_file"

 echo "Volumes section replaced successfully in $yaml_file"

# launching the 'orderer.example.com' service using the 'compose-test-net.yaml' file
# docker-compose -f configuration_file_path up -d service_name
docker-compose -f compose/compose-test-net.yaml up -d orderer.example.com

# inspecting containers after upgrading the 'orderer.example.com' service 
docker ps -a