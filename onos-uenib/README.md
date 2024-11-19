<!--
SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>

SPDX-License-Identifier: Apache-2.0
-->

# onos-uenib
UE NIB subsystem for ONOS SD-RAN (µONOS Architecture)

## Overview
This subsystem provides a central location for tracking information associated 
with RAN user equipment (UE).

Applications can associate various aspects of information with each UE either for their
one purpose or for sharing such state with other applications. The API and the system itself
is designed to allow for high rate of data mutation and with minimum latency.

### Unique ID
Each UE object has a unique identifier that can be used to directly look it up, update or delete it.

### Aspects
Since different use-cases or applications require tracking different information, and these may vary for different
types of user equipment, the schema must be extensible to carry various aspects of information.
This is where the notion of `Aspect` comes in. An `Aspect` is a collection of structured information, modeled as a
Protobuf message (although this is not strictly necessary), which is attached to the UE. In fact, UE entity carries
only its unique identifier, and the rest of the information is expressed via aspects, which are tracked as a map
of aspect type (`TypeURL`) and Protobuf `Any` message bindings.

For example, to track UE cell connectivity, the system uses the `CellInfo` aspect defined as a `CellConnection` for the 
serving cell and the list of candidate cells, defined as follows:

```proto
// CellConnection represents UE cell connection.
message CellConnection {
    string id = 1 [(gogoproto.customname) = "ID", (gogoproto.casttype) = "ID"];
    double signal_strength = 2;;
}

// CellInfo provides data on serving cell and candidate cells.
message CellInfo {
    CellConnection serving_cell = 1;
    repeated CellConnection candidate_cells = 2;
}
```

Of course applications may define their own structures of information and attach them to the UE for their own purpose
or to share with other applications.

## See Also
* [Deployment](docs/deployment.md)
* [CLI examples](docs/cli.md)
* [API examples (Golang)](docs/api-go.md)
* [topology subsystem]


[gRPC API]: https://github.com/onosproject/onos-api/blob/master/proto/onos/topo/topo.proto
[topology subcommands]: https://github.com/onosproject/onos-cli/blob/master/docs/cli/onos_topo.md
[Docker]: https://www.docker.com/
[Helm]: https://helm.sh
[topology subsystem]: https://github.com/onosproject/onos-topo