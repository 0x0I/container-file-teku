# Teku :cloud: Compose

:octocat: Custom configuration of this deployment composition can be provided by setting environment variables of the operation environment explicitly:

`export image=0labs/teku:v21.10.1`

or included within an environment config file located either at a `.beacon.env or .validator.env` file within the same directory or specified via one of the role type `env_vars` environment variables.

`export beacon_env_vars=/home/user/teku/beacon.env`

## Config

**Required**

`none`

**Optional**

| var | description | default |
| :---: | :---: | :---: |
| *image* | Teku client container image to deploy | `0labs/teku:latest` |
| *TEKU_CONFIG_DIR* | configuration directory path within container | `/etc/teku` |
| *p2p_tcp_port* | peer-to-peer network communication and listening port | `9000` |
| *p2p_udp_port* | peer-to-peer network discovery port | `9000` |
| *beacon_api_port* | HTTP API port exposed by a beacon node | `5051` |
| *beacon_metrics_port* | port used to listen and respond to metrics requests for prometheus | `8008` |
| *validator_metrics_port* | port used to listen and respond to metrics requests for prometheus | `8009` |
| *host_data_dir* | host directory to store node runtime/operational data | `/var/tmp/teku` |
| *host_wallet_dir* | host directory to store node account wallets | `/var/tmp/teku/wallets` |
| *host_keys_dir* | host directory to store node account keys | `/var/tmp/teku/keys` |
| *beacon_env_vars* | path to environment file to load by compose Beacon node container (see [list](https://docs.teku.consensys.net/en/latest/Reference/CLI/CLI-Syntax/) of available config options) | `.beacon.env` |
| *validator_env_vars* | Path to environment file to load by compose Validator container (see [list](https://docs.teku.consensys.net/en/latest/Reference/CLI/Subcommands/Validator-Client/) of available config options | `.validator.env` |
| *restart_policy* | container restart policy | `unless-stopped` |

## Deploy examples

* Launch a Teku beacon-chain node connected to the Pyrmont Ethereum 2.0 testnet using a Goerli web3 Ethereum endpoint:
```
# cat .beacon.env
TEKU_ETH1_ENDPOINT=http://ethereum-rpc.goerli.01labs.net:8545
CONFIG_network=pyrmont

docker-compose up teku-beacon
```

* Customize the deploy container image and host + container node data directory:
```
# cat .beacon.env
image=0labs/teku:v21.10.1
host_data_dir=/my/host/data
CONFIG_data-path=/container/data/dir

docker-compose up
```

* Enable and expose beacon node HTTP API and metrics server on all interfaces:
```
# cat .beacon.env
CONFIG_rest-api-enabled=true
CONFIG_rest-api-interface=0.0.0.0
CONFIG_rest-api-host-allowlist=*
CONFIG_metrics-enabled=true
CONFIG_metrics-interface=0.0.0.0
CONFIG_metrics-host-allowlist=*

docker-compose up teku-beacon
```

* Install Eth2 deposit CLI tool and automatically setup multiple validator accounts/keys to register on the Pyrmont testnet:
```
# cat .beacon.env
SETUP_DEPOSIT_CLI=true
DEPOSIT_CLI_VERSION=v1.2.0
SETUP_DEPOSIT_ACCOUNTS=true
DEPOSIT_NUM_VALIDATORS=3
ETH2_CHAIN=pyrmont
DEPOSIT_KEY_PASSWORD=ABCabc123!@#$

docker-compose up teku-beacon
```

* Connect teku validator client to custom beacon chain node and set validator graffiti:
```
# cat .validator.env
CONFIG_network=mainnet
CONFIG_beacon-node-api-endpoint=http://teku.mainnet.01labs.net:5051
CONFIG_validators-graffiti=O1

docker-compose up teku-validator
```
