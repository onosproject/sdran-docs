<!--
SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>

SPDX-License-Identifier: Apache-2.0
-->

# SD-RAN 1.0 Release Notes

## Highlights
The first release of the [SD-RAN project](https://opennetworking.org/sd-ran/) implements a minimal [O-RAN compliant](https://www.o-ran.org/) end-to-end mobile RAN stack. It includes a near-Real-Time Ran-Intelligent-Controller (nRT-RIC) based on [micro-ONOS](https://docs.onosproject.org/), which interacts with RAN hardware (E2 nodes) via O-RAN compliant interfaces (E2AP), encodings (ASN.1), transport-protocols (SCTP) and Service Models (SMs). The release also includes a white-box based CU/DU/RU solution, leveraging [OAI software](https://gitlab.eurecom.fr/oai/openairinterface5g) that has been enhanced to expose the same O-RAN compliant interfaces and protocols.

For end-to-end integration, the RAN components interact with Samsung Android handsets as well as OAI User Element (UE) software. For EPC integration, the RAN components interact with ONF’s [OMEC mobile core](https://opennetworking.org/omec/). To integrate with ONOS-RIC, the CU-CP RAN component has been enhanced with an E2 Agent that exposes the KPM-SM information-elements when subscribed for by a corresponding xAPP running on the RIC. This release also includes the beginnings of an app-SDK which can ease the process of creating xAPPs that are portable across different RIC platforms.

Finally, while the solution can be instantiated on reference white-box hardware (as noted below), it can also be experienced entirely in a virtualized form, in a VM or server, using RiaB (sdRAN-in-a-Box). The entire stack including xAPP, ONOS-RIC components, CU/DU, UE and OMEC can be instantiated within RiaB with a few simple commands.

## Features and Improvements

### micro-ONOS based nRT-RIC (ONOS-RIC)

* onos-e2t
  * Implements SB E2AP 1.0 / SCTP termination
    * Provides a Protobuf interface to E2AP
    * Performs translation of ASN.1 to/from Proto
  * Integrates with onos-e2sub for registration and for retrieval of application subscription requests; supports subscription add/delete operations
  * Integrates with applications (via SDK) to distribute incoming E2 indications and to relay outbound E2 messages
  * Provides configuration to allow external connections from E2 nodes
* onos-e2-sm
  * Provides Protobuf interface to E2 Service Models
  * Translates from Protobuf to/from ASN.1 UPER encoding
  * Accessible as a plugin (for onos-e2t) or a Go module (for xApps)
  * Supporting KPM Service Model 1.0 only
* onos-e2sub
  * Implements E2T registry as an intermediary for use by the SDK (and hence apps) and by the E2T nodes
  * Implements E2 subscription intermediary for use by the application SDK and by the E2T nodes
  * Manages assignment of subscriptions to E2T nodes
  * Supports distributed operation; 2 nodes should suffice for fail-over capability)
* onos-api
  * Shared repository for all public Protobuf service APIs and gRPC language bindings
  * Go bindings provide client and server interfaces and test libraries for developing all micro-ONOS services
  * Python 3 bindings for all micro-ONOS services with support for asyncio 
* onos-ric-sdk-go
  * Go SDK that manages configuration, logging, service discovery, etc and provides high level abstractions for building applications
  * Clients are provided for each micro-ONOS service — monitor the topology for changes, track and manage subscriptions, connect indication streams, etc
  * Simple mechanism for apps to list existing topology entities and to subsequently watch for future changes in the topology; allows filtering by object types, object kinds and event types
  * Provides a high-level subscription API that handles the complexity of safely managing subscriptions and receiving indications
  * Subscription API supports arbitrary service models
* onos-kpimon-app
  * Simple app that subscribes for CU-CP KPIs and subsequently receives indications from the e2 nodes specifying the number of active UE devices
  * Reads the default configuration using the RIC’s app-SDK, and uses the default configured report period interval in the subscription request
  * Makes the monitored result (i.e., the number of active UEs) available through CLI
* onos-config
  * Define an initial configuration model for configuration of onos-kpimon xApp (i.e. configuration of report period interval)
  * Implements a preliminary facility (via gNMI agent) for configuring of xApps
  * Upgraded model plugins in onos-config to use latest version of ygot
* onos-topo
  * Provides means to store and traverse topology information represented via entity-relationship scheme. Offers basic CRUD and watch for change capabilities
  * Deprecated “devices” API is now removed
* sdran-cli
  * Provides a command line interface (CLI) that allows interaction with components from a shell
  * Published as a separate docker image that can be loaded into the cluster
  * Useful for monitoring, debugging, and scripting
* atomix/go-client
  * Go client library for Atomix that provides a set of high-level primitives for building scalable, reliable distributed stores in micro-ONOS services and applications 
  * Distributed data structures like Map, IndexedMap, and Set form the basis for distributed stores in onos-topo, onos-config, onos-e2sub, etc
  * Distributed concurrency primitives like LeaderElection, Lock, and Counter are used in micro-ONOS services to coordinate consistent, reliable, and scalable protocols for communication between micro-ONOS services
  * Interfaces with the Atomix controller for service discovery, cluster membership, and managing peer-to-peer interactions within micro-ONOS services
* atomix/kubernetes-controller
  * Automates the management of databases used to persist state in micro-ONOS services (onos-topo, onos-config, onos-e2t, onos-e2sub) and coordinate across nodes and between micro-ONOS services (e.g. leadership/mastership election, cluster membership)
  * Extends the Kubernetes API with custom Database, Partition, Member, and Primitive resources for facilitating the Atomix deployment and applications
  * Provides a set of custom Kubernetes controllers for managing Atomix databases and partitions and provides service discovery to Atomix clients
  * Provides a framework for extending Atomix with storage plugins, allowing micro-ONOS services to store and distribute state according to their requirements
* atomix/raft-storage-controller
  * A storage plugin for Atomix that provides for storing and replicating Atomix primitives using a strongly consistent, sharded consensus protocol: Raft
  * Supports storage nodes based on several mature Raft implementations: Dragonboat, etcd, and Consul 
* atomix/cache-storage-controller
  * A storage plugin for Atomix that provides a fast in-memory cache for storing distributed primitives

### ONF/OAI CU-CP & White-Box RAN hardware

* [Ettus B210 USRP](https://www.ettus.com/all-products/ub210-kit/), [Enclosure kit](https://www.ettus.com/all-products/usrp-b200-enclosure/), Intel NUC10i7FNH, [Taoglas TG.45.8113](https://www.digikey.com/en/products/detail/taoglas-limited/TG-45-8113/9972822)
* Samsung Android smartphone (J5) 
* [OAI UE and OAI RU/DU/CU](https://gitlab.eurecom.fr/oai/openairinterface5g) (covered by [OAI Public License v1.1](https://www.openairinterface.org/legal/oai-public-license/)) split mode over Band 7 FDD with ONF enhancements for CU-CP and E2 Agent (available as Docker image covered under [ONF Member-only software license](https://opennetworking.org/wp-content/uploads/2020/06/ONF-Member-Only-Software-License-v1.0.pdf))
* CU-CP E2 Agent supports for the relevant Ran Function (KPM-SM):
  * E2 setup request and response, but not failure
  * Subscription request and response, but not failure
  * Indications of type REPORT
* The ONOS-E2T micro-service supports remote connections from White-Box RAN hardware

### SDRAN-in-a-Box (RiaB)
* Provides dev/test environment for SD-RAN project
* Installs K8s and Helm, required infrastructure for SD-RAN services
* Deploys OMEC-CP, OMEC-UP, Quagga router for the EPC network which can communicate with the RAN device/software
* Deploys a choice of two types of RAN software: (i) CU-CP/UP, OAI DU, and UE; (ii) RanSim
* Deploys Atomix and ONOS-RIC micro-services, i.e., ONOS-E2T, ONOS-E2Sub, ONOS-Topo, ONOS-Config, and ONOS-KPIMON
* Provides functionalities to test the user plane and KPIMON xApplication

### RanSim
* Implements Client interface for implementing of E2AP procedures in E2 agent
* Implements E2 Setup procedure in E2 agent
* Implements a preliminary subscription handler for KPM service model
* Supports a preliminary implementation of sending indication messages for KPM service model

## Test
* Continuous Integration (CI) testing
  * Run on travis-ci.com with triggers provided by GitHub
  * Three levels of CI testing:
    * Pull request verification: Each time new code is submitted to the repo, unit tests and static analysis tests are run against the new code. PRs are not merged unless these tests pass.
    * Merge commit verification: When a PR is merged, the tests are run again to be sure no incompatible changes have been made since the PR was submitted. If any docker images are required for the component, a new 'latest' image is produced and pushed to docker hub. If the version of the component was changed, the source tree is tagged with the new version, and tagged versions of any docker images are produced.
    * Nightly verification: Once a day, the integration tests and smoke tests are run against the latest sources in all the repos.
  * The Travis CI testing dashboard for ONOS SDRAN is available [here](https://travis-ci.com/github/onosproject/onos-test)
* Integration tests
  * Using the helmit testing framework, these tests load clusters from the helm charts and test API functionality using automation
  * Tests for CLI, e2 termination, topology, configuration gNMI, and configuration management
  * The onos-e2t integration tests use a ran-simulator to test subscription procedure and receiving of indication messages using SDK. 
  * Run nightly as part of CI on VM based kubernetes clusters and on hardware based clusters
  * Integration tests are kept in the repositories of the components they are testing: onos-e2t, onos-topo, onos-config
* Smoke tests
  * Basic tests to assure that all components build and load successfully
  * These tests are "end to end" - that is they use helm to load the cluster, start up a simulated e2 node, then use the ONOS CLI to interrogate the components
  * Driven by shell scripts that can check results to be sure that components are behaving correctly
  * Run nightly as part of CI
  * Source code for these tests is kept in the onos-test repo
* Build test
  * A nightly CI job that builds all of the SDRAN components, to be sure that no API changes have broken other components
  * The code for the build test is kept in the onos-test repo
* Automatically generated mocks for Golang are now released as part of the onos-api module
* Robot tests for hardware based QA pods are under development


## Deployment
* sdran-helm-charts
  * ONOS RIC can be installed from the helm charts as shown below:
```bash
# Create Atomix resources
kubectl create -f
https://raw.githubusercontent.com/atomix/kubernetes-controller/0a9e82ef37df25cf567a4dbc18f35b2bb454bda1/deploy/atomix-controller.yaml
kubectl create -f
https://raw.githubusercontent.com/atomix/raft-storage-controller/668951dff14e339f3c71b489863cbca8ec326a96/deploy/raft-storage-controller.yaml
kubectl create -f
https://raw.githubusercontent.com/atomix/cache-storage-controller/85014c6216e3d8cdf22df09aab3d1f16852fc584/deploy/cache-storage-controller.yaml

# Set up onos and sdran repos
helm repo add cord https://charts.opencord.org
helm repo add atomix https://charts.atomix.io
helm repo add onos https://charts.onosproject.org
helm repo add sdran --username "$repo_user" --password "$repo_password" https://sdrancharts.onosproject.org
helm repo update

# Run the sdran chart
helm install sd-ran sdran/sd-ran
```
 * Please [contact ONF](https://opennetworking.org/contact/) for username and password credentials to allow access to the sdran helm chart repo
 * When using RiaB, please refer to the [RiaB documentation](https://docs.sd-ran.org/master/sdran-in-a-box/README.html)

## Documentation

* All release documentation is available at: [docs.sd-ran.org](http://docs.sd-ran.org)
* Please [contact ONF](https://opennetworking.org/contact/) for username and password credentials

## Known Issues
* Subscription deletes are not supported end-to-end
* onos-kpimon xApp configuration cannot be changed dynamically
* RanSim does not dynamically report the number of UEs via the KPM-SM
* OAI-UE does not support reattachment - have to redeploy OAI and SD-RAN charts after manual detachment

## Component Versions

| component | version |
| :--- | ---: |
| onos-api | v0.7.0 |
| onos-ric-sdk-go | v0.7.0 |
| onos-e2-sm | v0.7.0 |
| onos-e2t | v0.7.0 chart 1.0.1-rev1 | 
| onos-e2sub | v0.7.0 chart 1.0.0 | 
| onos-topo | v0.7.0 chart 1.0.0 | 
| onos-config | v0.7.0 chart 1.0.0 |
| ran-simulator | v0.7.0 chart 1.0.0 |
| onos-cli | v0.7.0 chart 1.0.0 |
| onos-kpimon | v0.1.3 chart 0.6.0 |
| cu-cp | v0.1.0 chart 0.1.0 |
| oai du | v0.1.0 chart 0.1.0 |
| oai ue | v0.1.0 chart 0.1.0 |
| sdran-in-a-box | v1.0.0 |


