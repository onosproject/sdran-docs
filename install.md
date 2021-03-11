# Hardware Installation

This installation shows how to run the ONF SDRAN setup using ONOS-RIC, OMEC, and OAI CU/DU and UE components. 
The OAI components perform connection via USRP B210 radio equipment attached to NUC machines.
This setup can be utilized as a reference implementation of the ONOS-RIC in hardware.

## Preliminaries
Prepare two NUC machines and each has Ubuntu 18.04 server.
One NUC machine will be used to run a UE setup connected to a USRP B210. The other NUC machine will be used to run the eNodeB OAI components (CU/DU) connected to another B210 device.
Prepare other two machines (or Virtual Machines - VMs) to install decomposed parts the SDRAN-in-a-Box (RiaB), in one of them the RIC (ONOS-RIC) will be executed, while in the other the EPC (OMEC) will be executed - both over Kubernetes.
**Those machines (or VMs) should be connected into the same subnet (via a switch or direct connection). In all machines install Ubuntu 18.04 server first.**

*NOTE: In the below sections, we have the following IP addresses assigned: NUC-OAI-CU/DU (192.168.13.21), NUC-UE (192.168.13.22), ONOS-RIC (192.168.10.22), and EPC-OMEC (192.168.10.21). 
These IP addresses are assigned to the eno1 interface in each server, i.e., the interface associated with the default gateway route. In case of a custom setup with different IP addresses assigned to the VMs, make sure the IP addresses (and their subnets/masks) are properly referenced in the configurations utilized in this tutorial.*


### Credentials
While installing and running the RiaB components, we might have to write some credentials for (i) opencord gerrit, (ii) onosproject github, and (iii) sdran private Helm chart repository. Make sure you have this member-only credentials before starting to install RiaB.

```bash
aether-helm-chart repo is not in /users/wkim/helm-charts directory. Start to clone - it requires HTTPS key
Cloning into '/users/wkim/helm-charts/aether-helm-charts'...
Username for 'https://gerrit.opencord.org': <OPENCORD_GERRIT_ID>
Password for 'https://<OPENCORD_GERRIT_ID>@gerrit.opencord.org': <OPENCORD_GERRIT_HTTPS_PASSWORD>
remote: Total 1103 (delta 0), reused 1103 (delta 0)
Receiving objects: 100% (1103/1103), 526.14 KiB | 5.31 MiB/s, done.
Resolving deltas: 100% (604/604), done.
sdran-helm-chart repo is not in /users/wkim/helm-charts directory. Start to clone - it requires Github credential
Cloning into '/users/wkim/helm-charts/sdran-helm-charts'...
Username for 'https://github.com': <ONOSPROJECT_GITHUB_ID>
Password for 'https://<ONOSPROJECT_GITHUB_ID>@github.com': <ONOSPROJECT_GITHUB_PASSWORD>
remote: Enumerating objects: 19, done.
remote: Counting objects: 100% (19/19), done.
remote: Compressing objects: 100% (17/17), done.
remote: Total 2259 (delta 7), reused 3 (delta 2), pack-reused 2240
Receiving objects: 100% (2259/2259), 559.35 KiB | 2.60 MiB/s, done.
Resolving deltas: 100% (1558/1558), done.

.....

helm repo add incubator https://kubernetes-charts-incubator.storage.googleapis.com/
"incubator" has been added to your repositories
helm repo add cord https://charts.opencord.org
"cord" has been added to your repositories
Username for ONF SDRAN private chart: <SDRAN_PRIVATE_CHART_REPO_ID>
Password for ONF SDRAN private chart: <SDRAN_PRIVATE_CHART_REPO_PASSWORD>
"sdran" has been added to your repositories
touch /tmp/build/milestones/helm-ready
```


## Install SDRAN-in-a-Box (RiaB) in the EPC-OMEC machine


### Get the SDRAN-in-a-Box (RiaB) source code 
To get the source code, please see: https://github.com/onosproject/sdran-in-a-box.
Since SDRAN-in-a-Box repository is a member-only repository, a user should log in github and then check the git clone command on that web site.
Clone the RiaB repository to the EPC-OMEC machine.

In the EPC-OMEC machine, after downloading the source code, in the cloned source code folder, edit the sdran-in-a-box-values.yaml file and change the file as below (we can copy and paste).

### Change sdran-in-a-box-values yaml file

In the cloned source code of the folder sdran-in-a-box, overwrite the content of the file sdran-in-a-box-values.yaml as provided below (copy and paste).

```yaml
# Copyright 2020-present Open Networking Foundation
#
# SPDX-License-Identifier: LicenseRef-ONF-Member-Only-1.0

# cassandra values
cassandra:
  config:
    cluster_size: 1
    seed_size: 1

resources:
  enabled: false

config:
  spgwc:
    pfcp: true
    multiUpfs: true
    jsonCfgFiles:
      subscriber_mapping.json:
        subscriber-selection-rules:
          - selected-user-plane-profile: "menlo"
            keys:
              serving-plmn:
                mcc: 315
                mnc: 10
                tac: 1
            priority: 5
            selected-access-profile:
              - access-all
            selected-apn-profile: "apn-internet-menlo"
            selected-qos-profile: "qos-profile1"
        user-plane-profiles:
          menlo:
            user-plane: "upf.riab.svc.cluster.local"
        apn-profiles:
          apn-internet-default:
            apn-name: "internet"
            usage: 1
            network: "lbo"
            gx_enabled: true
            dns_primary: "1.1.1.1"
            dns_secondary: "8.8.8.8"
            mtu: 1400
          apn-internet-menlo:
            apn-name: "internet"
            usage: 1
            network: "lbo"
            gx_enabled: true
            dns_primary: "8.8.8.8"
            dns_secondary: "1.1.1.1"
            mtu: 1400
    ueIpPool:
      ip: 172.250.0.0 # if we use RiaB, Makefile script will override this value with the value defined in Makefile script.
  upf:
    name: "oaisim"
    sriov:
      enabled: false
    hugepage:
      enabled: false
    cniPlugin: simpleovs
    ipam: static
    cfgFiles:
      upf.json:
        mode: af_packet
  mme:
    address: 192.168.10.21 # Set here the IP address of the interface eno1 (default gw) in the VM where OMEC is running
    cfgFiles:
      config.json:
        mme:
          mcc:
            dig1: 3
            dig2: 1
            dig3: 5
          mnc:
            dig1: 0
            dig2: 1
            dig3: 0
          apnlist:
            internet: "spgwc"
  hss:
    bootstrap:
      users:
        - apn: "internet"
          key: "000102030405060708090a0b0c0d0e0f"
          opc: "69d5c2eb2e2e624750541d3bbc692ba5"
          sqn: 96
          imsiStart: "315010206000001"
          msisdnStart: "1122334455"
          count: 30
      mmes:
        - id: 1
          mme_identity: mme.riab.svc.cluster.local
          mme_realm: riab.svc.cluster.local
          isdn: "19136246000"
          unreachability: 1
  oai-enb-cu:
    networks:
      f1:
        interface: eno1 # if we use RiaB, Makefile script will automatically apply appropriate interface name
        address: 10.128.100.100 #if we use RiaB, Makefile script will automatically apply appropriate IP address
      s1mme:
        interface: eno1 # if we use RiaB, Makefile script will automatically apply appropriate interface name
      s1u:
        interface: eno1
      plmnID:
        mcc: "315"
        mnc: "10"
        length: 2
        fullName: "ONF SDRAN"
        shortName: "SDRAN"
  oai-enb-du:
    enableUSRP: true
    mode: nfapi #or local_L1 for USRP and BasicSim
    networks:
      f1:
        interface: eno1 #if we use RiaB, Makefile script will automatically apply appropriate IP address
        address: 10.128.100.100 #if we use RiaB, Makefile script will automatically apply appropriate IP address
      nfapi:
        interface: eno1 #if we use RiaB, Makefile script will automatically apply appropriate IP address
        address: 10.128.100.100 #if we use RiaB, Makefile script will automatically apply appropriate IP address
  oai-ue:
    enableUSRP: true
    networks:
      nfapi:
        interface: eno1 #if we use RiaB, Makefile script will automatically apply appropriate IP address
        address: 10.128.100.100 #if we use RiaB, Makefile script will automatically apply appropriate IP address
    sim:
      msinStart: "206000001" 
      apiKey: "000102030405060708090a0b0c0d0e0f"
      opc: "69d5c2eb2e2e624750541d3bbc692ba5"
      msisdnStart: "1122334455"
  onos-e2t:
    enabled: "yes"
    networks:
      e2:
        address: 192.168.10.22 # Set here the IP address of the interface eno1 (default gw) in the VM where RIC is running
        port: 36421
# for the development, we can use the custom images
# For ONOS-RIC
# onos-topo:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-topo
#     tag: latest
# onos-config:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-config
#     tag: v0.7.8
onos-e2t:
  service:
    external:
      enabled: true
    e2:
     nodePort: 36421
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-e2t
#     tag: latest
#   servicemodels:
#   - name: e2sm_kpm
#     version: 1.0.0
#     image:
#       repository: onosproject/service-model-docker-e2sm_kpm-1.0.0
#       tag: latest
#       pullPolicy: IfNotPresent
#   - name: e2sm_ni
#     version: 1.0.0
#     image:
#       repository: onosproject/service-model-docker-e2sm_ni-1.0.0
#       tag: latest
#       pullPolicy: IfNotPresent
# onos-e2sub:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-e2sub
#     tag: latest
# onos-sdran-cli:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-sdran-cli
#     tag: latest
# onos-kpimon:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-kpimon
#     tag: latest

# For OMEC & OAI
images:
  pullPolicy: IfNotPresent
  tags:
# For OMEC - Those images are stable image for RiaB
# latest Aether helm chart commit ID: 3d1e936e87b4ddae784a33f036f87899e9d00b95
#    init: docker.io/omecproject/pod-init:1.0.0
#    depCheck: quay.io/stackanetes/kubernetes-entrypoint:v0.3.1
    hssdb: docker.io/onosproject/riab-hssdb:v1.0.0
    hss: docker.io/onosproject/riab-hss:v1.0.0
    mme: docker.io/onosproject/riab-nucleus-mme:v1.0.0
    spgwc: docker.io/onosproject/riab-spgw:v1.0.0-onfvm-1
    pcrf: docker.io/onosproject/riab-pcrf:v1.0.0
    pcrfdb: docker.io/onosproject/riab-pcrfdb:v1.0.0
    bess: docker.io/onosproject/riab-bess-upf:v1.0.0-onfvm-1
    pfcpiface: docker.io/onosproject/riab-pfcpiface:v1.0.0-onfvm-1
# For OAI
    oaicucp: docker.io/onosproject/oai-enb-cu:latest
    oaidu: docker.io/onosproject/oai-enb-du:latest
    oaiue: docker.io/onosproject/oai-ue:latest

# For SD-RAN Umbrella chart:
# ONOS-KPIMON xAPP is imported in the RiaB by default
import:
  onos-kpimon:
    enabled: true
# Other ONOS-RIC micro-services
#   onos-topo:
#     enabled: true
#   onos-e2t:
#     enabled: true
#   onos-e2sub:
#     enabled: true
#   onos-o1t:
#     enabled: false
#   onos-config:
#     enabled: true
#   onos-sdran-cli:
#     enabled: true
# ran-simulator chart is automatically imported when pushing ransim option
#   ran-simulator:
#     enabled: false
#   onos-gui:
#     enabled: false
#   nem-monitoring:
#     enabled: false
```

### Change the target /fabric in the Makefile

In the cloned RiaB repository at the EPC-OMEC machine, edit the Makefile target to look like the following lines below.

*Note: The IP addresses prefix (i.e., 192.168.x.z) correspond to the prefix assigned to the same subnet where the whole setup is defined. In a custom setup, make sure these IP addresses subnet match too.*

```bash
$(M)/fabric: | $(M)/setup /opt/cni/bin/simpleovs /opt/cni/bin/static
	sudo apt install -y openvswitch-switch
	sudo ovs-vsctl --may-exist add-br br-enb-net
	sudo ovs-vsctl --may-exist add-port br-enb-net enb -- set Interface enb type=internal
	sudo ip addr add 192.168.11.12/29 dev enb || true
	sudo ip link set enb up
	sudo ethtool --offload enb tx off
	sudo ip route replace 192.168.11.16/29 via 192.168.11.9 dev enb
	kubectl apply -f $(RESOURCEDIR)/router.yaml
	kubectl wait pod -n default --for=condition=Ready -l app=router --timeout=300s
	kubectl -n default exec router ip route add $(UE_IP_POOL)/$(UE_IP_MASK) via 192.168.11.10
	kubectl delete net-attach-def core-net
	touch $@
```

**These IP addresses are assigned to OMEC because they must be reachable by the NUC-OAI-CU/DU machine, so the oai-enb-cu component can communicate with the omec-mme component. More details about custom settings are explained in the [Custom Settings](#network-routes-and-ip-addresses).**


### Change the router networks

In the cloned RiaB repository at the EPC-OMEC machine, edit the file located at path-to/sdran-in-a-box/resources/router.yaml, so the router Pod have its networks annotations to look like the lines below:

*Note: The IP addresses prefix (i.e., 192.168.x.z) correspond to the prefix assigned to the same subnet where the whole setup is defined. In a custom setup, make sure these IP addresses subnet match too.*

```text
…
apiVersion: v1
kind: Pod
metadata:
  name: router
  labels:
    app: router
  annotations:
    k8s.v1.cni.cncf.io/networks: '[
            { "name": "core-net", "interface": "core-rtr", "ips": ["192.168.11.1/29"] },
            { "name": "enb-net", "interface": "enb-rtr", "ips": ["192.168.11.9/29"] },
            { "name": "access-net", "interface": "access-rtr", "ips": ["192.168.11.17/29"] }
    ]'
…
```

**These IP addresses are assigned to a router pod in the OMEC VM, making possible the UPF component of OMEC can communicate with the enb and core networks. More details about custom settings are explained in the [Custom Settings](#network-routes-and-ip-addresses).**


### Start the RiaB EPC-OMEC components

After changing the file `sdran-in-a-box-values.yaml`, run the following commands:

```bash
$ cd /path/to/sdran-in-a-box
$ sudo apt install build-essential
$ make omec
```

### Verify whether everything is up and running
After a while, RiaB Makefile completes to install K8s and deploy OMEC CP, OMEC UP, and an internal router.
Once it is done, you can check with the below command in the EPC-OMEC machine.
```bash
$ kubectl get pods --all-namespaces
NAMESPACE     NAME                                          READY   STATUS    RESTARTS   AGE
default       router                                        1/1     Running   0          19h
kube-system   calico-kube-controllers-865c7978b5-k6f62      1/1     Running   0          19h
kube-system   calico-node-bldr4                             1/1     Running   0          19h
kube-system   coredns-dff8fc7d-hqfcn                        1/1     Running   0          19h
kube-system   dns-autoscaler-5d74bb9b8f-5w2j4               1/1     Running   0          19h
kube-system   kube-apiserver-node1                          1/1     Running   0          19h
kube-system   kube-controller-manager-node1                 1/1     Running   0          19h
kube-system   kube-multus-ds-amd64-jzvzr                    1/1     Running   0          19h
kube-system   kube-proxy-wclnq                              1/1     Running   0          19h
kube-system   kube-scheduler-node1                          1/1     Running   0          19h
kube-system   kubernetes-dashboard-667c4c65f8-bqkgl         1/1     Running   0          19h
kube-system   kubernetes-metrics-scraper-54fbb4d595-7kjss   1/1     Running   0          19h
kube-system   nodelocaldns-p6j8m                            1/1     Running   0          19h
omec          cassandra-0                                   1/1     Running   0          113m
omec          hss-0                                         1/1     Running   0          113m
omec          mme-0                                         4/4     Running   0          113m
omec          pcrf-0                                        1/1     Running   0          113m
omec          spgwc-0                                       2/2     Running   0          113m
omec          upf-0                                         4/4     Running   0          112m
```
If you can see the router and all OMEC PODs are running, then everything is good to go.

## Install SDRAN-in-a-Box (RiaB) in the ONOS-RIC machine

### Get the SDRAN-in-a-Box (RiaB) source code 
To get the source code, please see: https://github.com/onosproject/sdran-in-a-box.
Since SDRAN-in-a-Box repository is a member-only repository, a user should log in github and then check the git clone command on that web site.
Clone the RiaB repository to the ONOS-RIC machine.


### Start the RiaB ONOS-RIC components

```bash
$ cd /path/to/sdran-in-a-box
$ sudo apt install build-essential
$ make ric-oai-latest
```


### Verify whether everything is up and running
After a while, RiaB Makefile completes to install K8s and deploy ONOS-RIC components.
Once it is done, you can check with the below command in the ONOS-RIC machine.

```bash
NAMESPACE     NAME                                          READY   STATUS             RESTARTS   AGE
kube-system   atomix-controller-694586d498-xmbl6            1/1     Running            0          2d17h
kube-system   cache-storage-controller-5996c8fd45-qczpw     1/1     Running            0          2d17h
kube-system   calico-kube-controllers-845fccd4b8-5d9pf      1/1     Running            0          2d17h
kube-system   calico-node-pk9tq                             1/1     Running            0          2d17h
kube-system   coredns-dff8fc7d-xphrs                        1/1     Running            0          2d17h
kube-system   dns-autoscaler-5d74bb9b8f-8fj47               1/1     Running            0          2d17h
kube-system   kube-apiserver-node1                          1/1     Running            0          2d17h
kube-system   kube-controller-manager-node1                 1/1     Running            0          2d17h
kube-system   kube-multus-ds-amd64-dn989                    1/1     Running            0          2d17h
kube-system   kube-proxy-88wsz                              1/1     Running            0          2d17h
kube-system   kube-scheduler-node1                          1/1     Running            0          2d17h
kube-system   kubernetes-dashboard-667c4c65f8-9lhx4         1/1     Running            0          2d17h
kube-system   kubernetes-metrics-scraper-54fbb4d595-tjd97   1/1     Running            0          2d17h
kube-system   nodelocaldns-v8lnk                            1/1     Running            0          2d17h
kube-system   raft-storage-controller-7755865dcd-wt2xt      1/1     Running            0          2d17h
riab          onos-config-7b9686f7c-5fcdt                   1/1     Running            0          2d16h
riab          onos-consensus-db-1-0                         1/1     Running            0          2d16h
riab          onos-e2sub-df8c86fc7-gbb97                    1/1     Running            0          2d16h
riab          onos-e2t-5dbfb8555c-wzfjm                     1/1     Running            0          2d16h
riab          onos-kpimon-575947b656-k2vll                  1/1     Running            0          2d16h
riab          onos-sdran-cli-c4dc6bfbc-24c86                1/1     Running            0          2d16h
riab          onos-topo-69978c49fb-8cptq                    1/1     Running            0          2d16h
```


**Note: RIC does not have a fixed IP address by which oai-enb-cu (or another eNB) can communicate with it. The onos-e2t component exposes a service in port 36421, which is associated with the IP address of the eno1 interface (i.e., the default gateway interface) where it is running. To check that IP address run the command "kubectl -n riab get svc". In the output of this command, one of the lines should show something similar to "onos-e2t-external        NodePort    x.y.w.z   <none>        36421:36421/SCTP             0m40s". The IP address "x.y.w.z" shown in the output of the previous command (listed in the onos-e2t-external service) is the one that is accessible from the outside of the RIC VM, i.e., by the oai-enb-cu in case of this tutorial. In a test case with another eNB, that should be the IP address to be configured in the eNB so it can communicate with onos RIC.**


## Install the requirements for OpenAirInterface (OAI) and USRP B210 in both NUC machines

Before we start this section, we consider the NUC machines already have Ubuntu 18.04 server OS installed.
**Also, please DO NOT connect the USRP B210 device to the NUC machines yet.**
**Otherwise, NUC may not boot up.**

Then, follow below section.

### Install Linux Image low-latency
```bash
$ sudo apt install linux-image-lowlatency linux-headers-lowlatency
```

### Power management and CPU frequency configuration
To run on OAI, we must disable p-state and c-state in Linux.
Go to `/etc/default/grub` file and add change `GRUB_CMDLINE_LINUX_DEFAULT` line as below:
```text
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_pstate=disable processor.max_cstate=1 intel_idle.max_cstate=0 idle=poll"
```

After save that file, we should command this:
```bash
$ sudo update-grub2
```

Next, go to `/etc/modprobe.d/blacklist.conf` file and append below at the end of the file:
```text
# for OAI
blacklist intel_powerclamp
```

After that, reboot the NUC machine. When rebooting, we have to change the `BIOS` configuration.
Go to the BIOS setup page and change some parameters:
* Disable secure booting option
* Disable hyperthreading
* Enable virtualization
* Disable all power management functions (c-/p-state related)
* Enable real-time tuning and Intel Turbo boost
Once it is done, we should save and exit. Then, we reboot NUC board again.

When NUC is up and running, we should install the below tool:
```bash
$ sudo apt-get install cpufrequtils
```

After the installation, go to `/etc/default/cpufrequtils` and write below:
```text
GOVERNOR="performance"
```

*NOTE: If the `/etc/default/cpufrequtils` file does not exist, we should make that file.*

Next, we should command below:
```bash
$ sudo systemctl disable ondemand.service
$ sudo /etc/init.d/cpufrequtils restart
```

After that, we should reboot this machine again.

### Verification of the power management and CPU frequency configuration
In order to verify configurations for the power management and CPU frequency, we should use `i7z` tool.
```bash
$ sudo apt install i7z
$ sudo i7z
True Frequency (without accounting Turbo) 1607 MHz
  CPU Multiplier 16x || Bus clock frequency (BCLK) 100.44 MHz

Socket [0] - [physical cores=6, logical cores=6, max online cores ever=6]
  TURBO ENABLED on 6 Cores, Hyper Threading OFF
  Max Frequency without considering Turbo 1707.44 MHz (100.44 x [17])
  Max TURBO Multiplier (if Enabled) with 1/2/3/4/5/6 Cores is  47x/47x/41x/41x/39x/39x
  Real Current Frequency 3058.82 MHz [100.44 x 30.45] (Max of below)
        Core [core-id]  :Actual Freq (Mult.)      C0%   Halt(C1)%  C3 %   C6 %  Temp      VCore
        Core 1 [0]:       3058.81 (30.45x)       100       0       0       0    64      0.9698
        Core 2 [1]:       3058.82 (30.45x)       100       0       0       0    63      0.9698
        Core 3 [2]:       3058.82 (30.45x)       100       0       0       0    64      0.9698
        Core 4 [3]:       3058.81 (30.45x)       100       0       0       0    64      0.9698
        Core 5 [4]:       3058.81 (30.45x)       100       0       0       0    65      0.9698
        Core 6 [5]:       3058.82 (30.45x)       100       0       0       0    62      0.9686
```

In the above results, we have to see that all cores should get `C0%` as `100` and `Halt(C1)%` as `0`.
If not, some of the above configuration are missing.
Or, some of BIOS configurations are incorrect.

**Now, please connect the USRP B210 device to the NUC machines (usb 3.0).**


## OAI-CU/DU and OAI-UE RiaB Installation

Please follow the instructions in case a baremetal installation is required at [Baremetal Installation](#baremetal-installation), it provides the guidelines to compile OAI-CU/DU/UE, and how to execute them after following the [Network Parameter Configuration](#network-parameter-configuration).

Herein, the installation of the OAI-CU/CU OAI-UE NUCs will proceed using mechanisms similar to RIC and OMEC, i.e., via the Makefile of sdran-in-a-box repository.

### Get the SDRAN-in-a-Box (RiaB) source code 
To get the source code, please see: https://github.com/onosproject/sdran-in-a-box.
Since SDRAN-in-a-Box repository is a member-only repository, a user should log in github and then check the git clone command on that web site.
Clone the RiaB repository to the OAI-CU/DU and OAI-UE machines.

In both the OAI-CU/DU and OAI-UE NUC machines, after downloading the source code, in the cloned source code folder, edit the sdran-in-a-box-values.yaml file and change the file as presented in [Change sdran-in-a-box-values.yaml file](#change-sdran-in-a-box-values-yaml-file).


## Network parameter configuration
So far, we deployed EPC-OMEC, ONOS-RIC, installed OAI in both NUC machines (OAI-CU/DU and OAI-UE), and configured OAI in the OAI-CU/DU machine.

We should then configure the network parameters (e.g., routing rules, MTU size, and packet fregmentation) on EPC-OMEC and OAI-CU/DU machines in order to make them work together.

### Install some network tools on both machines (EPC-OMEC and OAI-CU/DU)
```bash
$ sudo apt install net-tools ethtool
```

*NOTE: Normally, those tools are already installed. If not, we can command it.*


### Configure the secondary IP address on the OAI NUC
Before run CU-CP, the NUC machine for OAI should have a secondary IP address on the Ethernet port.
The secondary IP address should have one of the IP address in `192.168.11.8/29` subnet.
The purpose of this IP address is to communicate with the other NUC machine which RiaB is running inside.
```bash
$ sudo ip a add 192.168.11.10/29 dev eno1
```
*NOTE: The reference setup has 192.168.11.10/29 for the secondary IP address, as defined in the same network prefix 192.168. as OMEC-EPC.*


### Configuration in EPC-OMEC machine
First, we should go to the EPC-OMEC machine.

We should add a single routing rule and disable TCP TX/RX checksum and Generic Receive Offloading (GRO) configuration.
```bash
$ ROUTER_IP=$(kubectl exec -it router -- ifconfig eth0 | grep inet | awk '{print $2}' | awk -F ':' '{print $2}')
$ ROUTER_IF=$(route -n | grep $ROUTER_IP  | awk '{print $NF}')
$ sudo ethtool -K $ROUTER_IF gro off rx off
$ sudo ethtool -K eno1 rx off tx on gro off gso on  #Notice here, this is the primary interface of the EPC-OMEC machine
$ sudo ethtool -K enb rx off tx on gro off gso on
$ sudo route add -host 192.168.11.10 gw 192.168.13.21 dev eno1 #Defines the route to OAI-CU/DU secondary IP address

```

### Configuration in EPC-OMEC internal router
Second, we should configure network parameters in the EPC-OMEC internal router.
In order to access the EPC-OMEC internal router, go to the EPC-OMEC machine and command below:

```bash
$ kubectl exec -it router -- bash
```

On the router prompt, we initially add a routing rule and MTU size.
Then, we should disable TX/RX checksum and GRO for all network interfaces in the router.

```bash
$ # Add routing rule
$ route add -host 192.168.11.10 gw 192.168.11.12 dev enb-rtr  #Defines the route to OAI-CU/DU machine via the enb interface (attached to br-enb-rtr bridge)

$ # Change MTU size
$ ifconfig core-rtr mtu 1550
$ ifconfig access-rtr mtu 1550

$ # Disable checksum and GRO
$ apt update; apt install ethtool
$ ethtool -K eth0 tx off rx off gro off gso off
$ ethtool -K enb-rtr tx off rx off gro off gso off
$ ethtool -K access-rtr tx off rx off gro off gso off
$ ethtool -K core-rtr tx off rx off gro off gso off
```

### Configuration in UPF
Next, we should go to the UPF running in the RiaB NUC machine:
```bash
$ kubectl exec -it upf-0 -n riab -- bash
```

On the UPF prompt, we should change the MTU size.
```bash
$ ip l set mtu 1550 dev access
$ ip l set mtu 1550 dev core
```

### Configuration in OAI-CU/DU machine
Last, we should configure network configuration in the OAI-CU/DU NUC machine.
We should go to the the OAI-CU/DU NUC machine and change the network configuration such as TX/RX checksum, GRO, and routing rules.

```bash
$ sudo ethtool -K eno1 tx off rx off gro off gso off
$ sudo route del -net 192.168.11.8/29 dev eno1 # ignore error if happened
$ sudo route add -net 192.168.11.0/29 gw 192.168.10.21 dev eno1 # This route forwards traffic to the EPC machine 
$ sudo route add -net 192.168.11.8/29 gw 192.168.10.21 dev eno1 # This route forwards traffic to the EPC machine 
$ sudo route add -net 192.168.11.16/29 gw 192.168.10.21 dev eno1 # This route forwards traffic to the EPC machine 
```

## Run CU and DU in the OAI-CU/DU machine

After changing the file `sdran-in-a-box-values.yaml`, run the following commands:

```bash
$ cd /path/to/sdran-in-a-box
$ sudo apt install build-essential
$ make oai-enb-usrp
```

This step might take some time due to the download of the oai-enb-cu and oai-enb-du docker images.
After both conditions (pod/oai-enb-du-0 condition met, pod/oai-enb-cu-0 condition met) were achieved proceed to the next topic.

The pod pod/oai-enb-du-0 takes some time to start as it needs to configure the USRP first.

## Check if the OAI/CU-DU command was correctly executed

In the ONOS-RIC machine, log in the onos-cli pod, running:

```bash
$ kubectl -n riab exec -ti deployment/onos-sdran-cli -- bash
```

Once inside the onos-cli pod, check the ONOS-RIC connections and subscriptions:

```bash
$ sdran e2t list connections      #Shows the associated CU/DU connection
$ sdran e2sub list subscriptions  #Shows the kpimon app subscrition to the CU/DU nodes
$ sdran kpimon list numues        #Shows the list of associated UEs in the kpimon app 
```

## Run the User Equipment (UE) on the OAI-UE machine

After changing the file `sdran-in-a-box-values.yaml`, run the following commands:

```bash
$ cd /path/to/sdran-in-a-box
$ sudo apt install build-essential
$ make oai-ue-usrp
```

This step might take some time due to the download of the oai-ue docker image.
After the condition (pod/oai-ue-0 condition met) were achieved proceed to the next topic.

The pod pod/oai-ue-0 takes some time to start as it needs to configure the USRP first.

### Check the UE registration


In the ONOS-RIC machine, log in the onos-cli pod, running:

```bash
$ kubectl -n riab exec -ti deployment/onos-sdran-cli -- bash
```

Once inside the onos-cli pod, check the ONOS-RIC connections and subscriptions:

```bash
$ sdran kpimon list numues        #Shows the list of associated UEs in the kpimon app 
```

In the kpimon output, there should appear 1 UE registered. It means the UE was attached to the DU/CU setup.


## Cleaning

### Reset RIC (ONOS-RIC machine)
$ make reset-ric

### Reset OMEC (EPC-OMEC machine)
$ make reset-omec

### Reset OAI CU/DU/UE (OAI-CU/DU and OAI-UE NUC machines)
$ make reset-oai

### Delete/Reset charts for RiaB (All machines)
This deletes all deployed Helm charts for SD-RAN development/test (i.e., Atomix, RIC, OAI, and OMEC). It does not delete K8s, Helm, or other software.
```bash
$ make reset-test
```

### Completely delete/reset RiaB (All machines)
This deletes not only deployed Helm chart but also Kubernetes and Helm.

```bash
make clean      # if we want to keep the ~/helm-charts directory - option to develop/test changed/new Helm charts
make clean-all  # if we also want to delete ~/helm-charts directory
```


## Custom Settings

### Network Routes and IP Addresses

It is important to explain the custom settings associated with the hardware setup described, in specific the network routes and IP addresses defined in the EPC-OMEC router and the OAI-CU/DU machine and the cu.onf.conf file.

In the EPC-OMEC, a router Pod (running the Quagga engine) interconnects the core, enb and access networks, each one respectively in the following subnets 192.168.11.0/29, 192.168.11.8/29, and 192.168.11.16/29.

Via the definition of the secondary IP address (192.168.11.10/29) in the OAI-CU/DU machine, it was possible to configure the EPC-OMEC core to forward traffic to the host 192.168.11.10 via the gateway 192.168.13.21 (the primary OAI-CU/DU IP address).

In the OAI-CU/DU machine, the set of routes had to be configured so the traffic from the CU/DU be forwarded to the EPC-OMEC machine.

Inside the router of the EPC-OMEC, a route had to be configured to reach the secondary IP address of OAI-CU/DU via the enb interface.

And the cu.onf.conf file in the OAI-CU/DU machine had to be correctly configured using the IP addresses of the MME (EPC-CORE) and RIC machines.

**Notice, in summary the routing rule and IP addresses configuration are performed so OAI-CU/DU can reach EPC-OMEC and vice-versa.**

### User Equipment (UE)
As of now, the current OAI with RiaB setup is running over LTE Band 7.
To communicate with this setup, we should prepare the Android smartphone which supports LTE Band 7.
We should then insert a SIM card to the smartphone, where the SIM card should have the below IMSI, Key, and OPc values:

* IMSI: `315010999912340-315010999912370`
* Key: `465b5ce8b199b49faa5f0a2ee238a6bc`
* OPc: `69d5c2eb2e2e624750541d3bbc692ba5`

If we want to use the different IMSI number, we have to change the HSS configuration.
In order to change SIM information in HSS, we first go to the ONOS-RIC machine and open the `sdran-in-a-box-values.yaml` file.
And change this section to the appropriate number:
```yaml
  hss:
    bootstrap:
      users:
        - apn: "internet"
          key: "000102030405060708090a0b0c0d0e0f" # Change me
          opc: "69d5c2eb2e2e624750541d3bbc692ba5" # Change me
          sqn: 135
          imsiStart: "315010999912340" # Change me
          msisdnStart: "9999334455"
          count: 30
```

If the new SIM information has the different PLMN ID, we should also change the PLMN ID into MME, HSS, CU-CP, and DU configuration files.
We should find PLMN ID or MCC/MNC values and change them to the appropriate number.

`sdran-in-a-box-values.yaml`:
```yaml
  spgwc:
    pfcp: true
    multiUpfs: true
    jsonCfgFiles:
      subscriber_mapping.json:
        subscriber-selection-rules:
          - selected-user-plane-profile: "menlo"
            keys:
              serving-plmn:
                mcc: 315 # Change me
                mnc: 10 # Change me
...
  mme:
    cfgFiles:
      config.json:
        mme:
          logging: debug
          mcc:
            dig1: 3 # Change me
            dig2: 1 # Change me
            dig3: 5 # Change me
          mnc:
            dig1: 0 # Change me
            dig2: 1 # Change me
            dig3: 0 # Change me
          apnlist:
            internet: "spgwc"
```

`cu.onf.conf`:
```text
tracking_area_code = 1001;
plmn_list = ( { mcc = 315; mnc = 010; mnc_length = 3; } ) // Change me
```

`du.onf.conf`:
```text
tracking_area_code = 1001;
plmn_list = ( { mcc = 315; mnc = 010; mnc_length = 3; } ) // Change me
```

## Baremetal Installation

### Install UHD driver and push UHD image to USRP B210 device
Once we finished to check that the power management and CPU frequency configuration are good, we should reboot NUC machine again.
After the NUC is completely rebooted, then we should connect the USRP B210 device to the NUC machine.
To make the USRP B210 device run along with the NUC board, we should install UHD driver on the NUC machine.
And then, we should push the UHD image to USRP B210 device.
```bash
$ # Install UHD driver
$ sudo apt-get install libuhd-dev libuhd003 uhd-host
$ # Push UHD image to the USRP B210 device
$ sudo uhd_images_downloader
```

*NOTE 1: When we cannot install `libuhd003`, we can replace it with `libuhd003.010.003`.*

*NOTE 2: USRP B210 device has a power cable. We should keep that plugged in.*
*If we plugged off the USRP B210 power due to whatever reasons, we should push UHD image to USRP B210 device again by using `uhd_image_downloader` command.*

### Verification of UHD driver installation and UHD image push
In order to verify the UHD driver installation and UHD image push to the USRP B210 driver, we can use below command.
```bash
$ uhd_usrp_probe
[INFO] [UHD] linux; GNU C++ version 7.5.0; Boost_106501; UHD_3.15.0.0-release
[INFO] [B200] Detected Device: B210
[INFO] [B200] Operating over USB 2.
[INFO] [B200] Initialize CODEC control...
[INFO] [B200] Initialize Radio control...
[INFO] [B200] Performing register loopback test...
[INFO] [B200] Register loopback test passed
[INFO] [B200] Performing register loopback test...
[INFO] [B200] Register loopback test passed
[INFO] [B200] Setting master clock rate selection to 'automatic'.
[INFO] [B200] Asking for clock rate 16.000000 MHz...
[INFO] [B200] Actually got clock rate 16.000000 MHz.
  _____________________________________________________
 /
|       Device: B-Series Device
|     _____________________________________________________
|    /
|   |       Mboard: B210
|   |   serial: 31EABDC
|   |   name: MyB210
|   |   product: 2
|   |   revision: 4
|   |   FW Version: 8.0
|   |   FPGA Version: 16.0
|   |
|   |   Time sources:  none, internal, external, gpsdo
|   |   Clock sources: internal, external, gpsdo
|   |   Sensors: ref_locked
|   |     _____________________________________________________
|   |    /
|   |   |       RX DSP: 0
|   |   |
|   |   |   Freq range: -8.000 to 8.000 MHz
|   |     _____________________________________________________
|   |    /
|   |   |       RX DSP: 1
|   |   |
|   |   |   Freq range: -8.000 to 8.000 MHz
|   |     _____________________________________________________
|   |    /
|   |   |       RX Dboard: A
|   |   |     _____________________________________________________
|   |   |    /
|   |   |   |       RX Frontend: A
|   |   |   |   Name: FE-RX2
|   |   |   |   Antennas: TX/RX, RX2
|   |   |   |   Sensors: temp, rssi, lo_locked
|   |   |   |   Freq range: 50.000 to 6000.000 MHz
|   |   |   |   Gain range PGA: 0.0 to 76.0 step 1.0 dB
|   |   |   |   Bandwidth range: 200000.0 to 56000000.0 step 0.0 Hz
|   |   |   |   Connection Type: IQ
|   |   |   |   Uses LO offset: No
|   |   |     _____________________________________________________
|   |   |    /
|   |   |   |       RX Frontend: B
|   |   |   |   Name: FE-RX1
|   |   |   |   Antennas: TX/RX, RX2
|   |   |   |   Sensors: temp, rssi, lo_locked
|   |   |   |   Freq range: 50.000 to 6000.000 MHz
|   |   |   |   Gain range PGA: 0.0 to 76.0 step 1.0 dB
|   |   |   |   Bandwidth range: 200000.0 to 56000000.0 step 0.0 Hz
|   |   |   |   Connection Type: IQ
|   |   |   |   Uses LO offset: No
|   |   |     _____________________________________________________
|   |   |    /
|   |   |   |       RX Codec: A
|   |   |   |   Name: B210 RX dual ADC
|   |   |   |   Gain Elements: None
|   |     _____________________________________________________
|   |    /
|   |   |       TX DSP: 0
|   |   |
|   |   |   Freq range: -8.000 to 8.000 MHz
|   |     _____________________________________________________
|   |    /
|   |   |       TX DSP: 1
|   |   |
|   |   |   Freq range: -8.000 to 8.000 MHz
|   |     _____________________________________________________
|   |    /
|   |   |       TX Dboard: A
|   |   |     _____________________________________________________
|   |   |    /
|   |   |   |       TX Frontend: A
|   |   |   |   Name: FE-TX2
|   |   |   |   Antennas: TX/RX
|   |   |   |   Sensors: temp, lo_locked
|   |   |   |   Freq range: 50.000 to 6000.000 MHz
|   |   |   |   Gain range PGA: 0.0 to 89.8 step 0.2 dB
|   |   |   |   Bandwidth range: 200000.0 to 56000000.0 step 0.0 Hz
|   |   |   |   Connection Type: IQ
|   |   |   |   Uses LO offset: No
|   |   |     _____________________________________________________
|   |   |    /
|   |   |   |       TX Frontend: B
|   |   |   |   Name: FE-TX1
|   |   |   |   Antennas: TX/RX
|   |   |   |   Sensors: temp, lo_locked
|   |   |   |   Freq range: 50.000 to 6000.000 MHz
|   |   |   |   Gain range PGA: 0.0 to 89.8 step 0.2 dB
|   |   |   |   Bandwidth range: 200000.0 to 56000000.0 step 0.0 Hz
|   |   |   |   Connection Type: IQ
|   |   |   |   Uses LO offset: No
|   |   |     _____________________________________________________
|   |   |    /
|   |   |   |       TX Codec: A
|   |   |   |   Name: B210 TX dual DAC
|   |   |   |   Gain Elements: None
```

If we see the above results which shows the device name `B210`, we are good to go.

### Build OAI

The OAI repository (https://github.com/onosproject/openairinterface5g) used in this tutorial requires member-only access, a user should log in github and then check the git clone command on that web site.

After the USRP configuration, we should build the OAI code.
```bash
$ git clone https://github.com/onosproject/openairinterface5g
$ cd /path/to/openairinterface5g
$ source oaienv
$ cd cmake_targets/
# $ ./build_oai -I -w USRP --eNB --UE 
# $ ./build_oai --eNB -c -w USRP
$ ./build_oai -c  --eNB --UE -w USRP -g --build-ric-agent
```

*NOTE: It takes really a long time to build OAI.*


### Configure CU-CP on the OAI NUC
After that, we should copy the sample CU-CP configuration file in the HOME directory.
```bash
$ cp /path/to/openairinterface5g/ci-scripts/conf_files/cu.band7.tm1.25PRB.conf ~/cu.onf.conf
```

Then, modify below parameters in the copied file `~/cu.onf.conf`:
```text
…
////////// RIC parameters:
RIC : {
    remote_ipv4_addr = "192.168.10.22";
    remote_port = 36421;
    enabled = "yes";
};
…

tracking_area_code = 1;
plmn_list = ( { mcc = 315; mnc = 010; mnc_length = 3; } )
…
    ////////// MME parameters:
    mme_ip_address  = (
      {
        ipv4       = "192.168.10.21";    // *Write down EPC-CORE SDRAN-in-a-Box IP*
        ipv6       = "192:168:30::17";  // *Don’t care*
        active     = "yes";
        preference = "ipv4";
      }
    );

    NETWORK_INTERFACES : {
      ENB_INTERFACE_NAME_FOR_S1_MME = "eno1";             // Ethernet interface name of OAI NUC
      ENB_IPV4_ADDRESS_FOR_S1_MME   = "192.168.13.21/16";  // OAI NUC IP address
      ENB_INTERFACE_NAME_FOR_S1U    = "eno1";             // Ethernet interface name of OAI NUC
      ENB_IPV4_ADDRESS_FOR_S1U      = "192.168.11.10/29";  // Write the secondary IP address which we set above
      ENB_PORT_FOR_S1U              = 2152; # Spec 2152   # Don't touch
      ENB_IPV4_ADDRESS_FOR_X2C      = "192.168.13.21/16";  // OAI NUC IP address
      ENB_PORT_FOR_X2C              = 36422; # Spec 36422 # Don't touch
    };
  }

```

### Configure DU on the OAI NUC
Likewise, we should copy the sample DU configuration file in the HOME directory.
```bash
$ cp /path/to/openairinterface5g/ci-scripts/conf_files/du.band7.tm1.25PRB.conf ~/du.onf.conf
```

And then, we should open the copied file `~/du.onf.conf` and change the blow variables:
```text
tracking_area_code = 1001;
plmn_list = ( { mcc = 315; mnc = 010; mnc_length = 3; } )
```

### Run CU and DU in the OAI-CU/DU machine

Before running CU and DU, make sure to follow the instructions provided at [Network Parameter Configuration](#network-parameter-configuration).

#### Run CU-CP
On the OAI NUC machine, we should go to `/path/to/openairinterface5g/cmake_targets/ran_build/build` and run the command below:
```bash
ENODEB=1 sudo -E ./lte-softmodem -O ~/cu.onf.conf
```

#### Run DU
After CU-CP is running, in another terminal we should go to `/path/to/openairinterface5g/cmake_targets/ran_build/build` and  run the command below:
```bash
while true; do ENODEB=1 sudo -E ./lte-softmodem -O ~/du.onf.conf; done
```

### Run the User Equipment (UE) on the OAI-UE machine

On the OAI-UE NUC machine, we should go to `/path/to/openairinterface5g/cmake_targets/ran_build/build` and run the command below:

Write down a file named ~/sim.conf with the following content:

```text
# List of known PLMNS
PLMN: {
    PLMN0: {
           FULLNAME="Test network";
           SHORTNAME="OAI4G";
           MNC="01";
           MCC="001";

    };
    PLMN1: {
           FULLNAME="SFR France";
           SHORTNAME="SFR";
           MNC="10";
           MCC="208";

    };
    PLMN2: {
           FULLNAME="SFR France";
           SHORTNAME="SFR";
           MNC="11";
           MCC="208";
    };
    PLMN3: {
           FULLNAME="SFR France";
           SHORTNAME="SFR";
           MNC="13";
           MCC="208";
    };
    PLMN4: {
           FULLNAME="Aether";
           SHORTNAME="Aether";
           MNC="010";
           MCC="315";
    };
    PLMN5: {
           FULLNAME="T-Mobile USA";
           SHORTNAME="T-Mobile";
           MNC="280";
           MCC="310";
    };
    PLMN6: {
           FULLNAME="FICTITIOUS USA";
           SHORTNAME="FICTITIO";
           MNC="028";
           MCC="310";
    };
    PLMN7: {
           FULLNAME="Vodafone Italia";
           SHORTNAME="VODAFONE";
           MNC="10";
           MCC="222";
    };
    PLMN8: {
           FULLNAME="Vodafone Spain";
           SHORTNAME="VODAFONE";
           MNC="01";
           MCC="214";
    };
    PLMN9: {
           FULLNAME="Vodafone Spain";
           SHORTNAME="VODAFONE";
           MNC="06";
           MCC="214";
    };
    PLMN10: {
           FULLNAME="Vodafone Germ";
           SHORTNAME="VODAFONE";
           MNC="02";
           MCC="262";
    };
    PLMN11: {
           FULLNAME="Vodafone Germ";
           SHORTNAME="VODAFONE";
           MNC="04";
           MCC="262";
    };
};

UE0:
{
    USER: {
        IMEI="356113022094149";
        MANUFACTURER="EURECOM";
        MODEL="LTE Android PC";
        PIN="0000";
    };

    SIM: {
        MSIN="206000001";
        USIM_API_K="000102030405060708090a0b0c0d0e0f";
        OPC=       "69d5c2eb2e2e624750541d3bbc692ba5";
        MSISDN="1122334455";
    };

    # Home PLMN Selector with Access Technology
    HPLMN= "315010";

    # User controlled PLMN Selector with Access Technology
    UCPLMN_LIST = ();

    # Operator PLMN List
    OPLMN_LIST = ("00101", "20810", "20811", "20813", "315010", "310280", "310028");

    # Operator controlled PLMN Selector with Access Technology
    OCPLMN_LIST = ("22210", "21401", "21406", "26202", "26204");

    # Forbidden plmns
    FPLMN_LIST = ();

    # List of Equivalent HPLMNs
#TODO: UE does not connect if set, to be fixed in the UE
#    EHPLMN_LIST= ("20811", "20813");
    EHPLMN_LIST= ();
};

```

Then execute the command below to generate the UE settings.

```bash
../../nas_sim_tools/build/conf2uedata -c ~/sim.conf -o .
```

After that, initialize the UE process:

```bash
sudo ./lte-uesoftmodem -C 2630000000 -r 25 --ue-rxgain 120 --ue-txgain 0 --ue-max-power 0 --ue-scan-carrier --nokrnmod 1  2>&1 | tee UE.log
```



## Troubleshooting
This section covers how to solve the reported issues. This section will be updated, continuously.

### SPGW-C or UPF is not working
Please check the log with below commands:
```bash
$ kubectl logs spgwc-0 -n riab -c spgwc # for SPGW-C log
$ kubectl logs upf-0 -n riab -c bess # for UPF log
```

In the log, if we can see `unsupported CPU type` or `a specific flag (e.g., AES) is missing`, we should check the CPU microarchitecture. RiaB requires Intel Haswell or more recent CPU microarchitecture.
If we have the appropriate CPU type, we should build SPGW-C or UPF image on the machine where RiaB will run.

To build SPGW-C, first clone the SPGW-C repository on the machine with `git clone https://github.com/omec-project/spgw`. Then, edit below line in Makefile:
```makefile
DOCKER_BUILD_ARGS        ?= --build-arg RTE_MACHINE='native'
```
Then, run `make` on the `spgw` directory.

Likewise, for building UPF image, we should clone UPF repository with `git clone https://github.com/omec-project/upf-epc`. Then, edit below line in Makefile:
```makefile
CPU                      ?= native
```
Then, run `make` on the `upf-epc` directory.

After building those images, we should modify overriding value yaml file (i.e., `sdran-in-a-box-values.yaml`). Go to the file and write down below:
```yaml
images:
  tags:
    spgwc: <spgwc_image_tag>
    bess: <bess_upf_image_tag>
    pfcpiface: <pfcpiface_upf_image_tab>
  pullPolicy: IfNotPresent
```
Then, run below commands:
```bash
$ cd /path/to/sdran-in-a-box
$ make reset-test
# after all OMEC pods are deleted, run make again
$ make
```

### ETCD is not working
Sometimes, we see the below outputs when building RiaB.
```text
TASK [etcd : Configure | Ensure etcd is running] ***********************************************************************
FAILED - RETRYING: Configure | Check if etcd cluster is healthy (4 retries left).
FAILED - RETRYING: Configure | Check if etcd cluster is healthy (3 retries left).
FAILED - RETRYING: Configure | Check if etcd cluster is healthy (2 retries left).
FAILED - RETRYING: Configure | Check if etcd cluster is healthy (1 retries left).
```

If we see this, we can command below:
```bash
$ sudo systemctl restart docker
$ cd /path/to/sdran-in-a-box
$ make
```

### Atomix controllers cannot be deleted/reset
Sometimes, Atomix controllers cannot be deleted (maybe we will get stuck when deleting Atomix controller pods) when we command `make reset-test`.
```bash
rm -f /tmp/build/milestones/oai-enb-cu
rm -f /tmp/build/milestones/oai-enb-du
rm -f /tmp/build/milestones/oai-ue
helm delete -n riab sd-ran || true
release "sd-ran" uninstalled
cd /tmp/build/milestones; rm -f ric
kubectl delete -f https://raw.githubusercontent.com/atomix/kubernetes-controller/master/deploy/atomix-controller.yaml || true
customresourcedefinition.apiextensions.k8s.io "databases.cloud.atomix.io" deleted
customresourcedefinition.apiextensions.k8s.io "partitions.cloud.atomix.io" deleted
customresourcedefinition.apiextensions.k8s.io "members.cloud.atomix.io" deleted
customresourcedefinition.apiextensions.k8s.io "primitives.cloud.atomix.io" deleted
serviceaccount "atomix-controller" deleted
clusterrole.rbac.authorization.k8s.io "atomix-controller" deleted
clusterrolebinding.rbac.authorization.k8s.io "atomix-controller" deleted
service "atomix-controller" deleted
deployment.apps "atomix-controller" deleted
```

If the script is stopped here, we can command:
```bash
# Commmand Ctrl+c first to stop the Makefile script if the make reset-test is got stuck. Then command below.
$ make reset-atomix # Manually delete Atomix controller pods
$ make atomix # Manually install Atomix controller pods
$ make reset-test # Then, make reset-test again
```

Or, sometimes we see this when deploying RiaB:
```text
Error from server (AlreadyExists): error when creating "https://raw.githubusercontent.com/atomix/kubernetes-controller/master/deploy/atomix-controller.yaml": object is being deleted: customresourcedefinitions.apiextensions.k8s.io "members.cloud.atomix.io" already exists
Makefile:231: recipe for target '/tmp/build/milestones/atomix' failed
```

In this case, we can manually delete atomix with the command `make atomix || make reset-atomix`, and then resume to deploy RiaB.

### Pod onos-consensus-db-1-0 initialization failed

In Ubuntu 20.04 (kernel 5.4.0-65-generic), the k8s pod named `onos-consensus-db-1-0` might fail due to a bug of using go and alpine together (e.g., https://github.com/docker-library/golang/issues/320). 

It can be seen in `kubectl logs -n riab onos-consensus-db-1-0` as:
```bash
runtime: mlock of signal stack failed: 12
runtime: increase the mlock limit (ulimit -l) or
runtime: update your kernel to 5.3.15+, 5.4.2+, or 5.5+
fatal error: mlock failed
```

Such pod utilizes the docker image atomix/raft-storage-node:v0.5.3, tagged from the build of the image atomix/dragonboat-raft-storage-node:latest available at https://github.com/atomix/dragonboat-raft-storage-node.

A quick fix (allowing an unlimited amount memory to be locked by the pod) to this issue is cloning the repository https://github.com/atomix/dragonboat-raft-storage-node, and changing the Makefile:

```bash
# Before change
image: build
	docker build . -f build/dragonboat-raft-storage-node/Dockerfile -t atomix/dragonboat-raft-storage-node:${RAFT_STORAGE_NODE_VERSION}

# After change: unlimited maximum locked-in-memory address space
image: build
	docker build --ulimit memlock=-1 . -f build/dragonboat-raft-storage-node/Dockerfile -t atomix/dragonboat-raft-storage-node:${RAFT_STORAGE_NODE_VERSION}
```

Then running in the source dir of this repository the command `make image`, and tagging the built image as:

```bash
docker tag atomix/dragonboat-raft-storage-node:latest  atomix/raft-storage-node:v0.5.3
```

After that proceed with the execution of the Riab setup again. 


### Other issues?
Please contact ONF SD-RAN team, if you see any issue. Any issue report from users is very welcome.
Mostly, the redeployment by using `make reset-test and make [option]` resolves issues.