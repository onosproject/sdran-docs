<!--
SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>

SPDX-License-Identifier: Apache-2.0
-->

# SD-RAN 1.2 Release Notes

## Highlights

The third release of the [SD-RAN project](https://opennetworking.org/sd-ran/) highlights successful integration with commercial 5G SA (stand alone) DU and CU software from Radisys. This builds on the successful integration of commercial 3rd party xApps (AirHop’s eSON server) achieved in the previous SD-RAN release.

ONF’s [micro-ONOS](https://docs.onosproject.org/) based nRT-RIC and Radisys [5G NR Software](https://www.radisys.com/connect/connectran/5g) were integrated successfully using O-RAN’s E2 Application Protocol and KPM Service Model (SM), as well as the pre-standard RC-PRE SM jointly developed by ONF, Facebook, AirHop, and Radisys.
With these two service models, three different use-cases are realized - monitoring Key Performance Metrics, PCI Conflict Resolution and Mobility Load Balancing.
New xApps were added on both Go and Python App-SDKs supporting these use cases.

This release also introduces significant changes to the RIC internals.
A Radio-Network Information Base (R-NIB) was added using onos-topo to store both configured and discovered information about the RAN nodes.
Applications can now use the R-NIB to learn about RAN Node capabilities via the App-SDKs. A new microservice, the User Element Network Information Base (UE-NIB), was also introduced to store and share near real-time information discovered about RAN UEs.
The SM subscription procedures were simplified by merging subscription APIs into the E2 Termination microservice, and deprecating the previously standalone subscription microservice (onos-e2sub).
Furthermore, new functionality was added to handle multiple xApps making identical subscriptions for the same SM from the same RAN node without getting rejected by the latter.
Finally, the RIC microservices were implemented using the principles of idempotent-APIs and level-triggered control loops, to ensure that components can tolerate and gracefully recover from crashes and restarts - for example, xApp restarts or E2 node restarts.

Mobility Load Balancing is a new use case introduced in this release. In this use-case, depending on the connected-UE load per cell, the nRT-RIC can influence Mobile Handover decision making by dynamically changing the cellIndividualOffset parameter used by UEs in the calculation of Handover A3 events.
To simulate this use-case, ONF’s RAN simulator (RANSim) was upgraded to simulate UEs moving along routes, measure RSRP values from their serving-cell and neighboring cells, and generate A3 events that lead to gNBs making handover decisions that load-balance UE distributions in cells in the RAN. A test application (onos-mlb) was also developed to test and validate the use-case.

SD-RAN’s white-box based CU/DU/RU solution with LTE support was upgraded with several stability fixes by ONF in this release, especially in the OAI based CU and DU code. And SD-RAN’s dev/test environment sdRan-in-a-Box (RiaB) was upgraded to make installation easier with ONF’s 4G mobile-core.
Importantly, our automated integration-test infrastructure now includes Robot based tests for Over-The-Air (OTA) scenarios, in addition to the [Helmit](https://docs.onosproject.org/helmit/docs/cli/) test infrastructure. In this release we have more-than-doubled the number of automated integration tests run nightly on Jenkins. 

Finally this is the first SD-RAN release fully integrated with [ONF’s Aether project](https://opennetworking.org/aether/), a private-5G Connected Edge platform for enabling enterprise digital transformation. This integration will be showcased as part of an SD-RAN outdoor trial at a large network operator in the second half of this year. 

## Features and Improvements

### micro-ONOS based nRT-RIC (ONOS-RIC), SDKs & xApps

* onos-e2t
  * Integrated with onos-topo to create/update RAN entities, their relations, and aspects during setup procedure 
  * Implemented  NB server and controllers based on new subscription and control APIs
  * Implemented absorbing identical subscriptions received from xApps in NB based on subscription specification proto bytes and E2 node ID
  * Introduced different level of stream abstractions to support multiplexing subscriptions 
  * Implemented required functionality to tolerate xApp/E2 node restarts/crashes and gracefully recover from them
  * Improved error handling in NB for incoming subscription and control requests
  * Full E2AP v1.01 protocol stack was finalized
  * Handling of OPTIONAL fields in the E2AP messages was implemented
  * Bug fix for RICserviceUpdate and E2connectionUpdate messages which were not able to be decoded properly (due to the same naming of some IEs)
  * Enhanced CLI usage to show both SB subscriptions and NB channels
* onos-e2-sm
  * Added an optional method to model plugin interface to extract required service model specific information for storing in onos-topo
  * RC-PRE SM was upgraded to the second revision of pre-standardized Radio Control SM
  * Handling of OPTIONAL fields in the KPMv2 and RC-PREv2 messages was implemented
  * Protoc-gen-cgo upgrade - now it’s able to generate code which handles OPTIONAL fields, added feature to pass flags and generate specific type of the code (unit tests or CGo glue code), minor update of templates
  * Ongoing transition from CGo approach to purely Go approach has started (currently under maintenance)
  * Improved build scripts to simplify building service model plugins for E2T
* onos-api
  * Added definitions of several generic and RAN-related topology aspects: Location, Coverage, E2Node, E2Cell, etc.
  * Enhanced topo API (filters, sorting)
  * Simplified E2T subscription and control APIs
  * Added custom error types for E2AP failures using custom gRPC error extensions
  * Deprecated E2Sub in favor of E2T subscription API
  * Introduced versioned package structure for E2T API to facilitate future API changes without breaking existing API contracts
* Go xApp SDK (onos-ric-sdk-go)
  * Implemented a new version of E2 SDK that supports E2AP Subscription, Subscription Delete, and Control procedures
  * Implemented a new version topology SDK to provide a high level interface for interacting with onos-topo subsystem.
  * Added an E2AP error package to provide a facility for handling different types of errors in E2T and xApps 
* onos-topo (R-NIB)
  * Deprecated attributes and implemented Aspect mechanism to allow tracking structured information rather than just flat key/value string attributes.
  * Implemented various filtering mechanisms to narrow information by: type, kind, labels, relations
  * Implemented optional sort criteria for returning results
  * Enhanced and cleaned-up CLI usage and added support for CLI filters and sort
* onos-uenib (UE-NIB)
  * Brand new subsystem that allows tracking information about UEs
  * Distinguished from R-NIB to allow choosing appropriate storage type to meet the requirements for real time read/write operations.
  * Aspect mechanism modeled based on onos-topo to allow tracking arbitrary groups of information
  * Implemented CLI usage
* onos-cli
  * Increased consistency of usage for various families of subcommands
  * Improved consistency of output and formatting
* onos-kpimon-xapp
  * Migrated the app to use new topo SDK to retrieve list of E2 nodes and monitor RAN environment changes for subscription procedure 
  * Migrated the app to use new version of E2 SDK to interact with the E2 nodes via E2T
  * Improved NB API and its implementation
  * Improved CLI implementation
  * Implemented UE-NIB handler to push the number of Active UEs per cell to UE-NIB
  * Improved the event handler to remove monitoring results from disconnected E2 nodes
  * Verified with RANSim, OAI-based 4G CU and Radisys 5G CU
* onos-pci-xapp
  * Migrated the app to use new topo SDK to retrieve list of E2 nodes and monitor RAN environment changes for subscription and control procedures
  * Migrated the app to use new version of E2 SDK to interact with the E2 nodes via E2T
  * Improved NB API and its implementation
  * Improved CLI implementation
  * Implemented UE-NIB handler to push each cell’s neighbor cells as reported by CUs
  * Verified with RANSim and Radisys 5G CU
* onos-mlb-xapp
  * Implemented a new xApp for mobility load balancing by adjusting the neighbor cell’s cell individual offset
  * Implemented MLB logic as follows: if serving cell’s load > overload threshold and neighbor cells’ load < target threshold, Ocn increases; if serving cell’s load < target threshold, Ocn decreases. Each cell’s load is the number of active UEs.
  * Implemented E2 handler to adjust Ocn by sending control messages through RC-PRE service model.
  * Implemented monitoring handler to get the number of UEs per cell from KPIMon xApp via UE-NIB
  * Implemented monitoring handler to get each cell’s neighbor cell information from PCI xApp via  UE-NIB
  * Implemented CLI to show the current Ocn value.
  * Verified with RANSim
* onos-exporter
  * Implemented modular mechanism to add collectors for different RIC components.
  * Each collector realizes the extraction, parsing and exposure of RIC component KPIs to Prometheus.
  * Implemented collectors for: onos-kpimon, onos-pci, onos-uenib, onos-topo and onos-e2t.
  * Implemented helm charts to include onos-exporter and its requirements (e.g., prometheus-stack) into sd-ran umbrella chart, as well as a SD-RAN KPIs dashboard in grafana.
  * Updated docs with methods to verify and visualize the onos-exporter KPIs, and a description of them.
* onos-operator
  * Added onos-topo operator with custom resources for defining topology Kinds, Entities, and Relations
  * Added support for deleting namespaces containing operator resources
  * Migrated to new deployment strategy using Helm charts
* atomix
  * Migrated Atomix control plane to new proxy-based architecture
  * Removed dependency of Atomix clients on controller connection
  * Added sidecar injection for proxies
  * Simplified Atomix Protobuf API to support clients in any gRPC supported language
  * Added new resources to inspect store/partition/node state and events
  * Integrated store/partition/node events with Kubernetes Event API
  * Added experimental peer-to-peer/gossip protocol for low-latency eventually consistent stores
  * Fixed hanging container deletes leading to resource consumption problems in long-running clusters
* Python xApp SDK (tentatively called aiomsa)
  * improvements to E2 subscription APIs
  * addition of SDL APIs for reading topology information and storing state
  * addition of mock E2 infrastructure to support testing apps without a RIC
* fb-kpimon-xapp
  * New xapp that uses the Python xApp SDK
  * Added support for parsing KPM measurements using ID type
  * Updated Prometheus metric labels to nodeid and cellid
  * Source granularity and report period intervals from configuration file
  * Create Prometheus metrics based on measurement names (not hardcoded)
  * Verified with RANSim and Radisys 5G CU
* fb-ah-xapp
  * Added support for MLB (mobility load balancing) use case, subscribing to the kpm service model to get cell capacity information
  * Upgraded from LTE to 5G internal data structures
  * Updated Airhop PCI support from LTE to 5G
  * Made changes to support updated rc-pre service model
  * Updated to utilize new SDL support in the SDK to retrieve e2/cell entities and save cell state
  * Added ability to manually update PCI and cell neighbor offset
  * Verified with RANSim
* fb-ah-gui
  * Updated to use latest APIs
* ah-eson-test-server
  * Updated to latest version from AirHop

### ONF/OAI CU-CP & White-Box RAN hardware

* [Ettus B210 USRP](https://www.ettus.com/all-products/ub210-kit/), [Enclosure kit](https://www.ettus.com/all-products/usrp-b200-enclosure/), Intel NUC10i7FNH, [Taoglas TG.45.8113](https://www.digikey.com/en/products/detail/taoglas-limited/TG-45-8113/9972822)
* Samsung Android smartphone (J5) 
* [OAI UE and OAI RU/DU/CU](https://gitlab.eurecom.fr/oai/openairinterface5g) (covered by [OAI Public License v1.1](https://www.openairinterface.org/legal/oai-public-license/)) split mode over Band 7 FDD with ONF enhancements for CU-CP and E2 Agent (covered under [ONF Member-only software license](https://opennetworking.org/wp-content/uploads/2020/06/ONF-Member-Only-Software-License-v1.0.pdf))
* CU-CP E2 Agent Service Model support (KPM-SM):
  * Upgrades E2SM-KPM to v02.00.03
* CU & DU performance improvements & fixes
  * Multiple CU/DU crash fixes during UE detach & Re-establishment scenario
  * Stale UE context fixes at CU (F1AP/RRC/PDCP/S1AP) & DU (MAC/RLC/RRC/F1AP)
  * Band 28 DU support
  * Improved PRACH DTX detection at L1
* UE
  * For nFAPI simulation mode, deployed onosproject/oai-ue:v0.1.6 which is from ONF OpenAirInterface5g repository
  * For USRP-based hardware setup, deployed onosproject/oai-ue:sdran-1.1.2 which is from the latest branch in OpenAirInterface upstream repository


### sdRan-in-a-Box (RiaB)

* Refactored Makefile to improve readability
* Updated make commands to run RiaB with a specific version and option, which is simpler than before
* Deprecated the old commands
* Added Makefile targets to deploy MLB xAPP along with KPIMON, PCI, UENIB, and RAN-Simulator
* Improved Makefile targets for RiaB infrastructure, EPC, and internal router deployment
* Added Makefile targets to config routing rules for hardware installation case
* Added Makefile targets for MLB, R-NIB, UE-NIB, and E2 tests
* Updated Facebook-Airhop use-case deployment code
* Minor bug fixes for RiaB reset and deployment
 
### RANSim

* Added handover parameters such as time to trigger, A3 offset, hysteresis, cell individual offset, and frequency offset
* Implemented the event A3 measurement logic and the A3 handover logic in RRM library (rrm-son-lib) and imported it to execute handover
* Honeycomb generator (generates RAN topology used by RANSim)
  * Merged metrics into honeycomb generator
  * PCI, EARFCN, cellType now generated with optional cli args
  * Added --max-collisions CLI flag argument
  * Perturbation: cells are each slightly shifted by a small random amount w/ cli arg
* Separate YAML output for configuring onos-topo (via helm charts) with information about simulated nodes and cells
* NBI for UEs
* 5G identifiers used by default
* Added RRC state simulation
  * UEs transition between RRC_CONNECTED and RRC_IDLE
  * CLI to display number of UEs in each state per cell
  * UEs in RCC_IDLE state do not take part in mobility handover

## Test

* Additional integration tests were added for the onos-e2t, onos-uenib, onos-topo, ran-simulator, onos-mlb, and onos-pci components
* Migrated integration tests to use new E2 and topo SDKs 
* HA failover tests added for the onos-e2t component and the onos-kpimon app
* Smoke tests added for testing multiple KPIMON apps, PCI app, MLB app, and UE NIB component
* Added UE detach scenario for RiaB OAI Robot tests
* Added Failure/Restart Robot test scenarios for RiaB and QA hardware pod setups
  * E2T restart, CU restart, and run functional tests again
* Added PCI and MLB deployment alongside RiaB OAI test scenario
  * Deploys these via helm charts and runs functional tests again
  * Ensures RiaB OAI functionality is not affected
* Updated current Robot tests to have more readable logging
* Updated Jenkins jobs for Robot tests to export build artifacts and logs for SD-RAN components deployed

## Deployment

* sdran-helm-charts
  * prerequisites - a running kubernetes cluster, kubectl and helm installed
```bash
# Add helm repositories
helm repo add cord https://charts.opencord.org
helm repo add atomix https://charts.atomix.io
helm repo add onos https://charts.onosproject.org
helm repo add sdran https://sdrancharts.onosproject.org
helm repo update

# Create Atomix resources
helm install -n kube-system atomix-controller atomix/atomix-controller --version v0.6.7 --wait

helm install -n kube-system raft-storage-controller atomix/atomix-raft-storage --version v0.1.8 --wait

# Create the ONOS operator
helm install -n kube-system onos-operator onos/onos-operator --version v0.4.6 --wait

# Install sd-ran (not in kube-system namespace)
kubectl create ns sdran 
helm -n sdran install sd-ran sdran/sd-ran --version 1.2.4

# Uninstall sd-ran, atomix and onos-operator
helm -n sdran uninstall sd-ran
helm -n kube-system uninstall onos-operator atomix-raft-storage atomix-controller
```

* When using RiaB, please refer to the [RiaB documentation](https://docs.sd-ran.org/master/sdran-in-a-box/README.html)
* For hardware setups, please check the [Hardware Installation docs](https://docs.sd-ran.org/master/sdran-in-a-box/docs/HW_Installation_intro.html)

## Documentation

* All release documentation is available at: [docs.sd-ran.org](http://docs.sd-ran.org)

## Known Issues
* Kpm measurement IDs in topo are prefixed with “value:” and it should be removed
* PLMN ID in onos-cli is not represented correctly
* Topo entities can override each other if the same IDs are picked for different kind of entities (e.g. same ID for E2 node and E2 cell entities)

## Component Versions

| Component               | SD-RAN 1.2.0                                                                |        SD-RAN 1.2.1 |
|:------------------------|-----------------------------------------------------------------------------|--------------------:|
| sd-ran (umbrella chart) | v1.2.0 chart 1.2.0                                                          |  v1.2.4 chart 1.2.4 |
| onos-api                | v0.7.80                                                                     |
| onos-ric-sdk-go         | v0.7.22                                                                     |
| onos-lib-go             | v0.7.13                                                                     |
| onos-e2-sm              | v0.7.51                                                                     |             v0.7.53 |
| onos-e2t                | v0.7.38 chart 1.0.46                                                        | v0.8.1 chart 1.0.47 |
| onos-uenib              | v0.1.0 chart 1.0.5                                                          |
| onos-topo               | v0.7.10 chart 1.0.16                                                        | 
| onos-config             | v0.8.4 chart 1.2.3                                                          |
| onos-operator           | v0.4.5 chart 0.4.6                                                          |
| ran-simulator (RANSim)  | v0.7.56 chart 1.0.74                                                        |
| onos-cli                | v0.7.33 chart 1.0.27                                                        |
| onos-kpimon             | v0.1.26 chart 0.6.19                                                        |
| onos-pci                | v0.1.19 chart 0.6.18                                                        |
| onos-mlb                | v0.0.7 chart 0.0.5                                                          |
| onos-exporter           | v0.1.7 chart 0.2.5                                                          |
| cu-cp                   | v0.1.6 chart 0.1.8                                                          |
| oai du                  | v0.1.6 chart 0.1.7                                                          |
| oai ue                  | v0.1.6 chart 0.1.7 (for nFAPI); sdran-1.1.2 chart 0.1.8 (for USRP hardware) |
| sdran-in-a-box (RiaB)   | 1.2.0                                                                       |
| fb-ah-gui               | 0.0.2 chart 0.0.4                                                           |
| ah-eson-test-server     | 0.0.2 chart 0.0.2                                                           |
| fb-ah-xapp              | 0.0.4 chart 0.0.5                                                           |
| fb-kpimon-xapp          | 0.0.2 chart 0.0.3                                                           |
| atomix                  | v3.1.9 chart 0.1.5                                                          |