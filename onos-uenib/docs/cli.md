<!--
SPDX-FileCopyrightText: 2019-present Open Networking Foundation <info@opennetworking.org>

SPDX-License-Identifier: Apache-2.0
-->

# Command-Line Interface
The project provides a command-line facilities for remotely 
interacting with the UE NIB subsystem.

The commands are available at run-time using the consolidated `onos` client hosted in the `onos-cli` repository.

The documentation about building and deploying the consolidated `onos` client or its Docker container
is available in the `onos-cli` GitHub repository.

## Usage
To see the detailed usage help for the `onos uenib ...` family of commands,
please see the [CLI documentation](https://github.com/onosproject/onos-cli/blob/master/docs/cli/onos_uenib.md)

## Examples
Here are some concrete examples of usage:

List `CellInfo` and `SubscriberData` of all UEs, that have these aspects.
```bash
$ onos uenib get ues --aspect onos.uenib.CellInfo
...
```

Create a new `CustomData` aspect for a UE:
```bash
$ onos uenib create ue 9182838476 --aspect operator.CustomData='{"foo": "bar", "special": true}'
```

Show all aspect data in verbose form for a given UE:
```bash
$ onos uenib get ue 9182838476 --verbose
```

Watch all changes in the UE NIB, without replay of existing UE information:
```bash
$ onos uenib watch ues --no-replay
```

Delete `CustomData` aspect for a specific UE:
```bash
$ onos uenib delete ue 9182838476 --aspect operator.CustomData
```
