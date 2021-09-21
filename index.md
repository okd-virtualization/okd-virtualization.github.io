# Goals
Provide an integrated solution for classical virtualization users based on OKD, HCO, and KubeVirt, including a graphical user interface and deployed using bare metal suited method.

# Projects

* OKD - as the platform
* KubeVirt - as the virtualization plugin
* HyperConverged Cluster Operator (HCO) - for supporting tools
* Rook? (Or whatever the upstream operator is called) for feature rich data storage
* Medik8s and NHC for high-availability
* Konveyor for migration from other platforms

# Deployment

* UPI first
* Assisted Installer? for easy provisioning of OKD on bare-metal nodes

# Mailing List & Slack

OKD Workgroup Google Group: <https://groups.google.com/forum/#!forum/okd-wg>

Slack Channel: <https://kubernetes.slack.com/messages/openshift-dev>

# Announcements


# TODO

* some social activity like a blog post and more upstream documentation

* just as a general comment (I don't have "real" data), I want to add that on CI side we are more flaky on OKD than on OCP: nothing so serious, but we see more false positives on OKD lanes than on OCP ones

# SIG Membership

 * [Fabian Deutsch](https://github.com/fabiand) (Red Hat)
 * [Sandro Bonazzola](https://github.com/sandrobonazzola) (Red Hat)
 * [Simone Tiraboschi](https://github.com/tiraboschi)
 * [Michal Skrivanek](https://github.com/michalskrivanek)


# Information on getting Started within the SIG

Resources:

OKD Workgroup recordings: <https://www.youtube.com/playlist?list=PLaR6Rq6Z4Iqc3WjZB-rUTPru8RKyOCnBo>

OKD Workgroup meeting proposed agenda and previous meetings notes: <https://hackmd.io/YJBn04R5TDi5Sm9XbOGwZA>

Automation in place:

HCO main branch gets tested against OKD 4.9: <https://github.com/openshift/release/blob/master/ci-operator/config/kubevirt/hyperconverged-cluster-operator/kubevirt-hyperconverged-cluster-operator-main__okd.yaml>

HCO precondition job: <https://prow.ci.openshift.org/job-history/gs/origin-ci-test/pr-logs/directory/pull-ci-k[…]onverged-cluster-operator-main-okd-hco-e2e-image-index-gcp>

KubeVirt is uploaded to operatorhub and on community-operators: <https://github.com/redhat-openshift-ecosystem/community-operators-prod/tree/main/operators/community-kubevirt-hyperconverged>

