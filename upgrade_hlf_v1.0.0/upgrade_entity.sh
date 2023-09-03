#!/bin/bash

#To upgrade orderer and peers

#upgrade_entity.sh -e "$entity_name" -t "$entity_type" -v "$version"

# ./upgrade_entity.sh -e orderer.example.com -t orderer -v 2.5.1

# ./upgrade_entity.sh -e peer0.org1.example.com -t peer -v 2.5.1

# ./upgrade_entity.sh -e peer0.org2.example.com -t peer -v 2.5.1



# "Function to create backup folders if they don't exist"
create_backup_folders() {
  if [ ! -d "backup/organizations" ]; then
    mkdir -p backup/organizations
  fi

  if [ ! -d "backup/organizations/ordererOrganizations" ]; then
    mkdir -p backup/organizations/ordererOrganizations
  fi

  if [ ! -d "backup/organizations/peerOrganizations" ]; then
    mkdir -p backup/organizations/peerOrganizations
  fi
}

# "start"

# "# Function to upgrade an entity (orderer or peer)"
upgrade_entity() {
  entity_name="$1"
  entity_type="$2"  # "orderer" or "peer"
  version="$3"

  # "# Extract part"
  peer_name=$(echo "$entity_name" | cut -d'.' -f1,2)
  org_name=$(echo "$entity_name" | cut -d'.' -f2)
  input=$entity_name
  # "# Remove ".example.com""
  output=$(echo "$input" | sed 's/\.example\.com//')
  # "# Replace dots with underscores"
  entity_id="${output//./_}"

  # "# Stopping the entity container (if running)"
  docker stop $entity_name
  # "# For backing up the ledger data"
  if [ "$entity_type" == "orderer" ]; then
    docker cp $entity_name:/var/hyperledger/production/${entity_type}/ backup/${entity_type}/

    # "# For backing up the MSP data"
    cp -r organizations/${entity_type}Organizations/example.com backup/organizations/${entity_type}Organizations 
  fi

  # "# For backing up the ledger data"
  if [ "$entity_type" == "peer" ]; then
    docker cp $entity_name:/var/hyperledger/production/ backup/${peer_name}/

    # "# For backing up the MSP data"
    cp -r organizations/${entity_type}Organizations/${org_name}example.com backup/organizations/${entity_type}Organizations
  fi

  if [ "$entity_type" == "peer" ]; then
    # "# Fetching the REPOSITORY (image_name) for the peer chaincode image"
    CC_IMAGE=$(docker images | grep "dev-$entity_name" | awk '{print $1}')

    # "# Removing the chaincode image"
    docker rmi -f $CC_IMAGE
  fi

  # "# Removing the entity container"
  docker rm -f $entity_name

  # "# Modify 'image' field of entity service in compose-test-net.yaml"
  sed -i "s/image: hyperledger\/fabric-${entity_type}:.*/image: hyperledger\/fabric-${entity_type}:$version/" compose/compose-test-net.yaml

  # "# Define the new volumes section"
  if [ "$entity_type" == "orderer" ]; then
    new_volumes="      - ../backup/organizations/${entity_type}Organizations/example.com/${entity_type}s/$entity_name/msp:/var/hyperledger/${entity_type}/msp
      - ../backup/organizations/${entity_type}Organizations/example.com/${entity_type}s/$entity_name/tls/:/var/hyperledger/${entity_type}/tls
      - ../backup/${entity_type}:/var/hyperledger/production/${entity_type}"
  fi

  if [ "$entity_type" == "peer" ]; then
    new_volumes="      - ../backup/organizations/peerOrganizations/${org_name}.example.com/${entity_type}s/${entity_name}:/etc/hyperledger/fabric
      - ../backup/${peer_name}:/var/hyperledger/production
      - ./docker/peercfg:/etc/hyperledger/peercfg
      - /var/run/docker.sock:/host/var/run/docker.sock"
  fi

  yaml_file="compose/compose-test-net.yaml"

  if [ "$entity_type" == "orderer" ]; then
    # Use awk to replace the volumes section in the YAML file with proper indentation
    awk -v new_volumes="$new_volumes" '
     /^services:/ { services=1 }
    services && /^  '"$entity_name"':/ { '"${entity_type}"'=1 }
    '"${entity_type}"' && /^    volumes:/ {
      print
      while (getline) {
        if (/^[[:space:]]*-/) {
          continue
        } else {
          print new_volumes
          '"${entity_type}"'=0
          break
        }
      }
    }
    /^    -/ { next }  # Skip any existing volume lines
    1
    ' "$yaml_file" > "$yaml_file.tmp"
  fi

  if [ "$entity_type" == "peer" ]; then
    # Use awk to replace the volumes section in the YAML file with proper indentation
    awk -v new_volumes="$new_volumes" '
    /^services:/ { services=1 }
    services && /^  '"$entity_name"':/ { '"${entity_id}"'=1 }
    '${entity_id}' && /^    volumes:/ {
      print
      while (getline) {
        if (/^[[:space:]]*-/) {
          continue
        } else {
          print new_volumes
          '${entity_id}'=0
          break
        }
      }
    }
    /^    -/ { next }  # Skip any existing volume lines
    1
    ' "$yaml_file" > "$yaml_file.tmp"
  fi
  
  # Rename the temporary file to the original filename
  mv "$yaml_file.tmp" "$yaml_file"

  echo "Volumes section replaced successfully for $entity_name"

  # If it's a peer, add environment variables to the 'environment' section
  if [ "$entity_type" == "peer" ]; then
    new_env_vars="      - CORE_VM_ENDPOINT=unix:///host/var/run/docker.sock
      - CORE_VM_DOCKER_HOSTCONFIG_NETWORKMODE=fabric_test"

    # Use awk to add the environment variables to the YAML file
    awk -v new_env_vars="$new_env_vars" '
      /^services:/ { services=1 }
      services && /^  '"$entity_name"':/ { '${entity_id}'=1 }
      '${entity_id}' && /^    environment:/ {
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
            '${entity_id}'=0
            in_env=0
            break
          }
        }
      }
      1
    ' "$yaml_file" > "$yaml_file.tmp"
     # Rename the temporary file to the original filename
      mv "$yaml_file.tmp" "$yaml_file"
  fi

 

  echo "Environment variables added successfully for $entity_name"

  # Launch the entity service using the 'compose-test-net.yaml' file
  docker-compose -f "$yaml_file" up -d $entity_name

  # Inspect containers after upgrading the entity service
  docker ps -a
}

# Parse command line arguments to get the entity name, type (orderer or peer), and version
while getopts "e:t:v:" opt; do
  case "$opt" in
    e) entity_name="$OPTARG" ;;
    t) entity_type="$OPTARG" ;;
    v) version="$OPTARG" ;;
    *) echo "Invalid option: -$opt"; exit 1 ;;
  esac
done

# Create backup folders if they don't exist
create_backup_folders

# Upgrade the specified entity
upgrade_entity "$entity_name" "$entity_type" "$version"