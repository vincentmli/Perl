#!/usr/bin/perl
use strict;
use warnings;

my $namespace = "./ns.yaml";

print "creating  namespace...\n";
for (my $ns=1; $ns < 15; $ns++) {
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

system("kubectl apply -f $namespace");



print "creating pod in namespace...\n";

my $pod = "./pod-ns.yaml";

for (my $ns=1; $ns < 15; $ns++) {
   my $pod_fh;
   open($pod_fh, '+>>', $pod) or die "couldn't open: $!";
   print $pod_fh <<EOF

apiVersion: v1
kind: ReplicationController
metadata:
  name: nginx
  namespace: ns$ns
spec:
  replicas: 2 
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

system("kubectl apply -f $pod");


print "creating service..\n";

my $service = "./service-ns.yaml";

for (my $ns=1; $ns < 15; $ns++) {
   my $service_fh;
   open($service_fh, '+>>', $service) or die "couldn't open: $!";

   for (my $i=1; $i < 10; $i++) {
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

system("kubectl apply -f $service");

	
   print "creating ingress...\n";

my $ingress = "./ingress-ns.yaml";

for (my $ns=1; $ns < 15; $ns++) {

   print "ns $ns\n";
   my $ing_fh;

   open($ing_fh, '+>>', $ingress) or die "couldn't open: $!";

   for (my $i=1; $i < 10; $i++) {
	print "ing $i svc $i ns $ns\n";

        print $ing_fh <<EOF

apiVersion: extensions/v1beta1 
kind: Ingress
metadata:
  name: ing$i-svc$i-ns$ns 
  namespace: ns$ns
  annotations:
     ingress.kubernetes.io/allow-http: "true"
     kubernetes.io/ingress.class: f5
     'virtual-server.f5.com/ip': '10.169.72.$ns$i'
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

system("kubectl apply -f $ingress");

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
