<h1 align="center">SD-RAN Hardware Installation</h1>

&nbsp;

# 1. Overall Connectivity

![SD-RAN Hardware Scenario](./SD-RAN%20Hardware%20Setting.png)

For the SD-RAN hardware scenario, we should have two servers (NUCs), one USRP, and one UE. The above figure shows the overall connectivity for the scenario. Each NUC has an IP address and they are connected with a L3 router with NAT functionality. In this document, we are assuming that the NUC for OAI CU/DU has a machine IP address 192.168.1.107. The CU and DU have the logical IP addresses 192.168.1.107 and 192.168.1.109, respectively. The NUC for RIC/Core Network (CN) has a machine IP address 192.168.1.108. The NUC for OAI is connected with the USRP B210 device with USB 3.0 cable.

&nbsp;

# 2. Requirements
- USRP B210
- NUC for OAI
    - CPU: > 6 cores, Intel CPU, Broadwell or later microarchitecture
    - RAM: > 32 GB
    - Disk: > 100 GB
    - OS: Ubuntu 18.04 server

- NUC for RIC/CN
    - CPU: > 10 cores, Intel CPU, Broadwell or later microarchitecture
    - RAM: > 64 GB
    - Disk: > 100 GB
    - OS: Ubuntu 18.04 server
- UE
    - LTE B7 supported phone (Samsung J5 and S20 supported)
- SIM card
    - PLMN ID: 315010

&nbsp;

&nbsp;

# 3. NUC Configuration
## 3.1 NUC for OAI
We will configure the NUC for OAI. Before we start, we should make sure that the USRP B210 is NOT connected with the NUC. Otherwise, the NUC will be in trouble while booting up. When we boot up the NUC, we should enter the bios configuration and then change some parameters:
- Disable secure booting option
- Disable hyperthreading
- Enable virtualization (VT-d, etc)
- Disable all power management functions (c-/p-state related)
- Enable real-time tuning
- Enable Intel Turbo boost

After the Bios configuration, we should install Ubuntu 18.04 server and set our Linux user as an administrator.

Then, we should update the Linux kernel, install some tools, and change some configuration parameters. First of all, we should install Linux low-latency kernel image with the below command:
```bash
$ sudo apt install linux-image-lowlatency linux-headers-lowlatency
```

Second, we should configure the power management and CPU frequency parameters. Go to ***“/etc/default/grub”*** file and change the ***“GRUB_CMDLINE_LINUX_DEFAULT”*** line as below:
```ini
GRUB_CMDLINE_LINUX_DEFAULT="quiet intel_pstate=disable processor.max_cstate=1 intel_idle.max_cstate=0 idle=poll"
```

After saving it, we should run the below command:
```bash
$ sudo update-grub2
```

Once it was done successfully, go to ***“/etc/modprobe.d/blacklist.conf”*** file and append below at the end of the file:

```conf
# for OAI
blacklist intel_powerclamp
```

After saving the file, reboot the machine. When the NUC is up again, we should install `cpufrequtils` tool with the below command:

```bash
$ sudo apt-get install cpufrequtils
```

Then, create or open ***“/etc/default/cpufrequtils”*** file and write below:
```ini
GOVERNOR="performance"
```

Finally, we should run below commands:
```bash
$ sudo systemctl disable ondemand.service
$ sudo /etc/init.d/cpufrequtils restart
```

Then, reboot the NUC one more time.

If we want to verify that the NUC is configured well, we can leverage the `i7z` tool. Install this tool and run it with the below command:
```bash
$ sudo apt install i7z 
$ sudo i7z 
True Frequency (without accounting Turbo) 1607 MHz 
    CPU Multiplier 16x || Bus clock frequency (BCLK) 100.44 MHz 
Socket [0] - [physical cores=6, logical cores=6, max online cores ever=6]
    TURBO ENABLED on 6 Cores, Hyper Threading OFF
    Max Frequency without considering Turbo 1707.44 MHz (100.44 x [17])
    Max TURBO Multiplier (if Enabled) with 1/2/3/4/5/6 Cores is
47x/47x/41x/41x/39x/39x
    Real Current Frequency 3058.82 MHz [100.44 x 30.45] (Max of below)
     Core [core-id] :Actual Freq (Mult.) C0% Halt(C1)% C3% C6% Temp VCore
    Core 1   [0]    :3058.81    (30.45x) 100     0      0   0   64  0.9698 
    Core 2   [1]    :3058.82    (30.45x) 100     0      0   0   63  0.9698 
    Core 3   [2]    :3058.82    (30.45x) 100     0      0   0   64  0.9698 
    Core 4   [3]    :3058.81    (30.45x) 100     0      0   0   64  0.9698 
    Core 5   [4]    :3058.81    (30.45x) 100     0      0   0   65  0.9698 
    Core 6   [5]    :3058.82    (30.45x) 100     0      0   0   62  0.9686
```

If we can see that all cores have **C0%** as **100** and **Halt(C1)%** as **0**, everything is good.

&nbsp;

## 3.2 NUC for SD-Core and RIC
The NUC for SD-Core and RIC is good to go if it runs with Ubuntu 18.04 server.

&nbsp;

&nbsp;

# 4. SD-Core and RIC deployment
After setting all the NUCs, we will then deploy the SD-Core and RIC. Go to the NUC for SD-Core and RIC, download the SDRAN-in-a-Box with below command:
```bash
$ git clone https://github.com/onosproject/sdran-in-a-box
```
Note that we will use the master branch and the latest commit is this:
[https://github.com/onosproject/sdran-in-a-box/commit/68a91e5d15f64f34330e248e8dbac220d70a4dff](https://github.com/onosproject/sdran-in-a-box/commit/68a91e5d15f64f34330e248e8dbac220d70a4dff)


&nbsp;

After getting the code, we should modify the ***“sdran-in-a-box-master-stable.yaml”*** file in the ***“sdran-in-a-box”*** directory. The modified file is attached in the **Appendix A**. Copy and then paste this file in ***sdran-in-a-box*** directory. Then, we deploy SD-Core first with the below command:
```bash
$ cd sdran-in-a-box
$ make omec
```
Note that if the NUC does not have `make`, install `build-essential` package with below command
```bash
$ sudo apt install build-essential
```

Similarly, if the NUC does not have `curl` installed, you need to install it using the command below. `curl` is essential for downloading and installing Kubernetes and Helm.
```bash
$ sudo apt install curl
```

If there is no error message on our screen, SD-Core is deployed successfully. To make sure, we can check if there is no error with the below command:
```bash
$ kubectl get pods --all-namespaces
```

If we can see no error status, SD-Core is now ready.

Next, we should deploy RIC on the same machine. We can deploy it with the below command:
```bash
$ make OPT=ric
```

If it is done without any error, RIC is also ready. We can verify it with below command:
```bash
$ kubectl get pods --all-namespaces
```

Likewise, if there is no error status, RIC is also ready.

After those deployments, we should update some network configuration manually. First, we should disable TCP tx/rx checksum and GRO with this:
```bash
$ sudo ethtool -K eno1 rx off tx on gro off gso on
$ sudo ethtool -K enb rx off tx on gro off gso on
$ sudo ethtool -K <calico_router> tx off rx off gro off gso on
```

You can check your *eno1* interface using the **ip a** command.

Note: here the ***“<calico_router>”*** should be replaced with the real calico network interface like ***“cali09d96a0e9e0”***. We can get this interface name with below command:
```bash
route -n | grep $(kubectl get po -o wide --no-headers | awk '{print $6}') | awk '{print $NF}'
```

Next, add ***net.ipv4.ip_forward=1*** to ***“/etc/sysctl.conf”*** file and apply the changes using the **sysctl -p** command.

After that, configure the following forward rule in iptables for the *enb* interface:
```bash
$ sudo iptables -A FORWARD -o enb -j ACCEPT
$ sudo iptables -A FORWARD -i enb -j ACCEPT
```

Next, enter the following commands:
```bash
$ ifconfig eno1 mtu 1500
$ ifconfig enb mtu 1550
$ ethtool -K eno1 gso off gro off
```

Then, add the routing rules:
```bash
$ sudo route add -host 192.168.251.100 gw 192.168.1.107 dev eno1
$ sudo route add -host 192.168.251.100 gw 192.168.1.109 dev eno1
```

Next, we should go to the internal router and then change some network parameters. Follow the below command:
```bash
$ kubectl exec -it router -- bash
router$ route add -host 192.168.251.100 gw 192.168.251.4 dev enb-rtr
router$ route add -host 192.168.1.107 gw 192.168.251.4 dev enb-rtr
router$ route add -host 192.168.1.109 gw 192.168.251.4 dev enb-rtr
router$ ifconfig core-rtr mtu 1550
router$ ifconfig access-rtr mtu 1550
router$ ifconfig enb-rtr mtu 1550
router$ apt install ethtool
router$ ethtool -K eth0 tx off rx off gro off gso off
router$ ethtool -K enb-rtr tx off rx off gro off gso off
router$ ethtool -K access-rtr tx off rx off gro off gso off
router$ ethtool -K core-rtr tx off rx off gro off gso off
```

Last, we should go to UPF and then change MTU size with below commands:
```bash
$ kubectl exec -it upf-0 -n riab -- bash
upf$ ip l set mtu 1550 dev access
upf$ ip l set mtu 1550 dev core
```

&nbsp;

&nbsp;

# 5. OAI CU/DU Build and Run
Once SD-Core and RIC are ready, we should build and run OAI CU and DU. After booting this NUC up, now connect the USRP B210 board to the USB 3.0 port. After that, run the below commands to install USRP driver and push UHD image into USRP B210 board:
```bash
$ sudo apt-get install libuhd-dev libuhd003 uhd-host
$ sudo uhd_images_downloader
$ uhd_usrp_probe # have to see some outputs - USRP B210 information
```
※ You can install a different version instead of libuhd003.

Note that if ***“libuhd003”*** makes some errors, we can replace it with ***“libuhd003.010.003”***.

Then, we should build OAI CU and DU. We should clone the ***“openairinterface5g”*** code and then build it with the below commands:
```bash
$ git clone https://github.com/onosproject/openairinterface5g.git
$ cd openairinterfae5g
$ source oaienv
$ cd cmake_targets/
$ ./build_oai -c -I --eNB -w USRP --build-ric-agent --build-ran-slicing
```

If there is no error message, OAI CU and DU build is successfully done.

Next, we should add one IP address on the ***“eno1”*** interface which is the network interface connected to the router with the IP address 192.168.1.107.
```bash
$ sudo ip a add 192.168.251.100/24 dev eno1
```

After that, you also need to add the logical IP for DU.
```bash
$ sudo ip a add 192.168.1.109/24 dev eno1
```
(i.e,. The network interface ***“eno1”*** should have three IP addresses: 192.168.1.107, 192.168.1.109, and 192.168.251.100)

And then, run the below commands to add some routing rules and disable TX/RX checksum and GRO:
```bash
$ sudo ethtool -K eno1 tx off rx off gro off gso off
$ sudo route del -net 192.168.251.0/24 dev eno 1 # ignore error if happened
$ sudo route add -net 192.168.250.0/24 gw 192.168.1.108 dev eno1
$ sudo route add -net 192.168.251.0/24 gw 192.168.1.108 dev eno1
$ sudo route add -net 192.168.252.0/24 gw 192.168.1.108 dev eno1
$ sudo route add -net 192.168.84.0/24 gw 192.168.1.108 dev eno1
```

After that, we should prepare CU and DU configuration files. **Appendix B** and **Appendix C** have CU and DU configuration files, respectively. Copy those files to the NUC for the OAI CU/DU.

Once those configurations are done and the configuration files for both CU and DU are ready, we can run CU and DU now. To run the CU and DU simultaneously, we should open two terminals. Of course, alternatively, we can use the `tmux` or the `screen` tool. On the first terminal, run the below command to run CU:
```bash
$ cd openairinterface5g/cmake_targets/ran_build/build
$ sudo ./lte-softmodem -O /path/to/cu.conf
```

Once the CU shows no error messages and prints some messages repeatedly, run the below command on the second terminal to run DU:
```bash
$ cd openairinterface5g/cmake_targets/ran_build/build
$ sudo ./lte-softmodem -O /path/to/du.conf
```

Note: we should write the correct path for *cu.conf* and *du.conf*.

&nbsp;

&nbsp;

# 6. Test and Verification
For the test, we can use a UE - smartphone. If the smartphone has the right SIM card (Aether SIM is ok), we can start testing it. For the attachment test (i.e,. LTE control plane test), we can toggle on and off the Airplane mode. If we can see that the antenna sign on the smartphone is up and we can see “LTE” sign, this phone is attached. We can also verify it by capturing packets with tcpdump on the NUC for SD-Core and RIC. If we can see correct S1AP message exchanges, the phone is attached. And for the LTE user plane test, we can easily run ping on the special smartphone application or just do web surfing like going to google.com and searching something.

For the test with RIC, we can follow those steps:
KPIMON and NIB test (follow this on the NUC for SD-Core and RIC):
[https://docs.sd-ran.org/master/sdran-in-a-box/docs/Installation_OAI_nFAPI.html#the-e2e-test-on-sd-ran-control-plane](https://docs.sd-ran.org/master/sdran-in-a-box/docs/Installation_OAI_nFAPI.html#the-e2e-test-on-sd-ran-control-plane)
Slicing test (follow this on the NUC for SD-Core and RIC):
[https://docs.sd-ran.org/master/sdran-in-a-box/docs/Installation_OAI_nFAPI.html#the-rsm-e2e-tests](https://docs.sd-ran.org/master/sdran-in-a-box/docs/Installation_OAI_nFAPI.html#the-rsm-e2e-tests)

&nbsp;

&nbsp;

# Appendix A. sdran-in-a-box-master-stable.yaml file
```YAML
# Copyright 2020-present Open Networking Foundation
#
# SPDX-License-Identifier: Apache-2.0

# cassandra values
cassandra:
  config:
    cluster_size: 1
    seed_size: 1

resources:
  enabled: false

5g-control-plane:
  enable5G: false

5g-ran-sim:
  enable: false

omec-sub-provision:
  enable: false

omec-control-plane:
  enable4G: true
  config:
    coreDump:
      enabled: false
    hss:
      bootstrap:
        users:
          - apn: internet
            key: "465b5ce8b199b49faa5f0a2ee238a6bc"
            opc: "d4416644f6154936193433dd20a0ace0"
            sqn: 96
            imsiStart: "208014567891200"
            msisdnStart: "1122334455"
            mme_identity: mme.riab.svc.cluster.local
            mme_realm: riab.svc.cluster.local
            count: 10
        staticusers:
          - apn: internet
            key: "465b5ce8b199b49faa5f0a2ee238a6bc"
            opc: "d4416644f6154936193433dd20a0ace0"
            sqn: 96
            imsi: "208014567891300"
            msisdn: "1122334455"
            staticAddr: 0.0.0.0
            mme_identity: mme.riab.svc.cluster.local
            mme_realm: riab.svc.cluster.local
        mmes:
          - id: 1
            mme_identity: mme.riab.svc.cluster.local
            mme_realm: riab.svc.cluster.local
            isdn: "19136246000"
            unreachability: 1
    mme:
      cfgFiles:
        config.json:
          mme:
            apnlist:
              internet: "spgwc"
            plmnlist:
              plmn1: "mcc=315,mnc=010"
              plmn2: "mcc=208,mnc=01"
    spgwc:
      cfgFiles:
        cp.json:
          ip_pool_config:
            ueIpPool:
              ip: 172.250.0.0 # if we use RiaB, Makefile script will override this value with the value defined in MakefileVar.mk file.
            staticUeIpPool:
              ip: 172.249.0.0 # if we use RiaB, Makefile script will override this value with the value defined in MakefileVar.mk file.
        subscriber_mapping.json:
          subscriber-selection-rules:
            - priority: 5
              keys:
                serving-plmn:
                  mcc: 208
                  mnc: 10
                  tac: 1
                imsi-range:
                  from: 200000000000000
                  to: 299999999999999
              selected-apn-profile: apn-profile1
              selected-qos-profile: qos-profile1
              selected-access-profile:
                - access-all
              selected-user-plane-profile: user-plane1
            - priority: 10
              keys:
                match-all: true
              selected-apn-profile: apn-profile1
              selected-qos-profile: qos-profile1
              selected-access-profile:
                - access-all
              selected-user-plane-profile: user-plane1
          apn-profiles:
            apn-profile1:
              apn-name: internet
              usage: 1
              network: lbo
              gx_enabled: true
              dns_primary: 8.8.8.4
              dns_secondary: 8.8.8.8
              mtu: 1460
          user-plane-profiles:
            user-plane1:
              user-plane: upf
              global-address: true
              qos-tags:
                tag1: BW
              access-tags:
                tag1: ACC
          qos-profiles:
            mobile:
              qci: 9
              arp: 1
              apn-ambr:
                - 12345678
                - 12345678
          access-profiles:
            access-all:
              type: allow-all
            internet-only:
              type: internet-only
              filter: No_private_network
            intranet-only:
              type: intranet-only
              filter: only_private_network
            apps-only:
              type: specific-network
              filter: only_apps_network
            specific-app:
              type: specific-destination-only
              filter: allow-app-name
            excluding-app:
              type: excluding-this-app
              filter: exclude-app-name
omec-user-plane:
  resources:
    enabled: true
    bess:
      requests:
        cpu: 2
        memory: 2Gi
      limits:
        cpu: 2
        memory: 2Gi
    routectl:
      requests:
        cpu: 256m
        memory: 128Mi
      limits:
        cpu: 256m
        memory: 128Mi
    web:
      requests:
        cpu: 256m
        memory: 128Mi
      limits:
        cpu: 256m
        memory: 128Mi
    cpiface:
      requests:
        cpu: 256m
        memory: 128Mi
      limits:
        cpu: 256m
        memory: 128Mi
  enable: true
  config:
    upf:
      privileged: true
      enb:
        subnet: 192.168.251.0/24
      access:
        ipam: static
        cniPlugin: simpleovs
        gateway: 192.168.252.1
        ip: 192.168.252.3/24
      core:
        ipam: static
        cniPlugin: simpleovs
        gateway: 192.168.250.1
        ip: 192.168.250.3/24
      name: "oaisim"
      sriov:
        enabled: false
      hugepage:
        enabled: false
      cniPlugin: simpleovs
      ipam: static
      cfgFiles:
        upf.jsonc:
          mode: af_packet                # This mode implies no DPDK
          hwcksum: true
          log_level: "info"
          cpiface:
            dnn: "internet"
            hostname: "upf"
            enable_ue_ip_alloc: false
            ue_ip_pool: 172.250.0.0/16 # if we use RiaB, Makefile script will override this value with the value defined in MakefileVar.mk file.
          slice_rate_limit_config:       # Slice-level rate limiting (also controlled by ROC)
            # Uplink
            n6_bps: 10000000000          # 10Gbps
            n6_burst_bytes: 12500000     # 10ms * 10Gbps
            # Downlink
            n3_bps: 10000000000          # 10Gbps
            n3_burst_bytes: 12500000     # 10ms * 10Gbps

config:
  oai-enb-cu:
    networks:
      f1:
        interface: eno1 # if we use RiaB, Makefile script will automatically apply appropriate interface name
        address: 10.128.100.100 #if we use RiaB, Makefile script will automatically apply appropriate IP address
      s1mme:
        interface: eno1 # if we use RiaB, Makefile script will automatically apply appropriate interface name
      s1u:
        interface: enb
  oai-enb-du:
    mode: nfapi #or local_L1 for USRP and BasicSim
    networks:
      f1:
        interface: eno1 #if we use RiaB, Makefile script will automatically apply appropriate IP address
        address: 10.128.100.100 #if we use RiaB, Makefile script will automatically apply appropriate IP address
      nfapi:
        interface: eno1 #if we use RiaB, Makefile script will automatically apply appropriate IP address
        address: 10.128.100.100 #if we use RiaB, Makefile script will automatically apply appropriate IP address
  oai-ue:
    numDevices: 1 # support up to 3
    networks:
      nfapi:
        interface: eno1 #if we use RiaB, Makefile script will automatically apply appropriate IP address
        address: 10.128.100.100 #if we use RiaB, Makefile script will automatically apply appropriate IP address
  onos-e2t:
    enabled: "yes"
    networks:
      e2:
        address: 127.0.0.1 # if we use RiaB, Makefile script will automatically apply appropriate interface name
        port: 36401
# for 5g core
#  amf:
#    ngapp:
#      externalIp: 127.0.0.1
  smf:
    cfgFiles:
      smfcfg.conf:
        configuration:
          mongodb:
            name: smf
            url: mongodb://mongodb:27017
  pcf:
    cfgFiles:
      pcfcfg.conf:
        info:
          version: 1.0.0
          description: PCF initial local configuration
        configuration:
          mongodb:
            name: free5gc
            url: mongodb://mongodb:27017
  nrf:
    cfgFiles:
      nrfcfg.conf:
        configuration:
          MongoDBName: free5gc
          MongoDBUrl: mongodb://mongodb:27017
  simapp:
    cfgFiles:
      simapp.yaml:
        configuration:
          provision-network-slice: true
          subscribers:
          - ueId-start: 2089300007487
            ueId-end: 2089300007487
            plmnId: 20893
            opc: "981d464c7c52eb6e5036234984ad0bcf"
            op: ""
            key: "5122250214c33e723a5dd523fc145fc0"
            sequenceNumber: "16f3b3f70fc2"
          device-groups:
          - name:  "5g-gnbsim-user"
            imsis:
              - "2089300007487"
              - "2089300007488"
            ip-domain-name: "pool1"
            ip-domain-expanded:
              dnn: internet
              dns-primary: "8.8.8.8"
              mtu: 1460
              ue-ip-pool: "172.250.0.0/16"
            site-info: "riab"
          network-slices:
          - name: "default"
            slice-id:
              sd: "010203"
              sst: 1
            site-device-group:
            - "5g-gnbsim-user"
            applications-information:
            - app-name: "default-app"
              end-port: 40000
              endpoint: "1.1.1.1/32"
              protocol: 17
              start-port: 40000
            deny-applications:
            - "iot-app-deny"
            permit-applications:
            - "iot-app1-permit"
            - "iot-app2-permit"
            qos:
              downlink: 20000000
              traffic-class: "platinum"
              uplink: 4000000
            site-info:
              gNodeBs:
              - name: "riab-gnb1"
                tac: 1
              plmn:
                mcc: "208"
                mnc: "93"
              site-name: "riab"
              upf:
                upf-name: "upf"
                upf-port: 8805
# for the development, we can use the custom images
# For ONOS-RIC
# onos-topo:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-topo
#     tag: latest
#   logging:
#     loggers:
#       root:
#         level: info
# onos-uenib:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-uenib
#     tag: latest
#   logging:
#     loggers:
#       root:
#         level: info
# onos-config:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-config
#     tag: latest
#   logging:
#     loggers:
#       root:
#         level: info
onos-e2t:
  service:
    external:
      enabled: true
    e2:
     nodePort: 36401
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-e2t
#     tag: latest
#   logging:
#     loggers:
#       root:
#         level: info
# onos-cli:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-cli
#     tag: latest
#   logging:
#     loggers:
#       root:
#         level: info
# ran-simulator:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/ran-simulator
#     tag: latest
#   pci:
#     modelName: "model"
#     metricName: "metrics"
#   logging:
#     loggers:
#       root:
#         level: info
# onos-kpimon:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-kpimon
#     tag: latest
#   logging:
#     loggers:
#       root:
#         level: info
# onos-pci:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-pci
#     tag: latest
#   logging:
#     loggers:
#       root:
#         level: info
# onos-mlb:
#   image:
#     pullPolicy: IfNotPresent
#     repository: onosproject/onos-mlb
#     tag: latest
#   logging:
#     loggers:
#       root:
#         level: info
#   config:
#     mlb:
#       e2tEndpoint: "onos-e2t:5150"
#       thresholds:
#         overload: 100
#         target: 0
#       config_json:
#         controller:
#           interval: 10
# onos-mho:
#  image:
#    pullPolicy: IfNotPresent
#    repository: onosproject/onos-mho
#    tag: latest
#  logging:
#    loggers:
#      root:
#        level: info
#  config:
#    mho:
#      e2tEndpoint: "onos-e2t:5150"
#      config_json:
#      reportingPeriod: 1000
#      periodic: true
#      uponRcvMeasReport: true
#      uponChangeRrcStatus: true
#      A3OffsetRange: 0
#      HysteresisRange: 0
#      CellIndividualOffset: 0
#      FrequencyOffset: 0
#      TimeToTrigger: 0
# onos-rsm:
#   image:
#     repository: onosproject/onos-rsm
#     tag: latest
#     pullPolicy: IfNotPresent
# onos-rsm-5g:
#   image:
#     repository: onosproject/onos-rsm-5g
#     tag: latest
#     pullPolicy: IfNotPresent
# rimedo-ts:
#   image:
#     repository: onosproject/rimedo-ts
#     tag: latest
#     pullPolicy: IfNotPresent
# fb-ah-xapp:
#   image:
#     repository: onosproject/fb-ah-xapp
#     tag: 0.0.4
#     pullPolicy: IfNotPresent
# fb-kpimon-xapp:
#   image:
#     repository: onosproject/fb-kpimon-xapp
#     tag: 0.0.2
#     pullPolicy: IfNotPresent
# fb-ah-gui:
#   image:
#     repository: onosproject/fb-ah-gui
#     tag: 0.0.2
#     pullPolicy: IfNotPresent
# ah-eson-test-server:
#   image:
#     repository: onosproject/ah-eson-test-server
#     tag: 0.0.2
#     pullPolicy: IfNotPresent


# For OMEC & OAI
images:
  pullPolicy: IfNotPresent
  tags:
# For OMEC - Those images are stable image for RiaB
# latest Aether helm chart commit ID: 3d1e936e87b4ddae784a33f036f87899e9d00b95
#    init: docker.io/omecproject/pod-init:1.0.0
#    depCheck: quay.io/stackanetes/kubernetes-entrypoint:v0.3.1
    hssdb: docker.io/onosproject/riab-hssdb:master-9de5dba
    hss: docker.io/onosproject/riab-hss:master-9de5dba
    mme: docker.io/onosproject/riab-nucleus-mme:master-9e2bf16
    spgwc: docker.io/onosproject/riab-spgw:master-d8b0987
    pcrf: docker.io/onosproject/riab-pcrf:pcrf-b29af70
    pcrfdb: docker.io/onosproject/riab-pcrfdb:pcrf-b29af70
    bess: docker.io/onosproject/riab-bess-upf:master-635b4d4
    pfcpiface: docker.io/onosproject/riab-pfcpiface:master-635b4d4
# For OAI
#    oaicucp: docker.io/onosproject/oai-enb-cu:latest
#    oaidu: docker.io/onosproject/oai-enb-du:latest
#    oaiue: docker.io/onosproject/oai-ue:latest

# For SD-RAN Umbrella chart:
# ONOS-KPIMON xAPP and ONOS-UENIB are imported in the RiaB by default
# ONOS-PCI xApp is imported in the RiaB when using OPT=ransim and OPT=mlb
# ONOS-MLB xApp is imported in the RiaB when using OPT=mlb
import:
  onos-uenib:
    enabled: true
  onos-kpimon:
    enabled: true
  onos-pci:
    enabled: false
  onos-mlb:
    enabled: false
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
# fb-ah-xapp, fb-ah-gui, fb-kpimon-xapp and ah-eson-test-server are automatically imported when pushing fbc-pci option
#   fb-ah-xapp:
#     enabled: false
#   fb-ah-gui:
#     enabled: false
#   ah-eson-test-server:
#     enabled: false
#   fb-kpimon-xapp:
#     enabled: false

```

&nbsp;

# Appendix B. cu.conf
```ini
Active_eNBs = ( "eNB-CU-Eurecom-LTEBox");
# Asn1_verbosity, choice in: none, info, annoying
#Asn1_verbosity = "none";
Asn1_verbosity = "annoying";





eNBs = (
  {
    ////////// Identification parameters:
    eNB_ID    = 3584;

#    RIC : {
#       remote_ipv4_addr = "10.0.2.10";
#       remote_port = 36422;
#       enabled = "yes";
#    };
#
    RIC : {
       remote_ipv4_addr = "192.168.1.108";
       remote_port = 36401;
       enabled = "yes";
    };

    cell_type = "CELL_MACRO_ENB";

    eNB_name  = "eNB-CU-Eurecom-LTEBox";

    // Tracking area code, 0x0000 and 0xfffe are reserved values
    tracking_area_code = 1;
    plmn_list = ( { mcc = 315; mnc = 010; mnc_length = 3; } )

    nr_cellid = 12345678L

    tr_s_preference  = "f1"

    local_s_if_name  = "enx00e04b6b02f6";
    remote_s_address = "192.168.1.109";
    local_s_address  = "192.168.1.107";
    local_s_portc    = 501;
    remote_s_portc   = 500;
    local_s_portd    = 601;
    remote_s_portd   = 600;

    ////////// Physical parameters:

    component_carriers = (
      {
        node_function                           = "3GPP_eNodeB";
        node_timing                             = "synch_to_ext_device";
        node_synch_ref                          = 0;
        frame_type                              = "FDD";
        tdd_config                              = 3;
        tdd_config_s                            = 0;
        prefix_type                             = "NORMAL";
        eutra_band                              = 7;
        downlink_frequency                      = 2680000000L;
        uplink_frequency_offset                 = -120000000;
        Nid_cell                                = 0;
        N_RB_DL                                 = 25;
        pbch_repetition                         = "FALSE";
        prach_root                              = 0;
        prach_config_index                      = 0;
        prach_high_speed                        = "DISABLE";
        prach_zero_correlation                  = 1;
        prach_freq_offset                       = 2;
        pucch_delta_shift                       = 1;
        pucch_nRB_CQI                           = 0;
        pucch_nCS_AN                            = 0;
        pucch_n1_AN                             = 0;
        pdsch_referenceSignalPower              = -25;
        pdsch_p_b                               = 0;
        pusch_n_SB                              = 1;
        pusch_enable64QAM                       = "DISABLE";
        pusch_hoppingMode                       = "interSubFrame";
        pusch_hoppingOffset                     = 0;
        pusch_groupHoppingEnable                = "ENABLE";
        pusch_groupAssignment                   = 0;
        pusch_sequenceHoppingEnabled            = "DISABLE";
        pusch_nDMRS1                            = 1;
        phich_duration                          = "NORMAL";
        phich_resource                          = "ONESIXTH";
        srs_enable                              = "DISABLE";
        /*
        srs_BandwidthConfig                     =;
        srs_SubframeConfig                      =;
        srs_ackNackST                           =;
        srs_MaxUpPts                            =;
        */

        pusch_p0_Nominal                        = -96;
        pusch_alpha                             = "AL1";
        pucch_p0_Nominal                        = -104;
        msg3_delta_Preamble                     = 6;
        pucch_deltaF_Format1                    = "deltaF2";
        pucch_deltaF_Format1b                   = "deltaF3";
        pucch_deltaF_Format2                    = "deltaF0";
        pucch_deltaF_Format2a                   = "deltaF0";
        pucch_deltaF_Format2b                   = "deltaF0";

        rach_numberOfRA_Preambles               = 64;
        rach_preamblesGroupAConfig              = "DISABLE";
        /*
        rach_sizeOfRA_PreamblesGroupA           = ;
        rach_messageSizeGroupA                  = ;
        rach_messagePowerOffsetGroupB           = ;
        */
        rach_powerRampingStep                   = 4;
        rach_preambleInitialReceivedTargetPower = -108;
        rach_preambleTransMax                   = 10;
        rach_raResponseWindowSize               = 10;
        rach_macContentionResolutionTimer       = 48;
        rach_maxHARQ_Msg3Tx                     = 4;

        pcch_default_PagingCycle                = 128;
        pcch_nB                                 = "oneT";
        bcch_modificationPeriodCoeff= 2;
        ue_TimersAndConstants_t300              = 1000;
        ue_TimersAndConstants_t301              = 1000;
        ue_TimersAndConstants_t310              = 1000;
        ue_TimersAndConstants_t311              = 10000;
        ue_TimersAndConstants_n310              = 20;
        ue_TimersAndConstants_n311              = 1;
        ue_TransmissionMode                     = 1;

        //Parameters for SIB18
        rxPool_sc_CP_Len                                       = "normal";
        rxPool_sc_Period                                       = "sf40";
        rxPool_data_CP_Len                                     = "normal";
        rxPool_ResourceConfig_prb_Num                          = 20;
        rxPool_ResourceConfig_prb_Start                        = 5;
        rxPool_ResourceConfig_prb_End                          = 44;
        rxPool_ResourceConfig_offsetIndicator_present          = "prSmall";
        rxPool_ResourceConfig_offsetIndicator_choice           = 0;
        rxPool_ResourceConfig_subframeBitmap_present           = "prBs40";
        rxPool_ResourceConfig_subframeBitmap_choice_bs_buf              = "00000000000000000000";
        rxPool_ResourceConfig_subframeBitmap_choice_bs_size             = 5;
        rxPool_ResourceConfig_subframeBitmap_choice_bs_bits_unused      = 0;
        /*
        rxPool_dataHoppingConfig_hoppingParameter                       = 0;
        rxPool_dataHoppingConfig_numSubbands                            = "ns1";
        rxPool_dataHoppingConfig_rbOffset                               = 0;
        rxPool_commTxResourceUC-ReqAllowed                              = "TRUE";
        */

        // Parameters for SIB19
        discRxPool_cp_Len                                               = "normal"
        discRxPool_discPeriod                                           = "rf32"
        discRxPool_numRetx                                              = 1;
        discRxPool_numRepetition                                        = 2;
        discRxPool_ResourceConfig_prb_Num                               = 5;
        discRxPool_ResourceConfig_prb_Start                             = 3;
        discRxPool_ResourceConfig_prb_End                               = 21;
        discRxPool_ResourceConfig_offsetIndicator_present               = "prSmall";
        discRxPool_ResourceConfig_offsetIndicator_choice                = 0;
        discRxPool_ResourceConfig_subframeBitmap_present                = "prBs40";
        discRxPool_ResourceConfig_subframeBitmap_choice_bs_buf          = "f0ffffffff";
        discRxPool_ResourceConfig_subframeBitmap_choice_bs_size         = 5;
        discRxPool_ResourceConfig_subframeBitmap_choice_bs_bits_unused  = 0;
      }
    );


    srb1_parameters :
    {
      # timer_poll_retransmit = (ms) [5, 10, 15, 20,... 250, 300, 350, ... 500]
      timer_poll_retransmit    = 80;

      # timer_reordering = (ms) [0,5, ... 100, 110, 120, ... ,200]
      timer_reordering         = 35;

      # timer_reordering = (ms) [0,5, ... 250, 300, 350, ... ,500]
      timer_status_prohibit    = 0;

      # poll_pdu = [4, 8, 16, 32 , 64, 128, 256, infinity(>10000)]
      poll_pdu                 =  4;

      # poll_byte = (kB) [25,50,75,100,125,250,375,500,750,1000,1250,1500,2000,3000,infinity(>10000)]
      poll_byte                =  99999;

      # max_retx_threshold = [1, 2, 3, 4 , 6, 8, 16, 32]
      max_retx_threshold       =  4;
    }

    # ------- SCTP definitions
    SCTP :
    {
      # Number of streams to use in input/output
      SCTP_INSTREAMS  = 2;
      SCTP_OUTSTREAMS = 2;
    };


    ////////// MME parameters:
    mme_ip_address  = (
      {
        ipv4       = "192.168.1.108";
        ipv6       = "192:168:30::17";
        active     = "yes";
        preference = "ipv4";
      }
    );

    NETWORK_INTERFACES : {
      ENB_INTERFACE_NAME_FOR_S1_MME = "enx00e04b6b02f6";
      ENB_IPV4_ADDRESS_FOR_S1_MME   = "192.168.1.107";
      ENB_INTERFACE_NAME_FOR_S1U    = "enx00e04b6b02f6";
      ENB_IPV4_ADDRESS_FOR_S1U      = "192.168.251.100";
      ENB_PORT_FOR_S1U              = 2152; # Spec 2152
      ENB_IPV4_ADDRESS_FOR_X2C      = "192.168.1.107";
      ENB_PORT_FOR_X2C              = 36422; # Spec 36422
    };
  }
);

log_config = {
  global_log_level            = "info";
  global_log_verbosity        = "medium";
  pdcp_log_level              = "info";
  pdcp_log_verbosity          = "medium";
  rrc_log_level               = "info";
  rrc_log_verbosity           = "medium";
  flexran_agent_log_level     = "info";
  flexran_agent_log_verbosity = "medium";
  gtp_log_level               = "info";
  gtp_log_verbosity           = "medium";
};

NETWORK_CONTROLLER : {
  FLEXRAN_ENABLED        = "no";
  FLEXRAN_INTERFACE_NAME = "lo";
  FLEXRAN_IPV4_ADDRESS   = "127.0.0.1";
  FLEXRAN_PORT           = 2210;
  FLEXRAN_CACHE          = "/mnt/oai_agent_cache";
  FLEXRAN_AWAIT_RECONF   = "no";
};
```

&nbsp;

# Appendix C. du.conf file
```ini
Active_eNBs = ( "eNB-Eurecom-DU");
# Asn1_verbosity, choice in: none, info, annoying
Asn1_verbosity = "none";

eNBs =
(
  {
    ////////// Identification parameters:
    eNB_CU_ID = 3584;
	
	RIC : {
       remote_ipv4_addr = "192.168.1.108";
       remote_port = 36401;
       enabled = "yes";
    };

    eNB_name  = "eNB-Eurecom-DU";

    // Tracking area code, 0x0000 and 0xfffe are reserved values
    tracking_area_code = 1;
    plmn_list = ( { mcc = 315; mnc = 010; mnc_length = 3; } )

    nr_cellid = 12345678L

    ////////// Physical parameters:

    component_carriers = (
      {
        node_function           = "3GPP_eNODEB";
        node_timing             = "synch_to_ext_device";
        node_synch_ref          = 0;
        frame_type              = "FDD";
        tdd_config              = 3;
        tdd_config_s            = 0;
        prefix_type             = "NORMAL";
        eutra_band              = 7;
        downlink_frequency      = 2680000000L;
        uplink_frequency_offset = -120000000;
        Nid_cell                = 0;
        N_RB_DL                 = 25;
        Nid_cell_mbsfn          = 0;
        nb_antenna_ports        = 1;
        nb_antennas_tx          = 1;
        nb_antennas_rx          = 1;
        tx_gain                 = 90;
        rx_gain                 = 125;

        pucch_deltaF_Format1    = "deltaF2";
        pucch_deltaF_Format1b   = "deltaF3";
        pucch_deltaF_Format2    = "deltaF0";
        pucch_deltaF_Format2a   = "deltaF0";
        pucch_deltaF_Format2b   = "deltaF0";
      }
    );


    # ------- SCTP definitions
    SCTP :
    {
      # Number of streams to use in input/output
      SCTP_INSTREAMS  = 2;
      SCTP_OUTSTREAMS = 2;
    };
  }
);

MACRLCs = (
  {
    num_cc           = 1;
    tr_s_preference  = "local_L1";
    tr_n_preference  = "f1";
    local_n_if_name  = "enx00e04b6b02f6";
    remote_n_address = "192.168.1.107";
    local_n_address  = "192.168.1.109";
    local_n_portc    = 500;
    remote_n_portc   = 501;
    local_n_portd    = 600;
    remote_n_portd   = 601;
    puSch10xSnr      = 210;
    puCch10xSnr      = 210;
  }
);

L1s = (
  {
    num_cc = 1;
    tr_n_preference = "local_mac";
  }
);

RUs = (
  {
    local_rf                      = "yes";
    nb_tx                         = 1;
    nb_rx                         = 1;
    att_tx                        = 10;
    att_rx                        = 10;
    bands                         = [7];
    max_pdschReferenceSignalPower = -25;
    max_rxgain                    = 125;
    eNB_instances                 = [0];
  }
);

log_config = {
  global_log_level            ="info";
  global_log_verbosity        ="medium";
  hw_log_level                ="info";
  hw_log_verbosity            ="medium";
  phy_log_level               ="info";
  phy_log_verbosity           ="full";
  mac_log_level               ="info";
  mac_log_verbosity           ="medium";
  rlc_log_level               ="info";
  rlc_log_verbosity           ="medium";
  rrc_log_level               ="info";
  rrc_log_verbosity           ="medium";
  f1ap_log_level               ="info";
  f1ap_log_verbosity           ="medium";
  flexran_agent_log_level     ="info";
  flexran_agent_log_verbosity ="medium";
};

NETWORK_CONTROLLER : {
  FLEXRAN_ENABLED        = "no";
  FLEXRAN_INTERFACE_NAME = "lo";
  FLEXRAN_IPV4_ADDRESS   = "127.0.0.1";
  FLEXRAN_PORT           = 2210;
  FLEXRAN_CACHE          = "/mnt/oai_agent_cache";
  FLEXRAN_AWAIT_RECONF   = "no";
};

THREAD_STRUCT = (
  {
    #three config for level of parallelism "PARALLEL_SINGLE_THREAD", "PARALLEL_RU_L1_SPLIT", or "PARALLEL_RU_L1_TRX_SPLIT"
    parallel_config    = "PARALLEL_SINGLE_THREAD";
    #        #two option for worker "WORKER_DISABLE" or "WORKER_ENABLE"
    worker_config      = "WORKER_ENABLE";
  }
);
```