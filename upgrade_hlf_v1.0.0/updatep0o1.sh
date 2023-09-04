 #!/bin/bash

 # stopping the 'peer0.org1.example.com' container
 docker stop peer0.org1.example.com

 # For backing up the ledger data
 # docker cp source_file_path destination_file_path
 docker cp peer0.org1.example.com:/var/hyperledger/production/ backup/peer0.org1/

 # For backing up the MSP data
 # cp -r source_file_path destination_file_path
 cp -r organizations/peerOrganizations/org1.example.com backup/organizations/peerOrganizations


# fetching the REPOSITORY (image_name) for the peer0.org1.example.com chaincode image
 CC_IMAGE=$(docker images | grep dev-peer0.org1.example.com | awk '{print $1}')

# # removing the chaincode image
 docker rmi -f $CC_IMAGE

 # removing the 'peer0.org1.example.com' container
 docker rm -f peer0.org1.example.com

 # inside 'test-network/compose/compose-test-net.yaml' file
 # modify 'image' field of 'peer0.org1.example.com' service
 # image: hyperledger/fabric-peer:2.5.2
 sed -i 's/image: hyperledger\/fabric-peer:.*/image: hyperledger\/fabric-peer:2.5.2/' compose/compose-test-net.yaml


# inside 'test-network/compose/compose-test-net.yaml' file
# modify 'volumes' section of 'peer0.org1.example.com' service
# Define the new volumes section
new_volumes="      - ../backup/organizations/peerOrganizations/org1.example.com/peers/peer0.org1.example.com:/etc/hyperledger/fabric
      - ../backup/peer0.org1:/var/hyperledger/production
      - ./docker/peercfg:/etc/hyperledger/peercfg
      - /var/run/docker.sock:/host/var/run/docker.sock"

# Define the path to your YAML file
yaml_file="compose/compose-test-net.yaml"

# Use awk to replace the volumes section in the YAML file with proper indentation
awk -v new_volumes="$new_volumes" '
  /^services:/ { services=1 }
  services && /^  peer0.org1.example.com:/ { peer0_org1=1 }
  peer0_org1 && /^    volumes:/ {
    print
    while (getline) {
      if (/^[[:space:]]*-/) {
        continue
      } else {
        print new_volumes
        peer0_org1=0
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

# add these in the 'environment' section of 'peer0.org1.example.com' service
# the below environment variables are taken from 'test-network/compose/docker/docker-compose-test-net.yaml' file
# - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
# - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=fabric_test

# Define the environment variables to add
new_env_vars="      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=fabric_test"

# Define the path to your YAML file
yaml_file="compose/compose-test-net.yaml"

# Create a temporary file to store the modified YAML content
tmp_file="$yaml_file.tmp"

# Use awk to process the YAML file and insert the new environment variables
awk -v new_env_vars="$new_env_vars" '
  /^services:/ { services=1 }
  services && /^  peer0.org1.example.com:/ { peer0_org1=1 }
  peer0_org1 && /^    environment:/ {
    print
    print new_env_vars
    in_env=1
    while (getline) {
      if (/^[[:space:]]*-/) {
        print
        continue
      } else if (in_env && /^[[:space:]]*#/) {
        print
        continue
      } else {
        peer0_org1=0
        in_env=0
        break
      }
    }
  }
  1
' "$yaml_file" > "$tmp_file"

# Rename the temporary file to the original filename
mv "$tmp_file" "$yaml_file"

echo "Environment variables added successfully in $yaml_file"

sleep 5

# launching the 'peer0.org1.example.com' service using the 'compose-test-net.yaml' file
# docker-compose -f configuration_file_path up -d service_name
docker-compose -f compose/compose-test-net.yaml up -d peer0.org1.example.com

# inspecting containers after upgrading the 'peer0.org1.example.com' service 
docker ps -a