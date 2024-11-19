<!--
SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>

SPDX-License-Identifier: Apache-2.0
-->

# onos-a1t
A1 AP Termination module for ONOS SD-RAN (µONOS Architecture)

## Overview
The `onos-a1t` is the A1 termination node in the near-RT RIC for A1 interface to communicate the near-RT RIC with the non-RT RIC.
It is the proxy that forwards incoming A1 messages from the non-RT RIC to appropriate xApps or outgoing A1 messages from xApps to the non-RT RIC.
As per the O-RAN Working Group 2 specification, `onos-a1t` should support A1 messages for (i) the policy management, (ii) the enrichment information, and (iii) the machine learning model management.
As of today, since the O-RAN A1 specification only defines the policy management data model, `onos-a1t` only supports the policy management service.

Regarding O-RAN specifications, `onos-a1t` supports A1 Application Protocol v03.01 and A1 Type Definitions v02.00.

## Interaction
The `onos-a1t` interacts with at least three nodes: (i) `onos-topo`, (ii) `A1-enabled xApps` and (iii) `non-RT RIC`.
To begin with, `onos-a1t` keeps listening the `onos-topo` to check if there is new `A1-enabled xApps` deployed and if there are `A1-enabled xApps` already running.
Basically, the A1-enabled `xApps` initially stores its A1 interface information, such as supported A1 services (i.e., the policy management, the enrichment information, and the machine learning model management) and A1 interface endpoint (i.e., IP address and port number).
Listening `onos-topo`, `onos-a1t` scrapes the A1 interface information and store it into the `onos-a1t` local store.
With the A1 interface information, `onos-a1t` starts creating the gRPC session with appropriate xApps to communicate with each other.
A gRPC server is the `A1-enabled xApp`, whereas `onos-a1t` acts as the gRPC client (Note that this design is able to support the high availability and reliability by using the replicas for the near future).
In order to communicate with the non-RT RIC, `onos-a1t` has both an HTTP server and an HTTP client.
And of course, the non-RT RIC has to have both the HTTP server and the HTTP client for the bi-directional communication over HTTP.
The HTTP server in `onos-a1t` receives the JSON formatted A1 interface message from the non-RT RIC.
The HTTP client in `onos-a1t` is the client that sends the JSON formatted outgoing A1 interface messages to the non-RT RIC.
The HTTP client and server implementations are auto generated from the OpenAPI definitions provided by the A1 Application Protocol specifications.