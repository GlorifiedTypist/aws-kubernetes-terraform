# aws-kubernetes-terraform

Emphermal kubernetes cluster in AWS, primarily suited for non-production development and/or distributed compute loads.

* Entire cluster is run on spot instances
* A new VPC is created for the cluster
* Calico as the default CNI
* Bootstrapping done via kubeadm
* Control plane is non-HA and not suitable for production or critical compute loads

Operation and documentation ongoing..


