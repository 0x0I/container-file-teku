<p><img src="https://avatars1.githubusercontent.com/u/12563465?s=200&v=4" alt="OCI logo" title="oci" align="left" height="70" /></p>
<p><img src="https://pbs.twimg.com/profile_images/1324063968877563907/n-NYkVty.png" alt="teku logo" title="teku" align="right" height="80" /></p>

Container File 🔰🔗 Teku
=========
![GitHub release (latest by date)](https://img.shields.io/github/v/release/0x0I/container-file-teku?color=yellow)
[![0x0I](https://circleci.com/gh/0x0I/container-file-teku.svg?style=svg)](https://circleci.com/gh/0x0I/container-file-teku)
[![Docker Pulls](https://img.shields.io/docker/pulls/0labs/teku?style=flat)](https://hub.docker.com/repository/docker/0labs/teku)
[![License: MIT](https://img.shields.io/badge/License-MIT-blueviolet.svg)](https://opensource.org/licenses/MIT)

Configure and operate Teku: an open-source Ethereum 2.0 client written in Java

**Overview**
  - [Setup](#setup)
    - [Build](#build)
    - [Config](#config)
  - [Operations](#operations)
  - [Examples](#examples)
  - [License](#license)
  - [Author Information](#author-information)

#### Setup
--------------
Guidelines on running service containers are available and organized according to the following software & machine provisioning stages:
* _build_
* _config_
* _operations_

#### Build

##### args

| Name  | description |
| ------------- | ------------- |
| `build_version` | base image to utilize for building application binaries/artifacts |
| `build_type` | type of application build process (i.e. build from *source* or *package*) |
| `teku_version` | `teku` application version to build within image |
| `goss_version` | `goss` testing tool version to install within image test target |
| `version` | container/image infra application version |

```bash
docker build --build-arg <arg>=<value> -t <tag> .
```

##### targets

| Name  | description |
| ------------- | ------------- |
| `builder` | image state following build of teku binary/artifacts |
| `test` | image containing test tools, functional test cases for validation and `release` target contents |
| `release` | minimal resultant image containing service binaries, entrypoints and helper scripts |

```bash
docker build --target <target> -t <tag> .
```

#### Config

:page_with_curl: Configuration of the `teku` client can be expressed in a config file written in [YAML](https://yaml.org/), a minimal markup format, used as an alternative to passing command-line flags at runtime or expressed by exposing environment variables exported explicitly (**i.e.** `export TEKU_NETWORK=mainnet`) or sourced from an environment var file to its runtime. Guidance on and a list of configurable settings can be found [here](https://docs.teku.consensys.net/en/latest/Reference/CLI/CLI-Syntax/#specifying-options).

_The following variables can be customized to manage the location and content of this YAML configuration as well as the set of variables included within the client's runtime environment:_

`$TEKU_CONFIG_DIR=</path/to/configuration/dir>` (**default**: `/etc/teku`)
- container path where the `teku` YAML configuration should be maintained

  ```bash
  TEKU_CONFIG_DIR=/mnt/etc/teku
  ```

`$CONFIG_<setting> = <value (string)>` **default**: *None*

- Any configuration setting/value key-pair supported by `teku` should be expressible and properly rendered within the associated YAML config.

    `<setting>` -- represents a YAML config setting:
    ```bash
    # [YAML Setting 'metrics-enabled']
    CONFIG_metrics-enabled=<value>
    ```

    `<value>` -- represents setting value to configure:
    ```bash
    # [YAML Setting 'metrics-enabled']
    # Setting: metrics-enabled
    # Value: true
    CONFIG_metrics-enabled=true
    ```

_Additionally, the content of the YAML configuration file can either be pregenerated and mounted into a container instance:_

```bash
$ cat custom-config.yml
network: mainnet
data-path: "/mnt/data"
eth1-endpoint: "https://mainnet.infura.io/v3/YOUR-PROJECT-ID"

# mount custom config into container
$ docker run --mount type=bind,source="$(pwd)"/custom-config.yml,target=/tmp/config.yml 0labs/teku:latest teku --config-file /tmp/config.yml
```

_...or developed from both a mounted config and injected environment variables (with envvars taking precedence and overriding mounted config settings):_

```bash
$ cat custom-config.yml
network: mainnet
data-path: "/mnt/data"
eth1-endpoint: "https://mainnet.infura.io/v3/YOUR-PROJECT-ID"

# mount custom config into container
$ docker run -it --env TEKU_CONFIG_DIR=/tmp/teku --env CONFIG_eth1-endpoint=http://localhost:8545 --env CONFIG_data-path=/custom/data \
  --mount type=bind,source="$(pwd)"/custom-config.yml,target=/tmp/teku/config.yml \
  0labs/teku:latest teku --config /tmp/teku/config.yml
```

_Moreover, see [here](https://docs.teku.consensys.net/en/latest/Reference/CLI/CLI-Syntax/#teku-command-line) for a list of supported flags to set as runtime command-line flags._

```bash
# connect to Prater Eth2 testnet and enable the REST API service
docker run 0labs/teku:latest teku --network=prater --rest-api-enabled=true
```

**Also, note:** as indicated in the linked documentation, CLI flags generally translate into configuration settings by removing the preceding `--` flag marker.

_...and reference below for network/chain identification and communication configs:_ 

###### port mappings

| Port  | mapping description | type | config setting | command-line flag | environment variable |
| :-------------: | :-------------: | :-------------: | :-------------: | :-------------: | :-------------: |
| `9000`    | The port used for p2p communication | *TCP*  | `p2p-port` | `--p2p-port` | TEKU_P2P_PORT |
| `9000`    | The port used by discv5 for p2p discovery | *UDP*  | `p2p-udp-port` | `--p2p-udp-port` | TEKU_P2P_UDP_PORT
| `5051`    | REST API listening | *TCP*  | `rest-api-port` | `--rest-api-port` | TEKU_REST_API_PORT |
| `8008`    | Prometheus metrics collection | *TCP*  | `metrics-port` | `--metrics-port` | TEKU_METRICS_PORT |

###### chain id mappings

| name | config setting (eth1-endpoint) | command-line flag |
| :---: | :---: | :---: |
| Mainnet | {mainnet-url} | `--eth1-endpoint={mainnet-url}` |
| Goerli | {goerli-url} | `--eth1-endpont={goerli-url}` |

**note:** only Eth1 endpoints connected to either Mainnet or the Goerli testnet are supported currently.

see [chainlist.org](https://chainlist.org/) for a complete list


#### Operations

:flashlight: To assist with managing a `teku` client and interfacing with the *Ethereum 2.0* network, the following utility functions have been included within the image. *Note:* all tool command-line flags can alternatively be expressed as container runtime environment variables, as described below.

##### Setup deposit accounts and tooling

Download Eth2 deposit CLI tool and setup validator deposit accounts.

`$SETUP_DEPOSIT_CLI=<boolean>` (**default**: `false`)
- whether to download the Eth 2.0 deposit CLI maintained at https://github.com/ethereum/eth2.0-deposit-cli

`$DEPOSIT_CLI_VERSION=<string>` (**default**: `v1.2.0`)
- version of the Eth 2.0 deposit CLI to download

`$ETH2_CHAIN=<string>` (**default**: `mainnet`)
- Ethereum 2.0 chain to register deposit validator accounts and keystores for

`$SETUP_DEPOSIT_ACCOUNTS=<boolean>` (**default**: `false`)
- whether to automatically setup Eth 2.0 validator depositor accounts ([see](https://github.com/ethereum/eth2.0-deposit-cli#step-2-create-keys-and-deposit_data-json) for more details)

`$DEPOSIT_DIR=<path>` (**default**: `/var/tmp/deposit`)
- container directory to generate Eth 2.0 validator deposit keystores

`$DEPOSIT_MNEMONIC_LANG=<string>` (**default**: `english`)
- language to generate deposit mnemonic in 

`$DEPOSIT_NUM_VALIDATORS=<int>` (**default**: `1`)
- count of Eth 2.0 validator deposit keystores to generate

`$DEPOSIT_KEY_PASSWORD=<string>` (**default**: `passw0rd`)
- validator deposit keystore password associated with generated mnemonic

A *validator_keys* directory containing deposit data and the generated validator deposit keystore(s) will be created at the `DEPOSIT_DIR` path.

```bash
ls /var/tmp/deposit/validator_keys
  deposit_data-1632777614.json  keystore-m_12381_3600_0_0_0-1632777613.json
```

##### Query RESTful HTTP API

Execute a RESTful HTTP API request.

```
$ teku-helper status api-request --help
Usage: teku-helper status api-request [OPTIONS]

  Execute RESTful API HTTP request

Options:
  --host-addr TEXT   Teku REST API host address in format
                     <protocol(http/https)>://<IP>:<port>  [default:
                     (http://localhost:5051)]
  --api-method TEXT  HTTP method to execute a part of request  [default:
                     (GET)]
  --api-path TEXT    Restful API path to target resource  [default:
                     (eth/v1/node/identity)]
  --api-data TEXT    Restful API request body data included within POST
                     requests  [default: ({})]
  --help             Show this message and exit.
```

`$API_HOST_ADDR=<url>` (**default**: `localhost:3501`)
- Teku HTTP API host address in format <protocol(http/https)>://<IP>:<port>

`$API_METHOD=<http-method>` (**default**: `GET`)
- HTTP method to execute

`$API_PATH=<url-path>` (**default**: `/eth/v1/node/health`)
- RESTful API path to target resource

`$API_DATA=<json-string>` (**default**: `'{}'`)
- RESTful API request body data included within POST requests

The output consists of a JSON blob corresponding to the expected return object for a given API query. Reference [Teku's HTTP API docs](https://docs.teku.consensys.net/en/latest/Reference/Rest_API/Rest/) for more details.

###### example

```bash
docker exec [--env API_PATH=eth/v1/node/syncing] teku-beacon teku-helper status api-request [--api-path eth/v1/node/syncing]
{
    "data": {
        "head_slot": "2363454",
        "is_syncing": false,
        "sync_distance": "0"
    }
}
```

##### Import validator keystores

Automatically import designated validator keystores and associated password files on startup.

`$SETUP_VALIDATOR=<boolean>` (**default**: `false`)
- whether to attempt to import validator keystores and associated wallets

`$VALIDATOR_KEY=<string>` (**required** if *validator key/password directory details are not provided*)
- validator keystore value in json format

`$VALIDATOR_KEY_PASSWORD=<string>` (**required** if *validator key/password directory details are not provided*)
- validator keystore password

`$VALIDATOR_KEYS_DIR=<directory>` (**required** if *validator key/password file details are not provided*)
- Path to a directory where validator keystores to be imported are stored

`$VALIDATOR_PWD_DIR=<directory>` (**required** if *validator key/password file details are not provided*)
- Path to a directory where validator keystore passwords are stored

`$SECURITY_OUTPUT_DIR=<string>` (**default**: `/var/tmp/teku`)
- directory to store secure/sensitive validator data


Validator keystore/password files will be created at the `$SECURITY_OUTPUT_DIR` as **validator-key.json** and **key-password.txt**, respectively.

```bash
ls /var/tmp/teku
  validator-key.json  key-password.txt
```

See [here](https://docs.teku.consensys.net/en/latest/Reference/CLI/Subcommands/Validator-Client/#validator-keys) for more details.

Examples
----------------

* Launch a Teku beacon-chain node connected to the Pyrmont Ethereum 2.0 testnet using a Goerli web3 Ethereum endpoint:
```
# cat .env
TEKU_ETH1_ENDPOINT=http://ethereum-rpc.goerli.01labs.net:8545
CONFIG_network=pyrmont

docker run --env-file .beacon.env 0labs/teku:latest
```

* Bind-mount and customize the container node data directory:
```
# cat .env
CONFIG_data-path=/container/data

docker run --volume /host/data:/container/data --env CONFIG_data-path=/container/data 0labs/teku:latest
```

* Enable and expose beacon node HTTP API and metrics server on all interfaces:
```
# cat .env
CONFIG_rest-api-enabled=true
CONFIG_rest-api-interface=0.0.0.0
CONFIG_rest-api-host-allowlist=*
CONFIG_metrics-enabled=true
CONFIG_metrics-interface=0.0.0.0
CONFIG_metrics-host-allowlist=*

docker run --env-file .env 0labs/teku:latest
```

* Install Eth2 deposit CLI tool and automatically setup multiple validator accounts/keys to register on the Pyrmont testnet:
```
# cat .env
SETUP_DEPOSIT_CLI=true
DEPOSIT_CLI_VERSION=v1.2.0
SETUP_DEPOSIT_ACCOUNTS=true
DEPOSIT_NUM_VALIDATORS=3
ETH2_CHAIN=pyrmont
DEPOSIT_KEY_PASSWORD=ABCabc123!@#$

docker run --env-file .env 0labs/teku:latest
```

* Connect teku validator client to custom beacon chain node and set validator graffiti:
```
# cat .env
CONFIG_network=mainnet
CONFIG_beacon-node-api-endpoint=http://teku.mainnet.01labs.net:5051
CONFIG_validators-graffiti=O1

docker run --env-file .env 0labs/teku:latest validator-client
```

License
-------

MIT

Author Information
------------------

This Containerfile was created in 2021 by O1.IO.

🏆 **always happy to help & donations are always welcome** 💸

* **ETH (Ethereum):** 0x652eD9d222eeA1Ad843efec01E60C29bF2CF6E4c

* **BTC (Bitcoin):** 3E8gMxwEnfAAWbvjoPVqSz6DvPfwQ1q8Jn

* **ATOM (Cosmos):** cosmos19vmcf5t68w6ug45mrwjyauh4ey99u9htrgqv09
