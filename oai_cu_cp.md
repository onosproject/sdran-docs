# OAI CU-CP

ONF's OAI CU-CP is a O-RAN compliant CU Control Plane (CU-CP) based on on
[OpenAirInterface](http://www.openairinterface.org). The CU-CP implements
O-RAN's E2AP interface with support for the Key Performance Metrics (E2SM_KPM)
Service Model. This component is intended for use with OAI based RU/DU hardware
or SDRAN-in-a-Box (RiaB).

## RIC Agent

The RIC Agent is an ONF addition to OAI that adds support for interfacing the
OAI CU-CP with a O-RAN Real-time Intelligent Controller (RIC) over the E2
interface. To build OAI with this support, enable the *--build-ric-agent* build
option:

```shell
$ cd openairinterface5g
$ source oaienv
$ cd cmake_targets
$ ./build_oai -c -I --eNB --UE -w USRP -g --build-ric-agent
```

The top-level *Makefile* builds docker images that include the RIC Agent:

```shell
$ cd openairinterface5g
$ make images
```

## ONF and OAI Code

The ONF fork can be found at
[onosproject/openairinterface5g](https://github.com/onosproject/openairinterface5g),
and upstream code can be found at [OAI's gitlab
openairinterface5g](https://gitlab.eurecom.fr/oai/openairinterface5g).
