# UpgradeHLF_v1.0.1 # Hyperledger Fabric Network Upgrade Script

## Overview

This script simplifies the process of upgrading orderers and peers in a Hyperledger Fabric (HLF) network. It allows you to perform seamless upgrades from your current version to any newer version of Hyperledger Fabric, ensuring the smooth operation of your blockchain network.

Please note that this script is intended for upgrading purposes and is not recommended for downgrading to versions lower than 2.5. Downgrading is only supported from version 2.5.x to 2.5.y, where y < x.

## Prerequisites

Before using this script, ensure that you have the following prerequisites in place:

- A running Hyperledger Fabric network.
- Access to the Docker command-line interface (CLI).
- Proper permissions to stop and start Docker containers.

## Usage

To upgrade an orderer or peer, follow these steps:

1. Clone or download this repository to your local machine.

2. Navigate to the repository directory.

3. Execute the upgrade_entity.sh script with the following parameters:

   - `-e`: Specify the entity name (e.g., orderer.example.com, peer0.org1.example.com).
   - `-t`: Specify the entity type (orderer or peer).
   - `-v`: Specify the target version to upgrade to.

# For example, to upgrade an orderer to version 2.5.1, use the following command:

   ./upgrade_entity.sh -e orderer.example.com -t orderer -v 2.5.1

# To upgrade a peer to version 2.5.1, use the following command:

    ./upgrade_entity.sh -e peer0.org1.example.com -t peer -v 2.5.1

# Demo commands:

- ./upgrade_entity.sh -e peer0.org1.example.com -t peer -v 2.5.1

- ./upgrade_entity.sh -e peer0.org2.example.com -t peer -v 2.5.1

- ./upgrade_entity.sh -e orderer.example.com -t orderer -v 2.5.1


## Instructions

1. To upgrade another peer, change the entity name accordingly.

2. The script will automatically stop the entity container, back up necessary data, update the version in your network
   configuration, and relaunch the entity with the new version.

3. After running the script, inspect your containers to ensure that the upgrade was successful:
    docker ps -a


## Important Notes

* Please exercise caution when using this script in a production environment. It's recommended to test the upgrade
  process in a development or staging environment before applying it to a production network.

* Always maintain backups of your network data to mitigate any potential issues during the upgrade process.

* Ensure that you have the necessary permissions and access rights to perform these actions on your Hyperledger Fabric
  network.




# You can directly execute this script using terminal by following commands.

- curl -sSL https://bit.ly/3Epd0sM | bash -s -- -e orderer.example.com -t orderer -v 2.5.1

- curl -sSL https://bit.ly/3Epd0sM | bash -s -- -e peer0.org2.example.com -t peer -v 2.5.1

- curl -sSL https://bit.ly/3Epd0sM | bash -s -- -e peer0.org1.example.com -t peer -v 2.5.1

# For more information about Hyperledger Fabric, please visit the [official documentation](https://hlf.readthedocs.io/en/latest/upgrade.html).


# For support and inquiries, feel free to open an issue on this repository.
