# Hardware Installation

## Preliminaries
Prepare two NUC machines and each has Ubuntu 18.04 server.
One of the NUC machines will have Aether-in-a-Box and the other will have OAI connected with the USRP B210 device.
**Those machines should be connected into the same subnet (via a switch or direct connection).**

*NOTE: In the below sections, AiaB machine will have 10.0.0.213 IP address, while OAI machine will have 10.0.0.214 machine for the eno1 interface which is to communicate with each other.*

## Install Aether-in-a-Box (AiaB)
The NUC machine for AiaB should have Ubuntu 18.04 server first. Then, follow below subsections.

### Get AiaB source code
To get the source code, please see: https://gerrit.opencord.org/admin/repos/aether-in-a-box.
Since Aether-in-a-Box repository is a member-only repository, a user should log in gerrit and then check the git clone command on that web site.

### Change `aether-in-a-box.yaml` file
After downloading the source code, go to the aether-in-a-box-values.yaml file and change the file as below (we can copy and paste):
```yaml
# Copyright 2019-present Open Networking Foundation
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
                tac: 1001
            priority: 5
            selected-access-profile:
              - access-all
            selected-apn-profile: "apn-internet-menlo"
            selected-qos-profile: "qos-profile1"
        user-plane-profiles:
          menlo:
            user-plane: "upf.omec.svc.cluster.local"
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
      ip: 10.250.0.0
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
    cfgFiles:
      config.json:
        mme:
          logging: debug
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
          sqn: 135
          imsiStart: "315010999912340"
          msisdnStart: "9999334455"
          count: 30
  # oaisim values - don't care the below section
  enb:
    mme:
      address: 127.0.0.1
    networks:
      s1u:
        interface: enb
  plmn:
    mcc: "315"
    mnc: "010"
    mnc_length: 2
  ue:
    sim:
      msin: "4567891201"
      api_key: "465b5ce8b199b49faa5f0a2ee238a6bc"
      opc: "d4416644f6154936193433dd20a0ace0"
      msisdn: "1122334456"
```

### Build AiaB
After changing the file `aether-in-a-box.yaml`, run the following commands:
```bash
$ cd /path/to/aether-in-a-box
$ sudo apt install build-essential
$ make
```

If build is failed with this kind of message `cannot find cord/aether-helm-charts/omec/omec-control-plane directory`, please run the following commands.
```bash
$ cd ~
$ mkdir cord
$ cd cord
$ # This is also a member-only repository.
$ # Should check the command to clone aether-helm-chart repository here: 
$ # https://gerrit.opencord.org/admin/repos/aether-helm-charts.
$ git clone https://gerrit.opencord.org/aether-helm-charts
$ # Then, make again
$ cd ~/aether-in-a-box
$ make
```

### Verify whether everything is up and running
After a while, AiaB Makefile completes to install K8s and deploy OMEC CP, OMEC UP, and an internal router.
Once it is done, you can check with the below command in the AiaB NUC machine.
```bash
$ kubectl get po --all-namespace
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

## Install OpenAirInterface (OAI) and USRP B210
Before we start this section, we should have the other NUC board which should have Ubuntu 18.04 server OS.
**Also, please DO NOT connect the USRP B210 device to the NUC board yet.**
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
After the USRP configuration, we should build the OAI code.
```bash
$ git clone https://github.com/onosproject/openairinterface5g
$ cd /path/to/openairinterfae5g
$ source oaienv
$ cd cmake_targets/
$ ./build_oai -I -w USRP --eNB --UE
$ ./build_oai --eNB -c -w USRP
```

*NOTE: It takes really long time.*

### Configure the secondary IP address on the OAI NUC
Before run CU-CP, the NUC machine for OAI should have a secondary IP address on the Ethernet port.
The secondary IP address should have one of the IP address in `192.168.251.0/24` subnet.
The purpose of this IP address is to communicate with the other NUC machine which AiaB is running inside.
```bash
$ sudo ip a add 192.168.251.100/24 dev eno1
```

*NOTE: The reference setup has 192.168.251.100/24 for the secondary IP address.*
*However, any IP address is available as long as it is in the `192.168.251.0/24` subnet.*

### Configure CU-CP
After that, we should copy the sample CU-CP configuration file in the HOME directory.
```bash
$ cp /path/to/openairinterface5g/ci-scripts/conf_files/cu.band7.tm1.50PRB.conf ~/cu-cp.conf
```

Then, modify below parameters in the copied file `cu-cp.conf`:
```text
tracking_area_code = 1001;
plmn_list = ( { mcc = 315; mnc = 010; mnc_length = 3; } )
…
    ////////// MME parameters:
    mme_ip_address  = (
      {
        ipv4       = "10.0.0.213"; // *Write down Aether-in-a-Box IP*
        ipv6       = "192:168:30::17"; // *Don’t care*
        active     = "yes";
        preference = "ipv4";
      }
    );

    NETWORK_INTERFACES : {
      ENB_INTERFACE_NAME_FOR_S1_MME = "eno1"; // Ethernet interface name of OAI NUC
      ENB_IPV4_ADDRESS_FOR_S1_MME   = "10.0.0.214/24"; // OAI NUC IP address
      ENB_INTERFACE_NAME_FOR_S1U    = "eno1"; // Ethernet interface name of OAI NUC
      ENB_IPV4_ADDRESS_FOR_S1U      = "192.168.251.100/24"; // Write the secondary IP address which we set above
      ENB_PORT_FOR_S1U              = 2152; # Don't touch here
      ENB_IPV4_ADDRESS_FOR_X2C      = "10.0.0.214"; // OAI NUC IP address
      ENB_PORT_FOR_X2C              = 36422; # Don't touch
    };
  }

```

### Configure DU
Likewise, we should copy the sample DU configuration file in the HOME directory.
```bash
$ cp /path/to/openairinterface5g/ci-scripts/conf_files/du.band7.tm1.50PRB.conf ~/du.conf
```

And then, we should open the copied file `du.conf` and change the blow variables:
```text
tracking_area_code = 1001;
plmn_list = ( { mcc = 315; mnc = 010; mnc_length = 3; } )
```

## Network parameter configuration
So far, we deployed AiaB on a NUC machine and installed/configured OAI on the other NUC machine.
We should then configure the network parameters (e.g., routing rules, MTU size, and packet fregmentation) on both machines, AiaB router, and UPF in order to make them work together.

### Install some network tools on both NUC machines
```bash
$ sudo apt install net-tools ethtool
```

*NOTE: Normally, those tools are already installed. If not, we can command it.*

### Configuration in AiaB NUC machine
First, we should go to the AiaB NUC machine.
We should add a single routing rule and disable TCP TX/RX checksum and Generic Receive Offloading (GRO) configuration.
```bash
$ ROUTER_IP=$(kubectl exec -it router -- ifconfig eth0 | grep inet | awk '{print $2}' | awk -F ':' '{print $2}')
$ ROUTER_IF=$(route -n | grep $ROUTER_IP  | awk '{print $NF}')
$ sudo ethtool -K $ROUTER_IF gro off rx off
$ sudo ethtool -K eno1 rx off tx on gro off gso on
$ sudo ethtool -K enb rx off tx on gro off gso on
$ sudo route add -host 192.168.251.100 gw 10.0.0.214 dev eno1
```

### Configuration in AiaB internal router
Second, we should configure network parameters in the AiaB internal router.
In order to access the AiaB internal router, go to the AiaB NUC machine and command below:
```bash
$ kubectl exec -it router -- bash
```

On the router prompt, we initially add a routing rule and MTU size.
Then, we should disable TX/RX checksum and GRO for all network interfaces in the router.
```bash
$ # Add routing rule
$ route add -host 192.168.251.5 gw 192.168.251.4 dev enb-rtr
$ route add -host 10.0.0.214 gw 192.168.251.4 dev enb-rtr

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
Next, we should go to the UPF running in the AiaB NUC machine:
```bash
$ kubectl exec -it upf-0 -n omec -- bash
```

On the UPF prompt, we should change the MTU size.
```bash
$ ip l set mtu 1550 dev access
$ ip l set mtu 1550 dev core
```

### Configuration in OAI NUC machine
Last, we should configure network configuration in the OAI NUC machine.
We should go to the the OAI NUC machine and change the network configuration such as TX/RX checksum, GRO, and routing rules.
```bash
$ sudo ethtool -K eno1 tx off rx off gro off gso off
$ sudo route del -net 192.168.251.0/24 dev eno 1 # ignore error if happened
$ sudo route add -net 192.168.250.0/24 gw 10.0.0.213 dev eno1
$ sudo route add -net 192.168.251.0/24 gw 10.0.0.213 dev eno1
$ sudo route add -net 192.168.251.0/24 gw 10.0.0.213 dev eno1
```

## Run CU-CP and DU
### Run CU-CP
On the OAI NUC machine, we should go to `/path/to/openairinterface5g/cmake_targets` and command below:
```bash
$ sudo ./lte_build_oai/build/lte-softmodem -O ~/cu-cp.conf
```

*NOTE: We should have the `cu-cp.conf` file which we copied and configured before section.*

### Run DU
After CU-CP is running, we should run below command:
```bash
$ sudo ./lte_build_oai/build/lte-softmodem -O ~/du.conf
```

## User Equipment (UE)
As of now, the current OAI with AiaB setup is running over LTE Band 7.
To communicate with this setup, we should prepare the Android smartphone which supports LTE Band 7.
We should then insert a SIM card to the smartphone, where the SIM card should have the below IMSI, Key, and OPc values:

* IMSI: `315010999912340-315010999912370`
* Key: `465b5ce8b199b49faa5f0a2ee238a6bc`
* OPc: `69d5c2eb2e2e624750541d3bbc692ba5`

If we want to use the different IMSI number, we have to change the HSS configuration.
In order to change SIM information in HSS, we first go to the AiaB NUC and open the `aether-in-a-box.yaml` file.
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

`aether-in-a-box.yaml`:
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

`cu-cp.conf`:
```text
tracking_area_code = 1001;
plmn_list = ( { mcc = 315; mnc = 010; mnc_length = 3; } ) // Change me
```

`du.conf`:
```text
tracking_area_code = 1001;
plmn_list = ( { mcc = 315; mnc = 010; mnc_length = 3; } ) // Change me
```

## Issues?
Please report any issue to SD-RAN team. All error/issue reports are really well.