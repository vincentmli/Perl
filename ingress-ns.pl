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

