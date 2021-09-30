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

For the OKD nodes you’ll need Fedora CoreOS. You can get it from [Get Fedora!](https://getfedora.org/en/coreos?stream=stable) website, choose the Bare Metal ISO.

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

Despite OKD current stable-4 branch is delivering OKD 4.7 we recommend to use ODK 4.8.
You can download the installer from <https://amd64.origin.releases.ci.openshift.org/#4.8.0-0.okd>

In order to get the 4.8.0 installer you’ll need the released openshift client.
You can get it from <https://github.com/openshift/okd/releases> ; look for openshift-client-linux archive.

Extract the openshift-client-linux archive and you’ll have the `oc` command.

Now you can follow instructions on <https://amd64.origin.releases.ci.openshift.org/#4.8.0-0.okd> , selecting the latest build which passed the update test.
It’s safe to ignore failures on VSphere.
The command to execute looks like: `oc adm release extract --tools ...`.
It will download the openshift-client-linux and openshift-install-linux archives for you.

At this point you should have all OKD nodes already installed with Fedora CoreOS and the bastion with all the needed services. Check that all nodes and the bastion have the correct ip addresses and fqdn and that they are resolvable via DNS.

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

* master nodes are failing the first boot with access denied to `[::1]:53` <https://github.com/openshift/okd/issues/897>

While the master node is booting edit the grub config adding to kernel command line `console=null`.

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

TBD: rook.io deployment
