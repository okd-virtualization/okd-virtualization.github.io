# OKD Virtualization on user provided infrastructure

## Preparing the hardware

As a first step for providing an infrastructure for OKD Virtualization, you need to prepare the hardware:
* check that [minimum hardware requirements for running OKD](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html#minimum-resource-requirements_installing-bare-metal) are satisfied;
* check that [additional hardware requirements for running OKD Virtualization](https://docs.okd.io/latest/virt/install/preparing-cluster-for-virt.html#virt-cluster-resource-requirements_preparing-cluster-for-virt) are also satisfied.


## Preparing the infrastructure

Once your hardware is ready and connected to the network you need to configure your services, your network and your DNS for allowing the OKD installer to deploy the software.
You may need to prepare in advance also a few services you'll need during the deployment.
Read carefully the [Preparing the user-provisioned infrastructure](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-infrastructure-user-infra_installing-bare-metal) section and ensure all the requirements are met.


## Provision your hosts

For the bastion / service host you can use CentOS Stream 8.
You can follow [CentOS 8 installation documentation](https://docs.centos.org/en-US/8-docs/standard-install/)
but we recommend using the latest [CentOS Stream 8 ISO](http://isoredirect.centos.org/centos/8-stream/isos/x86_64/).

For the OKD nodes you’ll need Fedora CoreOS.
In order to get the correct ISO for installing OKD you can get the link from the installer:

```bash
openshift-install coreos print-stream-json | grep iso
```

## Configure the bastion to host needed services

Configure Apache to serve on port 8080/8443 as the http/https port will be used by the haproxy service.
Apache will be needed to provide ignition configuration for OKD nodes.

```bash
dnf install -y httpd
sed -i 's/Listen 80/Listen 8080/' /etc/httpd/conf/httpd.conf
sed -i 's/Listen 443/Listen 8443/' /etc/httpd/conf.d/ssl.conf
setsebool -P httpd_read_user_content 1
systemctl enable --now httpd.service
firewall-cmd --permanent --add-port=8080/tcp
firewall-cmd --permanent --add-port=8443/tcp
firewall-cmd --reload
# Verify it’s up:
curl localhost:8080
```

Configure haproxy

```bash
dnf install haproxy -y
firewall-cmd --permanent --add-port=6443/tcp
firewall-cmd --permanent --add-port=22623/tcp
firewall-cmd --permanent --add-service=http
firewall-cmd --permanent --add-service=https
firewall-cmd --reload
setsebool -P haproxy_connect_any 1
systemctl enable --now haproxy.service
```


## Installing OKD

OKD current stable-4 branch is delivering OKD 4.9.0. If you're using an older version we recommend to update to ODK 4.9.0.

At this point you should have all OKD nodes ready to be installed with Fedora CoreOS and the bastion with all the needed services.
Check that all nodes and the bastion have the correct ip addresses and fqdn and that they are resolvable via DNS.

As we are going to use baremetal UPI installation you’ll need to create a `install-config.yaml` following the example for
[installing bare metal](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-bare-metal-config-yaml_installing-bare-metal)

Remember to [configure your proxy settings if you have a proxy](https://docs.okd.io/latest/installing/installing_bare_metal/installing-bare-metal.html#installation-configure-proxy_installing-bare-metal)


## Apply workarounds

* qemu-ga is hitting selinux denials <https://bugzilla.redhat.com/show_bug.cgi?id=1927639>

You can workaround this by adding a custom policy:
```bash
echo '(allow virt_qemu_ga_t container_var_lib_t (dir (search)))' >local_virtqemu_ga.cil
semodule -i local_virtqemu_ga.cil
```

* iptables is hitting selinux denials <https://bugzilla.redhat.com/show_bug.cgi?id=2008097>

You can workaround this by adding a custom policy:

```bash
echo '(allow iptables_t cgroup_t (dir (ioctl)))' >local_iptables.cil
semodule -i local_iptables.cil
```

* rpcbind

```bash
echo '(allow rpcbind_t unreserved_port_t (udp_socket (name_bind)))' >local_rpcbind.cil
semodule -i local_rpcbind.cil
```

* bpf

```
echo '(allow container_runtime_t init_t (bpf (prog_run)))' >local_bpf.cil
semodule -i local_bpf.cil
```

* worker nodes may fail on openvswitch

```
echo '(allow openvswitch_t init_var_run_t (capability (fsetid)))' >local_openvswitch.cil
semodule -i local_openvswitch.cil
```


## Installing HCO and KubeVirt

Once OKD console is up, connect to it.
Go to Operators -> OperatorHub
Look for `KubeVirt HyperConverged Cluster Operator` and install it.

Click on Create Hyperconverged button, all the defaults should be fine.


## Providing storage

Shared storage is not mandatory for OKD Virtualization, but without a doubt it provides many advantages over a configuration based on local storage which is considered a suboptimal configuration.

Between the advantages enabled by shared storage is worth to mention:
- Live migration of Virtual Machines
  - Founding pillar for HA
  - Enables seamless cluster upgrades without the need to shut down and restart all the VMs on each upgrade
- Centralized storage management enabling elastic scalability
- Centralized backup

### Shared storage

#### rook.io with Ceph
[//]: # (Update for community operators catalog when rook will be available there)
rook.io operator is still not available in the Community Operators catalog but it can be manually deployed.
Please notice that being not managed by the OLM, it's not going to receive any automatic update.

```bash
$ ROOK_VERSION=v1.7.8
$ git clone --single-branch --branch ${ROOK_VERSION} https://github.com/rook/rook.git
$ oc create -f rook/cluster/examples/kubernetes/ceph/crds.yaml -f rook/cluster/examples/kubernetes/ceph/common.yaml
$ oc create -f rook/cluster/examples/kubernetes/ceph/operator-openshift.yaml
$ oc create -f rook/cluster/examples/kubernetes/ceph/cluster.yaml
$ oc create -f rook/cluster/examples/kubernetes/ceph/csi/rbd/storageclass.yaml
```

`examples/kubernetes/ceph/cluster.yaml` contains typical settings for a production cluster and it requires at least three worker nodes.
Please see the [Ceph Cluster documentation on rook.io](https://rook.io/docs/rook/v1.7/ceph-cluster-crd.html) to tune the configuration according to your specific needs.

`rook/cluster/examples/kubernetes/ceph/csi/rbd/storageclass.yaml` contains typical settings for a production scenario with replica 3: your data is replicated on three different worker nodes (so it requires at least three worker nodes) and intermittent or long-lasting single node failures will not result in data unavailability or loss. It uses the CSI driver for block devices.
See the [Ceph Pool CRD topic on rook.io documentation](https://rook.io/docs/rook/v1.7/ceph-pool-crd.html) for more details on the settings.

You can check the status of your Ceph cluster with:
```bash
$ oc get CephCluster -n rook-ceph  rook-ceph -o json | jq '.status'
```

### Local storage
You can configure local storage for your virtual machines by using the OKD Virtualization hostpath provisioner feature.

When you install OKD Virtualization, the hostpath provisioner Operator is automatically installed. To use it, you must:
- Configure SELinux on your worker nodes via a Machine Config object.
- Create a HostPathProvisioner custom resource.
- Create a StorageClass object for the hostpath provisioner.

#### Configuring SELinux for the hostpath provisioner on OKD worker nodes
You can configure SELinux for your OKD Worker nodes using a [MachineConfig](./contrib/machineconfig-selinux-hpp.yaml).

#### Creating a CR for the HostPathProvisioner operator
1. Create the HostPathProvisioner custom resource file. For example:
    ```bash
    $ touch hostpathprovisioner_cr.yaml
    ```
2. Edit that file. For example:
    ```yaml
    apiVersion: hostpathprovisioner.kubevirt.io/v1beta1
    kind: HostPathProvisioner
    metadata:
      name: hostpath-provisioner
    spec:
      imagePullPolicy: IfNotPresent
      pathConfig:
        path: "/var/hpvolumes" #The path of the directory on the node
        useNamingPrefix: false #Use the name of the PVC bound to the created PV as part of the directory name.
    ```
3. Creating the CR in the `kubevirt-hyperconverged` namespace:
    ```bash
    $ oc create -n kubevirt-hyperconverged -f hostpathprovisioner_cr.yaml
    ```

#### Creating a StorageClass for the HostPathProvisioner operator
1. Create the YAML file for the storage class. For example:
    ```bash
    $ touch hppstorageclass.yaml
    ```
2. Edit that file. For example:
    ```yaml
    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: hostpath-provisioner
    provisioner: kubevirt.io/hostpath-provisioner
    reclaimPolicy: Delete
    volumeBindingMode: WaitForFirstConsumer
    ```
3. Creating the Storage Class object:
    ```bash
    $ oc create -f hppstorageclass.yaml
    ```
