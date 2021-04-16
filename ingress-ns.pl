#!/usr/bin/perl
use strict;
use warnings;
use Getopt::Long qw(GetOptions);

my $num_ns;
my $num_pod;
my $num_ing;
my $add;
my $del;

my $namespace = "./ns.yaml";
my $pod = "./pod-ns.yaml";
my $service = "./service-ns.yaml";
my $ingress = "./ingress-ns.yaml";

GetOptions(
    'add|a' => \$add,
    'del|d' => \$del,
    'namespace|n=i' => \$num_ns,
    'pod|p=i' => \$num_pod,
    'ingress|i=i' => \$num_ing,
) or die "Usage: $0 \n
          --add|a add option \n
          --del|d delete option \n
          --namespace|n <number of namespace> \n
          --pod|p <number of pod in namespace> \n
          --ingress|i <number of ingress in namespace>\n";

if($del) {
    print "deleting $ingress, $service, $pod, $namespace\n";
    system("kubectl delete -f $ingress; rm -rf $ingress") if (-e $ingress);
    system("kubectl delete -f $service; rm -rf $service") if (-e $service);
    system("kubectl delete -f $pod; rm -rf $pod") if (-e $pod);
    system("kubectl delete -f $namespace; rm -rf $namespace") if (-e $namespace);
    exit;
}

if ($num_ns) {
	print "creating  namespace yaml file $namespace...\n";
	for (my $ns=1; $ns <= $num_ns; $ns++) {
	my $namespace_fh;
	open($namespace_fh, '+>>', $namespace) or die "couldn't open: $!";
	print $namespace_fh <<EOF

apiVersion: v1
kind: Namespace
metadata:
  name: ns$ns
---

EOF

	}

}

if ($num_pod and $num_ns) {

	print "creating pod in namespace yaml file $pod...\n";


	for (my $ns=1; $ns <= $num_ns; $ns++) {
   		my $pod_fh;
   		open($pod_fh, '+>>', $pod) or die "couldn't open: $!";
   		print $pod_fh <<EOF

apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
  namespace: ns$ns
spec:
  replicas: $num_pod 
  selector:
    app: nginx
  template:
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - containerPort: 80

---
EOF

	}

}

if ($num_ns) {

	print "creating service yaml file $service...\n";


	for (my $ns=1; $ns <= $num_ns; $ns++) {
   		my $service_fh;
   		open($service_fh, '+>>', $service) or die "couldn't open: $!";

   		for (my $i=1; $i <= $num_ing; $i++) {
			print "svc $i ns $ns\n";

        		print $service_fh <<EOF

apiVersion: v1
kind: Service
metadata:
  labels:
    name: svc$i-ns$ns
  name: svc$i-ns$ns
  namespace: ns$ns
spec:
  ports:
    # The port that this service should serve on.
    - port: 80
  selector:
    app: nginx
  type: ClusterIP
---
EOF

   		}
	}
}

if ($num_ns) {
	
	print "creating ingress yaml file $ingress...\n";

	for (my $ns=1; $ns <= $num_ns; $ns++) {

   		print "ns $ns\n";
   		my $ing_fh;

   		open($ing_fh, '+>>', $ingress) or die "couldn't open: $!";

   		for (my $i=1; $i <= $num_ing; $i++) {
			print "ing $i svc $i ns $ns\n";

			my $ip = 10 . "." . 169 . "." . int(rand(255)) . "." . int(rand(255));

        		print $ing_fh <<EOF

apiVersion: extensions/v1beta1 
kind: Ingress
metadata:
  name: ing$i-svc$i-ns$ns 
  namespace: ns$ns
  annotations:
     ingress.kubernetes.io/allow-http: "true"
     kubernetes.io/ingress.class: f5
     'virtual-server.f5.com/ip': "$ip" 
spec:
  rules:
   - host: www.ing$i-svc$i-ns$ns.com
     http:
       paths:
       - path: /
         backend:
            serviceName: svc$i-ns$ns
            servicePort: 80
---
EOF

   		}
	}
}

if($add) {
	print "deploying $namespace, $pod, $service, $ingress in Kubernetes...\n";
	system("kubectl apply -f $namespace") if (-e $namespace);
	system("kubectl apply -f $pod") if ( -e $pod);
	system("kubectl apply -f $service") if ( -e $service);
	system("kubectl apply -f $ingress") if ( -e $ingress);
}

=begin

to test:

scale the nginx pod replicas to monitor how soon  nginx pod get populated in BIG-IP 

root@k8s-cilium-master:/home/vincent/k3s-examples/C3431966/perl# kubectl get rc -n ns9
NAME    DESIRED   CURRENT   READY   AGE
nginx   2         2         2       3h21m
root@k8s-cilium-master:/home/vincent/k3s-examples/C3431966/perl# kubectl scale rc nginx --replicas=3 -n ns9
replicationcontroller/nginx scaled
root@k8s-cilium-master:/home/vincent/k3s-examples/C3431966/perl# kubectl get po -o wide -n ns9
NAME          READY   STATUS    RESTARTS   AGE     IP            NODE                NOMINATED NODE   READINESS GATES
nginx-jxwq6   1/1     Running   0          3h22m   10.42.0.123   k8s-cilium-master   <none>           <none>
nginx-kzj7r   1/1     Running   0          3h22m   10.42.0.124   k8s-cilium-master   <none>           <none>
nginx-s9kpv   1/1     Running   0          19s     10.42.0.137   k8s-cilium-master   <none>           <none>


root@k8s-cilium-master:/home/vincent/k3s-examples/C3431966/perl# kubectl scale rc nginx --replicas=0 -n ns9
replicationcontroller/nginx scaled

root@k8s-cilium-master:/home/vincent/k3s-examples/C3431966/perl# kubectl get po -o wide -n ns9
NAME          READY   STATUS        RESTARTS   AGE     IP            NODE                NOMINATED NODE   READINESS GATES
nginx-jxwq6   0/1     Terminating   0          3h25m   10.42.0.123   k8s-cilium-master   <none>           <none>
nginx-kzj7r   0/1     Terminating   0          3h25m   10.42.0.124   k8s-cilium-master   <none>           <none>
nginx-s9kpv   0/1     Terminating   0          3m3s    10.42.0.137   k8s-cilium-master   <none>           <none>

root@k8s-cilium-master:/home/vincent/k3s-examples/C3431966/perl# kubectl scale rc nginx --replicas=4 -n ns9
replicationcontroller/nginx scaled


root@k8s-cilium-master:/home/vincent/k3s-examples/C3431966/perl# kubectl get po -o wide -n ns9
NAME          READY   STATUS              RESTARTS   AGE   IP       NODE                NOMINATED NODE   READINESS GATES
nginx-q7n6p   0/1     ContainerCreating   0          3s    <none>   k8s-cilium-master   <none>           <none>
nginx-fczdw   0/1     ContainerCreating   0          3s    <none>   k8s-cilium-master   <none>           <none>
nginx-q486f   0/1     ContainerCreating   0          3s    <none>   k8s-cilium-master   <none>           <none>
nginx-hm7x5   0/1     ContainerCreating   0          3s    <none>   k8s-cilium-master   <none>           <none>

=end

=cut
