# SD-RAN 1.3 Release Notes

## Highlights

The fourth release of the [SD-RAN project](https://opennetworking.org/sd-ran/) brings two new use cases to the RIC, one involving Mobile Handovers and the other introducing RAN Slicing.

In this release, we targeted a different way to achieve load balanced cells in the RAN compared to the previous SD-RAN 1.2 release. The high level objective is to balance UE load across cells in the RAN by monitoring cell load (#UEs/cell) and then moving mobile-UEs from a highly loaded cell to neighboring cells with lower load. 
In SD-RAN 1.2 we achieved this via an xAPP named MLB (Mobility Load Balancing) which influences the handover logic in the cells and UEs by manipulating parameters used in the A3-handover event generation algorithm. 
In SD-RAN 1.3, we take a more direct approach where an xApp named MHO (Mobile Handover) takes the handover decision itself and instructs the serving-cell to initiate handover procedures for a UE to a target cell. In the process of implementing the MHO use-case, we developed a new Service Model and made extensive changes to RANSim to simulate mobility, expose RSRP metrics to the RIC and change RRC state. By moving the handover decision making to the RIC, an xApp can leverage AI/ML techniques to make more optimal decisions and predict future changes. Such efforts are underway by a third-party xApp developer.

RAN Slicing is an important feature for ensuring UEs experience the desired QoS in a shared medium such as the RAN. In this release, we have enhanced our LTE whitebox CU/DU software to introduce Downlink (DL) RAN Slicing on the DU via a new Service Model we developed called RSM (RAN Slice Management). With RSM supported on both the CU and DU, the RSM xApp on the RIC platform can receive EMM messages from the CU, figure out the UE to slice association for newly attached UEs, and instruct the DU to create or update DL slices and associate the UE bearers to the slice.
This functionality is an important first step in the RAN Slicing domain. We will continue to develop this functionality in future releases by introducing Uplink (UL) Slicing and more sophisticated scheduling algorithms and UE-to-slice association mechanisms.

In addition to new use cases, we continued to make improvements to the RIC platform, by introducing the ability to run multiple instances of the E2 Termination (E2T) microservice for high availability and horizontal scalability. When E2T instances are clustered, control of E2 nodes is balanced among the instances. The dynamic load balancing algorithm adapts to changes in the environment in real time. When an E2 node is added, control of the node is assigned to one of the available E2T instances. If an E2T instance crashes, control of those E2 nodes for which it had been responsible is automatically rebalanced among the remaining E2T instances.

The multi-Instance E2 Termination service relies on SDKs to implement client-side load balancing. To help facilitate this for all the RIC SDKs, this release also introduces a new RIC sidecar component for xApps. Sidecars are containers that are injected into pods at runtime and are a staple of Kubernetes native system architecture. The sidecar proxy is injected into xApp pods and takes on some of the responsibility of managing communication between the pod and RIC services — like E2T — from language-specific SDKs. Rather than having to implement the same client-side load balancing algorithms in each SDK, the sidecar proxy transparently balances requests to the E2T service and can be used by xApps written in any language.

Another highlight of this release is the upgrade of the platform to support the official O-RAN E2AP v2.0 interface, while maintaining support for the earlier version (v1.01). We have also made significant progress in our tooling with the introduction of the Go APER library that allows for a simpler and more automated way to convert ASN.1 to protobuf and related Go code, when compared to the earlier CGo tool. With continued effort in the Go APER library, future development in SD-RAN will soon benefit from fully-automated conversion of E2-AP messages and SM definitions. 

A helpful listing of the use-cases, xApps, SMs and their support in this release on various platforms is shown below

| Use Case | Service Model (developed by)  | xApp(s) | RANSim | LTE whitebox CU/DU | Radisys 5G CU/DU |
| :--- | --- | --- | --- | --- | ---: |
| KPI Monitoring | KPM v2.0.3 (O-RAN) | onos-kpimon, fb-kpimon, fb-ah | supported on E2AP 2.0 | supported on E2AP 1.01 | supported on E2AP 1.01 |
| PCI Conflict Resolution | RC-PRE v2 (ONF/FB/AirHop/Radisys) | onos-pci, fb-ah | supported on E2AP 2.0 | | supported on E2AP 1.01 |
| Mobility Load Balancing (MLB) | RC-PRE v2 (ONF/FB/AirHop/Radisys) | onos-mlb, fb-ah | supported on E2AP 2.0 | | supported on E2AP 1.01 |
| Mobile Handover (MHO) | MHO v1 (ONF/FB/Intel) | onos-mho | supported on E2AP 2.0 | | |
| RAN Slice Management | RSM v1 (ONF) | onos-rsm | | supported on E2AP 1.01 ||

## Features and Improvements

### micro-ONOS based nRT-RIC (ONOS-RIC), SDKs & xApps

* onos-e2t
  * Upgraded E2AP protocol stack and E2AP API to use official E2AP version 2.0
  * Implemented E2AP Connection Update and Configuration Update procedures for adding/removing new connections to support clustering 
  * Distinguished E2 management connection (i.e. connection established via E2 setup) from data connections that are added using E2 Connection Update procedure
  * Added a new configuration controller to reconcile E2 node and cell entities and their relations,  E2 node configuration, and connection update procedure 
  * Added a new E2T controller to reconcile creating and updating E2T entities in R-NIB
  * Deprecated admin API
  * Stored mapping of service model OID and RAN function IDs in R-NIB for usage of E2AP procedures 
  * Supported lease for E2T entities to detect E2T node failures and clean up E2T entities automatically by other E2T nodes  when the lease expired 
  * Added NB channels timestamps to clean up channels automatically when the channels expire
  * Refactored internal stream broker to allow reconcilers to propagate acks/failures to northbound server
  * Integrated E2 node mastership into Channel reconciliation to handle concurrency in multi-Instance E2T
  * Support Channel (Subscribe) retries in northbound server
  * Support Unsubscribe when no master exists
  * Begin buffering indications after mastership changes independent of northbound Subscribe RPC
  * Delete subscription on E2 node prior to Subscription mastership change
  * Added new integration tests for testing new functionalities and merged all of the tests into E2 suite

* onos-e2-sm
  * Deprecated ransim model plugins.
  * Implemented RAN Slicing Service Model (RSM) with Go APER library.
  * Re-implemented KPM v2.0.3 (pre-standard, was introduced in SD-RAN 1.2 release), MHO and RC-PRE SMs with Go APER library.
  * Implemented simple SM to start transition for using purely Go APER library in SM development instead of previously used CGo approach. 
    * This simple SM covers various test cases which serve as a reference for comparison of APER bytes produced by CGo approach and APER bytes produced by Go APER library.

* onos-api
  * Added RAN function ID list to the Service Model info message
  * Added Lease aspect with an expiration timestamp for RAN entities
  * Added E2T info aspect which includes information about  E2T interfaces (i.e. IP and port of southbound and northbound interfaces)
  * Added timeout to NB channels 

* Go xApp SDK (onos-ric-sdk-go)
  * SDK E2 facilities modified to work with the sidecar onos-proxy

* onos-topo (R-NIB)
  * Introduced internal relation indexes for faster relation-based queries
  * Introduced internal UUID for topo objects (entities/relations/kinds)
  * E2T instances are now tracked as separate objects and the E2 node and E2T controlling relationships are tracked via ‘controls’ relations
  * Location and related E2Cell info aspects were enhanced to support mobile base stations
  * New aspects were added to support slicing use-case
  * New aspects were added to track E2 node mastership
  * Fixed a number of defects and improved performance
* onos-uenib (UE-NIB)
  * UE aspects were added to support slicing use-case
* onos-cli
  * Deprecated e2sub and e2t admin API commands 
* onos-kpimon-xapp
  * Migrated the KPM monitoring result store from onos-uenib to onos-topo
* onos-pci-xapp
  * Migrated the neighbor information store from onos-uenib to onos-topo
* onos-mlb-xapp
  * Updated monitoring handler to migrate KPIMON monitoring results and neighbor information store from onos-uenib to onos-topo
* onos-rsm-xapp
  * A new xApp for RAN slice management
  * Implemented RAN slice management logic to create, delete, and update slices
  * Implemented UE-Slice association logic
  * Implemented R-NIB and UE-NIB handlers to store slice information in terms of CU/DU and UE, respectively
  * Implemented CLI for RAN slice management and UE-Slice association
  * Verified with OAI CU/DU via USRP and smartphone hardware as well as UE nFAPI software emulator

* onos-mho-xapp
  * A new xApp for Mobile Hand Over control
  * onos-mho-xapp implements a simple A3 event based handover function to demonstrate the mobility management capabilities of µONOS RIC platform
  * A new E2 Service Model for Mobile HandOver (E2SM-MHO) specifies procedures over the E2 interface to subscribe to and receive indications of UE mobility information and trigger handovers through control messages
  * The E2SM-MHO service model is currently only supported by RANSim and not by real CU/DU/gNB
  * New onos-mho-xapp specific CLI commands are introduced in onos-cli for viewing handover related information
  * Ransim’s mobility function has been enhanced to support handovers

* onos-exporter
  * Updated metrics related to queries to onos-e2t (list of xApp subscriptions)
  * Added metrics related to queries to onos-uenib (list of UEs), onos-topo (list of entities, relations and slices)
* onos-operator
  * Added application operator for runtime injection of sidecar proxy for xApp pods  
* onos-proxy
  * New RIC component designed to absorb complexities of interacting with multiple E2T instances and other RIC components in the future
  * The goal is to avoid reimplementing connection tracking (and other complex mechanism) in multiple language SDKs
  * SDK calls into the proxy and the proxy redirects the call to the appropriate E2T instance based on the state of an E2 node mastership
* onos-lib-go
  * Improved gRPC interceptors for HA
  * Implemented time-based requeues in controller framework
  * Several bugs in encoding/decoding in Go APER library were fixed.
* Atomix
  * Releases are now focused on long-term stability
  * Refactored state machine proxies and services to support concurrent reads and writes within a session
  * Fixed consistency bug allowing reads on followers to go back in time
  * Fixed a deadlock on write streams resulting from gRPC back-pressure to the state machine 
* Python xApp SDK (onos-ric-sdk-py)
  * Utilize sidecar proxy to enable client-side load balancing/optimizations
  * Remove dependency on abstract class API definitions
* fb-kpimon-xapp
  * Updated to follow Python xApp SDK changes
  * Image built from onos-ric-python-apps repository
* fb-ah-xapp
  * Updated to follow Python xApp SDK changes
  * Fixes for MLB functionality after lab testing with Radisys CU
  * Correlation of cell IDs between rc-pre and kpi service models
  * Image built from onos-ric-python-apps repository
* fb-ah-gui
  * no changes
* ah-eson-test-server
  * Image built from onos-ric-python-apps repository

### ONF/OAI CU-CP & White-Box RAN hardware

* [Ettus B210 USRP](https://www.ettus.com/all-products/ub210-kit/), [Enclosure kit](https://www.ettus.com/all-products/usrp-b200-enclosure/), Intel NUC10i7FNH, [Taoglas TG.45.8113](https://www.digikey.com/en/products/detail/taoglas-limited/TG-45-8113/9972822)
* Samsung Android smartphone (J5) 
* [OAI UE and OAI RU/DU/CU](https://gitlab.eurecom.fr/oai/openairinterface5g) (covered by [OAI Public License v1.1](https://www.openairinterface.org/legal/oai-public-license/)) split mode over Band 7 FDD with ONF enhancements for CU-CP and E2 Agent (covered under [ONF Member-only software license](https://opennetworking.org/wp-content/uploads/2020/06/ONF-Member-Only-Software-License-v1.0.pdf))
* Supports DL RAN slicing on DU
  * Round-Robin DL Slice scheduling enhancements in MAC layer
  * Allocating scheduling weights to each DL slice to support different QoS
  * Slice management procedures - Create/Delete/Update DL slices (in runtime)
  * UE-DL Slice association
* Supports new E2 RSM service model agent in both CU and DU
  * CU reporting EMM event to the Slicing xApp
  * DU handling incoming E2SM-RSM control messages & UE-slice association messages for RAN slice management from slicing xApp
* Supported E2 KPM service model agent along with E2 RSM service model

### sdRan-in-a-Box (RiaB)
* Added OpenVSwitch bridge and network interfaces for dedicated CU-DU F1 interface to fix SCTP session issue
* Updated infrastructure deployment code
* Updated Makefile targets for OAI option to deploy KPIMON and RSM xApps
* Updated OMEC EPC image and Helm chart version
* Added Makefile targets for new MHO use-case
* Fixed Atomix and onos-operator deployment logic to deploy proper version images rather than latest images

### RANSim
* Migrated to use service model Go modules instead of service model plugins (i.e. uses Go APER library for encoding and decoding of the corresponding messages) 
* Implemented E2AP Connection Update and Configuration Update procedures to support adding/removing new E2 connections to support clustering in onos-e2t
* Added a new connection controller to manager E2 connections 
* Supported reconnect on E2 setup connection failure 
* Minor fixes in MHO service model implementation

## Test

* Added new e2t integration tests and merged all of the integration tests into a single test suite
  * E2AP connection update in multi-instance E2T
  * Recover subscription after E2 node failure
  * E2T instance failure detection and load balancing
  * Recover subscription after E2T instance restart
  * Retain subscription during topo instance restart
  * Subscribe transaction timeout
  * Subscribe/Unsubscribe after E2 node down
* Added new RSM integration tests to test RSM xApp with large-scale RAN (100 CUs, 100 DUs, 300 UEs, and 3 slices / DU)
* Added integration tests for MHO xApp
* Added smoke tests for MHO and clustered E2T
* Updated RiaB smoke test to perform the RSM end-to-end test
* Added handset reattach scenario to QA hardware pod setup
* Added RSM functional tests to RiaB and QA hardware pod setups

## Deployment

* sdran-helm-charts
  * prerequisites - a running kubernetes cluster, kubectl and helm installed
  * Note that the SD-RAN umbrella chart version used below (v1.3) in the helm install command corresponds to a version of E2T microservice that uses O-RAN E2AP v2.0. For use of E2AP v1.01, use a different umbrella chart (v1.2.126). The two E2AP versions cannot be used at the same time.
```bash
# Add helm repositories
helm repo add cord https://charts.opencord.org
helm repo add atomix https://charts.atomix.io
helm repo add onos https://charts.onosproject.org
helm repo add sdran --username "$repo_user" --password "$repo_password" https://sdrancharts.onosproject.org
helm repo update

# Install atomix and onos-operator in kube-system namespace
helm install atomix-controller atomix/atomix-controller -n kube-system --wait --version 0.6.8
helm install atomix-raft-storage atomix/atomix-raft-storage -n kube-system --wait --version 0.1.15
helm install onos-operator onos/onos-operator -n kube-system --wait --version 0.4.14 

# Install sd-ran (not in kube-system namespace)
kubectl create ns sdran 
helm -n sdran install sd-ran sdran/sd-ran --version 1.3.0

# Uninstall sd-ran, atomix and onos-operator
helm -n sdran uninstall sd-ran
helm -n kube-system uninstall onos-operator atomix-raft-storage atomix-controller
```
* Please [contact ONF](https://opennetworking.org/contact/) for username and password credentials that allow access to the sdran helm chart repo
* When using RiaB, please refer to the [RiaB documentation](https://docs.sd-ran.org/master/sdran-in-a-box/README.html)
* For hardware setups, please check the [Hardware Installation docs](https://docs.sd-ran.org/master/riab_hw_intro.html)

## Documentation

* All release documentation is available at: [docs.sd-ran.org](http://docs.sd-ran.org)
* Please [contact ONF](https://opennetworking.org/contact/) for username and password credentials

## Known Issues

* In RSM use-case with the nFAPI emulator, sometimes the UE data plane does not work after deleting the associated slice and other slices frequently in a short time. To recover the data plane, a new slice should be created and then the UE should be associated with the new slice. In RSM use-case with the hardware devices, there is no issue.

## Component Versions

| Component | SD-RAN 1.3.0  |
| :--- | ---: |
|sd-ran (umbrella chart)| 1.3.0, 1.2.126 (for e2ap101) |
| onos-api| v0.7.110 |
| onos-ric-sdk-go | v0.7.34 |
| onos-ric-sdk-py | v0.1.7 |
| onos-proxy | v0.0.6 |
| onos-lib-go | v0.7.22 |
| onos-e2-sm | v0.7.69 |
| onos-e2t | v0.9.8 chart 1.2.6,  v0.8.13 chart 1.1.12 (for e2ap101) |
| onos-uenib | v0.2.4 chart 1.1.4 |
| onos-topo | v0.8.13 chart 1.1.109 |
| onos-config | v0.9.4 chart 1.3.6 |
| onos-operator | v0.4.13 chart 0.4.14 |
| ran-simulator | v0.8.18 chart 1.2.5 |
| onos-cli | v0.8.15 chart 1.1.11 |
| onos-kpimon | v0.2.13 chart 0.7.6 |
| onos-pci | v0.2.8 chart 0.7.5 |
| onos-mlb | v0.1.9 chart 0.1.6 |
| onos-exporter | v0.2.0 chart 0.3.1 |
| onos-rsm | v0.1.9 chart 0.1.4 |
| onos-mho | v0.1.8 chart 0.1.6 |
| oai/onf cu | v0.1.7 chart 0.1.10 |
| oai/onf du | v0.1.7 chart 0.1.10 |
| oai ue | v0.1.7 chart 0.1.10 (for nFAPI); sdran-1.1.2 chart 0.1.10 (for USRP hardware) |
| sdran-in-a box (RiaB) | v1.3.0 |
| fb-ah-gui | 0.0.2 chart 0.0.4 |
| ah-eson-test-server | 0.0.3 chart 0.0.3 |
| fb-ah-xapp | v0.0.13 chart 0.0.13 |
| fb-kpimon-xapp | v0.0.13 chart 0.0.5 |
| atomix/atomix-controller | v0.6.1 chart 0.6.8 |
| atomix/atomix-raft-storage | v0.9.8 chart 0.1.15 |



