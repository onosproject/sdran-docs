<!--
SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>

SPDX-License-Identifier: Apache-2.0
-->

# API Examples for Golang

The following are a few examples on how to use the [Golang API] generated from the `onos-uenib` gRPC API.

All the examples assume that the following import is available:
```go
import "github.com/onosproject/onos-api/go/uenib"
```

Similarly, all examples assume that the `UEService` client has been obtained and that context `ctx` was
either provided or created via code similar to the following:
```go
client := uenib.CreateUEServiceClient(conn)
...
ctx := context.Background()
```

## Create UE aspect(s)
Since the UE itself is just an ID and all other information is provided via the `aspects` mechanism, all
operations are effectively on aspects. Therefore, even if a UE already exists, but it does not currently have
a particular aspect, one must call `Create` rather than `Update`. This example shows how to attach a new
`onos.uenib.CellInfo` aspect to a particular UE:
```go
ue := &uenib.UE{ID: ueID}
ue.SetAspect(uenib.CellInfo{ServingCell: &uenib.CellConnection{ID: cellID, SignalStrength: 11.0}})
response, err = client.CreateUE(ctx, &uenib.CreateUERequest{UE: *ue})
```

## Get UEs - specific aspects or all aspects
An application may want to get one or more aspects of information associated with a UE. The following
example shows how this can be accomplished for `CellInfo` and (fictitious) `SubscriberData` aspects:
```go
aspectTypes := []string{"onos.uenib.CellInfo", "operator.SubscriberData"}
response, err := client.GetUE(ctx, &uenib.GetUERequest{ID: ueID, AspectTypes: aspectTypes})
```


To return all aspects associated with a UE, simply omit the `AspectTypes` from the request:
```go
response, err := client.GetUE(ctx, &uenib.GetUERequest{ID: ueID})
```

## Update UE aspect(s)
The UE information does not track a `Revision` and therefore it is not necessary to retrieve the UE aspect 
before updating it. Once can simply provide a new aspect value as part of the update request. For example,
the following shows how to update the `CellInfo` aspect:
```go
cells := neighborCellsByStrength(ueID) // fictitious utility
ue := &uenib.UE{ID: ueID}
ue.SetAspect(uenib.CellInfo{ServingCell: cells[0], CandidateCells: cells[1:]})
response, err = client.UpdateUE(ctx, &uenib.UpdateUERequest{UE: *ue})
```

## Delete UE aspect(s)
To delete specific aspects from a UE, simply provide the UE ID and the types of aspects to be deleted:
```go
response, err := client.DeleteUE(ctx, &uenib.GetUERequest{
	ID:          ueID, 
	AspectTypes: []string{"operator.SubscriberData"}
})
```


## List UEs
To iterate over all UEs, use the `List` method, which provides a finite stream from which the application
can read each UE with all requested aspects, as shown below:
```go
aspectTypes := []string{"onos.uenib.CellInfo", "operator.SubscriberData"}
stream, err := client.ListUEs(ctx, &uenib.ListUERequest{AspectTypes: aspectTypes})
for {
    response, err := stream.Recv()
    if err == io.EOF {
        break
    }
    if err != nil { ... }
    processUE(response.UE)
}
```
The stream will be closed when the client reads the last entry, or the client can prematurely close it
by invoking `ctx.Done()`.

## Watch UE Changes
The UE NIB API allows clients to watch the changes in real-time via its `Watch` method which delivers its
results as a continuous stream of events. These include not only the usual `create`, `update`, and `delete` events,
but also `replay` events to indicate the object as it existed prior to the `Watch` being called.

As with the `List` method, the results can be further narrowed by specifying `AspectTypes` in the request.
Here is a simple example of the `Watch` usage:

```go
stream, err := client.Watch(ctx, &uenib.WatchRequest{AspectType: []string{"onos.uenib.CellInfo"}})
if err == nil { ... }

for {
    msg, err := stream.Recv()
    if err == io.EOF {
        break
    }
    if err != nil { ... }
    processEvent(msg.Event.Type, msg.Event.UE)
}
```
The client can cancel the watch at anytime by invoking `ctx.Done()`.
