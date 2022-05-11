<!--
SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>

SPDX-License-Identifier: Apache-2.0
-->

# SD-RAN 1.4 Release Notes

## Highlights

The fifth release of the [SD-RAN project](https://opennetworking.org/sd-ran/) brings significant improvements to the platform as well as several 3rd party integrations in xApps and RAN equipment.
This is also the first release of [SD-RAN to fully embrace open source](https://opennetworking.org/news-and-events/press-releases/onfs-sd-ran-now-fully-released-to-open-source/) - all code repositories, helm-charts and documentation are now Apache licensed and available to the public, together with older releases that were previously incubated under the ONF Member-only license.

A key feature of this release is the introduction of the [A1-Termination (AIT) microservice](https://github.com/onosproject/onos-a1t), which is based on the official O-RAN A1TD v02.00 and A1AP v03.01 specifications. The main A1T goal is to manage policies in the SD-RAN environment via communication with an external non Real-Time RIC. 
The first implementation of such a use-case involved a [Traffic Steering (TS) xApp](https://github.com/onosproject/rimedo-ts) introduced by RIMEDO Labs. The xApp interacts with A1T and dynamically manages UE to base-station connectivity taking into account radio conditions, cell-types and QoS profiles. The Mobile-Handover SM (MHO) was updated to its second version to implement the functionality required by the TS xApp.

Using an earlier version of the MHO-SM from SD-RAN 1.3, Intel has released a [Connection Management xApp](https://www.intel.com/content/www/us/en/developer/articles/reference-implementation/intelligent-connection-management.html) demonstrating the power of applying AI/ML to managing the RAN. 
Implementing a deep reinforcement learning (DRL) algorithm with a graph neural network (GNN) model, the xApp intelligently manages a wireless network and association of mobile user equipment with available radio cells, optimizing for user throughput, cell coverage, and load balancing.

On the RAN equipment front, Sercomm has recently announced [integration of their 5G-SA gNB](https://www.youtube.com/watch?v=2yfi6-KK8No&ab_channel=ONFSD-RANProject) with SD-RAN nRT-RIC and KPM use case. Furthermore, our OAI based whitebox LTE CU/DU software has been upgraded to support O-RAN’s E2AP 2.0 interface, and has added Uplink slicing to complement Downlink RAN Slicing implemented in the previous SD-RAN release.

On the RIC platform front, in preparation for a comprehensive O-RAN O1T implementation in future releases, we put in significant effort into the onos-config microservice. 
The onos-config service internals were redesigned and reimplemented to address various instability issues and incorporate new patterns and architectures into the algorithms with which onos-config processes gNMI requests and manages network configuration. 
The controllers at the core of onos-config were [redesigned in TLA+](https://github.com/onosproject/onos-tlaplus/blob/master/Config/Config.pdf) – a machine-checked formal specification language – to develop a more stable and viable architecture long-term, and the controllers were reimplemented according to the new design. On the northbound, new gNMI extensions make onos-config’s handling of gNMI Set and Get requests configurable with support for various consistency strategies when propagating changes to gNMI targets. 
On the southbound, support was added for handling non-persistent targets (recovering target configuration after restarts). This refactoring effort also produced a new internal data model and outward facing abstractions ([Transactions](https://github.com/onosproject/onos-api/blob/master/proto/onos/config/v2/transaction.proto), [Proposals](https://github.com/onosproject/onos-api/blob/master/proto/onos/config/v2/proposal.proto), and [Configurations](https://github.com/onosproject/onos-api/blob/master/proto/onos/config/v2/configuration.proto)) in the onos-config northbound API.

Finally, the Go APER library introduced in SD-RAN 1.3, was updated to support the E2AP protocol stack (previously it supported only E2-SMs). In particular, newly added features enable encoding and decoding of CHOICEs with Canonical Ordering (specific to E2AP definition and not that widely used in ASN.1 practice). Also, fixing potential race condition bugs in this library added more stability to the E2AP/E2SM communication process. The current distribution of Go APER library produces APER bytes identical to the one produced with Nokia’s asn1c tool distribution.

A helpful listing of the use-cases, xApps, SMs and their support in this release on various platforms is shown below.

| Use Case | xApps | Service Model (developed by)  | Radisys disaggregated 5G SA CU/DU | Sercomm 5G-SA gNB | Whitebox LTE CU/DU | RANSim |
| :--- | --- | --- | --- | --- | --- | ---: |
| KPI Monitoring | onos-kpimon, fb-kpimon, fb-ah | KPM v2 (O-RAN) | E2-AP v1.0.1 | E2-AP v1.0.1 | E2-AP v2.0 | E2-AP v2.0 |
| PCI Conflict Resolution | onos-pci, fb-ah | RC-PRE v2 (ONF / FB / AirHop / Radisys) | E2-AP v1.0.1 |  |  | E2-AP v2.0 |
| Mobility Load Balancing (MLB) | onos-mlb, fb-ah | RC-PRE v2 (ONF / FB / AirHop / Radisys) | E2-AP v1.0.1 | |  | E2-AP v2.0 |
| Mobile Handover (MHO) | onos-mho, Intel CM-xapp | MHO v1 (ONF/FB/Intel) |  |  |  | E2-AP v2.0 |
| RAN Slice Management | onos-rsm | RSM v1 (ONF)  |  |  | E2-AP v2.0 |  |
| Policy driven Traffic Steering | rimedo-ts | MHO v2 (ONF/FB/Intel/Rimedo-Labs)  |  |  |  | E2-AP v2.0 |

## Features & Improvements

### micro-ONOS based nRT-RIC (ONOS-RIC) platform & app-SDKs

* onos-e2t
  * Migrated service model plugins to use new versions that use Go APER library
  * Updated E2AP API to use Go APER library for encoding/decoding of E2AP messages
  * Fixed race condition bugs and memory leak 
  * E2AP protobuf structure was changed to correspond strictly to the ASN.1 definition and C-structures generated by asn1c tool.
    *  pdubuilder and pdudecoder packages for E2AP protocol stack were reworked.
  * All CGo dependencies (E2AP encoder) were removed.
* onos-a1t
  * Implemented with support to A1 Policy Management interacting with xApps (A1 Enrichment Information not fully supported).
  * Realized the integration with onos-topo to interact with A1-enabled xApps for specific policy type IDs and EI job type IDs.
  * Implemented Open API auto generation of HTTP client and server source code for Policy Management and Enrichment Information services.
  * Implemented CLI to expose the xApp subscription information
  * Implemented A1T southbound interface being able to communicate with xApps
* onos-a1-dm
  * Implemented A1 JSON schemas for O-RAN WG2 A1 data model version 2.0
    * Supported policy data model: QoE and Traffic Steering, QoE Target, QoS and Traffic Steering, QoS Target, Slice SLA Target, Traffic Steering Preference, and UE Level Target
* onos-e2-sm
  * MHO SM was updated. Newer revision aligns existing MHO definition with common data structures defined by O-RAN in E2SM, in particular, UE-ID representation.
  * CGo-based plugins are not built and published anymore, but source code is still present.
    * They were substituted with Go-based plugins which use the Go APER library.
  * Default logger for Go-based SMs was changed to the ONF’s proprietary one.
  * Validate function was re-introduced (now support of optional fields is enabled).
  * Protoc-gen-choice plugin, which generates a CHOICE map for corresponding E2SM/E2AP (mandatory prerequisite for Go APER library) was updated to support multiple input Protobuf files and generate a single map.
  * How to create your own SM tutorial was added.
* onos-api
  * Define new version of onos-config internal APIs and deprecate old APIs
  * Removed deprecated APIs
  * Defined A1T admin APIs for CLI and southbound APIs for both policy management and enrichment information
* onos-topo (R-NIB)
  * Improved RelationFilter functionality to support RELATIONS_ONLY and RELATIONS_AND_TARGETS scopes 
* onos-config
  * Completely redesigned onos-config controllers to address instability and ensure long-term maintainability
  * Created a formal TLA+ specification of the new logic for processing, propagating, and rolling back configuration change requests in the controllers
  * Verified the new onos-config controller architecture and logic maintains using TLC (the TLA+ model checker)
    * Checked that transactions are always processed and applied to targets in the order in which they were received
    * Checked that the system maintains serializable isolation for transactions
    * Checked that no possible behavior of the system exists that leads to a deadlock
    * Ran model checked simulations of tens of millions of scenarios
  * Implemented/reimplemented various onos-config controllers based on the TLA+ spec
    * Transaction controller to reconcile transactions created by NB of onos-config for Set requests 
    * Proposal controller to reconcile proposals created by transaction controller by creating gNMI Set requests and sending them to the targets
    * Configuration controller to reconcile configuration for ephemeral targets
    * Target controller to connect/disconnect to the targets as they added/removed from topology 
    * Connection controller to manage control relations in topology 
    * Mastership controller to create/update mastership state to target entities
    * Node controller to manage onos-config node entities in topo 
  * Developed a prototype of model-based test case generation to verify the code correctly implements the TLA+ spec
  * Reimplemented the northbound Set API to use transactions to process requests
  * Reimplemented the northbound Get API to query configuration from the internal Configuration state 
  * Added a passthrough for STATE variables on gNMI Get requests
  * Added a gNMI extension for synchronous Sets (wait for changes to be applied to targets)
  * Added a gNMI extension for synchronous Gets (passthrough to targets)
  * Added support for serializable isolation of multi-target Sets (any later change to one of the same targets must via a gNMI extension on northbound Sets
  * Added support for new persistent flag on target entities in onos-topo
  * Extended configuration protocol to support restoration of configuration on ephemeral (persistent=false) targets 
  * Extended northbound API with a new data model (transactions/proposals/configurations) based on the TLA+ spec
  * Implemented new data stores to persist transactions, proposals, and configurations 
  * Implemented a new SB to manage connections and detect connection failures
  * Implemented new NB to incorporate new changes with preserving the functionality
  * Implemented a new model plugin interface using gRPC and sidecar containers
* onos-uenib (UE-NIB)
  * Stores 5QI information reported by MHO xApp.
* onos-cli
  * Deprecated old onos-config CLI 
  * Implemented new onos-config CLI  for listing and watching transactions and configurations, rollback transactions, listing plugins. 
* onos-exporter
  * Fix the reference of opendistro-es in broken helm chart repo to opensearch for logging storage of fluentbit
  * The definition of the helm charts related to logging and monitoring (i.e., prometheus-stack, fluent-bit and opensearch) were moved to onos-exporter dependencies
* onos-operator
  * Removed the unused onos-config operator
* onos-proxy
  * Updated build dependencies
* onos-lib-go
  * Go APER library was updated to support E2AP protocol stack
    * In particular, new features enable encoding of CHOICEs with Canonical Ordering.
    * Fix race condition bug.
    * Current distribution of Go APER library produces APER bytes identical to the one produced with Nokia’s asn1c tool.
  * Updated logger package to use package name by default for the name of logger
* Atomix
  * Fixed memory leaks in session management state machine
  * Implemented session recovery protocol to handle expired sessions in drivers
* Go xApp SDK (onos-ric-sdk-go)
  * Implements a1t API to enable xApps interact with onos-topo and onos-a1t
* Python xApp SDK (onos-ric-sdk-py)
  * Upgraded to the latest version of the KPM service model

### xApps

* onos-kpimon-xapp
  * Updated to use new version of kpm v2 service model that uses Go APER library 
* onos-pci-xapp
  * Updated to use new version of rc-pre service model that uses Go APER library
  * Fixed minor bugs related to wrong PLMN ID
  * Updated to store cell type to onos-topo
* onos-mlb-xapp
  * Fixed minor bugs related to wrong PLMN ID
* onos-rsm-xapp
  * Updated to support E2AP v2.0 and latest RSM service model version
* onos-mho-xapp
  * xApp was updated to use MHO SM v2.
    * MHO SM v2 is based on the Go APER library.
* fb-kpimon-xapp
  * Upgraded to the latest version of the KPM service model
* fb-ah-xapp
  * Upgraded to the latest version of the KPM service model
* fb-ah-gui
  * No changes for this release
* ah-eson-test-server
  * No changes for this release
* rimedo-ts-xapp
  * Implements a traffic steering application utilizing the MHO Service Model
  * In the northbound defines the implementation of A1 Policy Management service supporting integration of onos-a1t for traffic steering policy definitions, in specific ORAN_TrafficSteeringPreference_2.0.0 policy type ID
  * By the A1 policy definitions via onos-a1t, rimedo-ts-xapp enforces the attachment of UEs with a defined profile to a specific cell by triggering handovers
  * In particular, the UE profile (i.e., 5QI) was extended in MHO service model to be reported in the Indication messages of MHO SM, and so this feature was implemented in the ran-simulator

### ONF/OAI CU-CP & White-Box RAN hardware
  * [Ettus B210 USRP](https://www.ettus.com/all-products/ub210-kit/), [Enclosure kit](https://www.ettus.com/all-products/usrp-b200-enclosure/), Intel NUC10i7FNH, [Taoglas TG.45.8113](https://www.digikey.com/en/products/detail/taoglas-limited/TG-45-8113/9972822)
  * Samsung Android smartphone (J5) 
  * [OAI UE and OAI RU/DU/CU](https://gitlab.eurecom.fr/oai/openairinterface5g) (covered by [OAI Public License v1.1](https://www.openairinterface.org/legal/oai-public-license/)) split mode over Band 7 FDD with ONF enhancements for CU-CP and E2 Agent (covered under Apache))
  * UL RAN Slicing feature support
  * With this release OAI CU/DU is E2AP v2 compliant

### sdRan-in-a-Box (RiaB)
  * Added Vagrant file for hardware installation and updated hardware installation documents accordingly
  * Supported E2AP 2.0 for OAI use-case
  * Removed all prompts asking credentials since RiaB and the deployments are now all open-source projects

### RANSim
  * Fix minor bugs in connection controller
  * Fixed wrong PLMN ID issue
  * Update E2AP client API to use Go APER library for encoding/decoding of E2AP messages
  * Embedded functionality to randomly generate 5QI value for each UE.
  * All CGo dependencies (E2AP encoder) were removed.
  * Adds the definition of 5QI to the UE profile, reported in Indication messages in MHO service model

## Test
  * Added UL tests to RSM functional robot tests
  * Added A1T integration test
  * Added RIMEDO Labs traffic steering xApp integration test
  * onos-config integration tests
    * Enhanced coverage of GNMI Get, Set, and Delete operations
    * Enhanced testing of failover operations for onos-config nodes and targets
  * Added new unit tests for onos-config  

## Deployment
  * sdran-helm-charts (prerequisites: a running kubernetes cluster, kubectl and helm installed)
  * Note that the SD-RAN umbrella chart version used below (v1.4.2) in the helm install command corresponds to a version of E2T microservice that uses O-RAN E2AP v2.0. For use of E2AP v1.01, use a different umbrella chart (v1.2.126). The two E2AP versions cannot be used at the same time.
  * NOTE for 1.4.1 release, use SD-RAN umbrella chart version 1.4.5 (appversion 1.4.1)
```bash
# Add helm repositories
helm repo add cord https://charts.opencord.org
helm repo add atomix https://charts.atomix.io
helm repo add onos https://charts.onosproject.org
helm repo add sdran https://sdrancharts.onosproject.org
helm repo update

# Install atomix and onos-operator in kube-system namespace
helm install atomix-controller atomix/atomix-controller -n kube-system --wait --version 0.6.9
helm install atomix-raft-storage atomix/atomix-raft-storage -n kube-system --wait --version 0.1.25
helm install onos-operator onos/onos-operator -n kube-system --wait --version 0.5.2

# Install sd-ran (not in kube-system namespace)
kubectl create ns sdran 
helm -n sdran install sd-ran sdran/sd-ran --version 1.4.5

# Uninstall sd-ran, atomix and onos-operator
helm -n sdran uninstall sd-ran
helm -n kube-system uninstall onos-operator atomix-raft-storage atomix-controller
kubectl delete ns sdran
```

* When using RiaB, please refer to the [RiaB documentation](https://docs.sd-ran.org/master/sdran-in-a-box/README.html)
* For hardware setups, please check the [Hardware Installation docs](https://docs.sd-ran.org/master/sdran-in-a-box/docs/HW_Installation_intro.html)

## Documentation

* All release documentation is available at: [docs.sd-ran.org](http://docs.sd-ran.org)

## Known Issues
  * xApp A1 policy consistent problem: a new A1-enabled xApp should not be added if there are already A1 policies added. If it happens, the new xApp is unable to get the old A1 policies already added. The new xApp only has the A1 policies which are pushed after the xApp is deployed.

## Release 1.4.1. Change Notes




* Use uint16 for request ID to fix out of range encoding issue
* Fix concurrency access on response channels map for E2 control API
* Cache Nodes in E2 SDK  to prevent resource leaks when calling Node() function
* Handle empty indication message on a NB closed channel in onos-e2t.
* Fixed a problem with the `plmnID` value on the `model-7cell-140ue.yaml` model in `ran-simulator`
* Updated the `onos-sdk` dependency in `onos-e2t` and `onos-cli`
* Updated the `onos-sdk` dependency in these xApps: `onos-kpimon`, `onos-pci`, `onos-mlb`, `onos-rsm`, and `onos-mho`
## Component Versions

| Component                  | SD-RAN 1.4.0                                                                  |          SD-RAN 1.4.1 |
|:---------------------------|-------------------------------------------------------------------------------|----------------------:|
| sd-ran (umbrella chart)    | 1.4.2, 1.2.126 (for e2ap101)                                                  |                 1.4.5 |
| onos-api                   | v0.9.7                                                                        |
| onos-ric-sdk-go            | v0.8.8                                                                        |
| onos-ric-sdk-py            | v0.2.3                                                                        |
| onos-proxy                 | v0.1.2                                                                        |
| onos-lib-go                | v0.8.13                                                                       |
| onos-e2-sm                 | v0.8.7                                                                        |
| onos-e2t                   | v0.10.11 chart 1.3.10,  v0.8.13 chart 1.1.12 (for e2ap101)                    | v0.10.13 chart 1.3.11 |
| onos-uenib                 | v0.2.5 chart 1.2.2                                                            |
| onos-topo                  | v0.9.4 chart 1.2.3                                                            |
| onos-config                | v0.10.28 chart 1.6.12                                                         |
| onos-operator              | v0.5.0 chart 0.5.2                                                            |
| ran-simulator              | v0.9.6 chart 1.3.9                                                            |   v0.9.6 chart 1.3.11 |
| onos-cli                   | v0.9.11 chart 1.2.8                                                           |
| onos-kpimon                | v0.3.5 chart 0.8.5                                                            |    v0.4.0 chart 0.8.6 |
| onos-pci                   | v0.3.5 chart 0.8.5                                                            |    v0.4.0 chart 0.8.6 |
| onos-mlb                   | v0.2.2 chart 0.2.3                                                            |    v0.3.0 chart 0.2.4 |
| onos-exporter              | v0.2.0 chart 0.4.3                                                            |
| onos-rsm                   | v0.1.13 chart 0.1.8                                                           |    v0.2.0 chart 0.1.9 |
| onos-mho                   | v0.2.5 chart 0.2.4                                                            |    v0.3.0 chart 0.2.5 |
| onos-a1t                   | v0.1.11 chart 0.1.5                                                           |
| onos-a1-dm                 | 0.0.5                                                                         |
| oai/onf cu                 | v0.1.10 chart 0.2.4                                                           |
| oai/onf du                 | v0.1.10 chart 0.2.4                                                           |
| oai ue                     | v0.1.7 chart 0.1.10 (for nFAPI); sdran-1.1.2 chart 0.1.10 (for USRP hardware) |
| sdran-in-a box (RiaB)      | v1.4.0                                                                        |
| rimedo-ts                  | v0.0.5 chart 0.0.5                                                            |
| fb-ah-gui                  | 0.0.2 chart 0.0.5                                                             |
| ah-eson-test-server        | 0.0.3 chart 0.0.4                                                             |
| fb-ah-xapp                 | v0.0.18 chart 0.0.15                                                          |
| fb-kpimon-xapp             | v0.0.19 chart 0.0.7                                                           |
| atomix/atomix-controller   | v0.6.2 chart 0.6.9                                                            |
| atomix/atomix-raft-storage | v0.9.19 chart 0.1.25                                                          |
