# Exposing containers

- We can connect to our pods using their IP address

- Then we need to figure out a lot of things:

  - how do we look up the IP address of the pod(s)?

  - how do we connect from outside the cluster?

  - how do we load balance traffic?

  - what if a pod fails?

- Kubernetes has a resource type named *Service*

- Services address all these questions!

---

## Services in a nutshell

- Services give us a *stable endpoint* to connect to a pod or a group of pods

- An easy way to create a service is to use `kubectl expose`

- If we have a deployment named `my-little-deploy`, we can run:

  `kubectl expose deployment my-little-deploy --port=80`

  ... and this will create a service with the same name (`my-little-deploy`)

- Services are automatically added to an internal DNS zone

  (in the example above, our code can now connect to http://my-little-deploy/)

---

## Advantages of services

- We don't need to look up the IP address of the pod(s)

  (we resolve the IP address of the service using DNS)

- There are multiple service types; some of them allow external traffic

  (e.g. `LoadBalancer` and `NodePort`)

- Services provide load balancing

  (for both internal and external traffic)

- Service addresses are independent from pods' addresses

  (when a pod fails, the service seamlessly sends traffic to its replacement)

---

## Many kinds and flavors of service

- There are different types of services:

  `ClusterIP`, `NodePort`, `LoadBalancer`, `ExternalName`

- There are also *headless services*

- Services can also have optional *external IPs*

- There is also another resource type called *Ingress*

  (specifically for HTTP services)

- Wow, that's a lot! Let's start with the basics ...

---

## `ClusterIP`

- It's the default service type

- A virtual IP address is allocated for the service

  (in an internal, private range; e.g. 10.96.0.0/12)

- This IP address is reachable only from within the cluster (nodes and pods)

- Our code can connect to the service using the original port number

- Perfect for internal communication, within the cluster

---

## `LoadBalancer`

- An external load balancer is allocated for the service

  (typically a cloud load balancer, e.g. ELB on AWS, GLB on GCE ...)

- This is available only when the underlying infrastructure provides some kind of
  "load balancer as a service"

- Each service of that type will typically cost a little bit of money

  (e.g. a few cents per hour on AWS or GCE)

- Ideally, traffic would flow directly from the load balancer to the pods

- In practice, it will often flow through a `NodePort` first

---

## `NodePort`

- A port number is allocated for the service

  (by default, in the 30000-32767 range)

- That port is made available *on all our nodes* and anybody can connect to it

  (we can connect to any node on that port to reach the service)

- Our code needs to be changed to connect to that new port number

- Under the hood: `kube-proxy` sets up a bunch of `iptables` rules on our nodes

- Sometimes, it's the only available option for external traffic

  (e.g. most clusters deployed with kubeadm or on-premises)

---

## Running containers with open ports

- Since `ping` doesn't have anything to connect to, we'll have to run something else

- We could use the `nginx` official image, but ...

  ... we wouldn't be able to tell the backends from each other!

- We are going to use `jpetazzo/httpenv`, a tiny HTTP server written in Go

- `jpetazzo/httpenv` listens on port 8888

- It serves its environment variables in JSON format

- The environment variables will include `HOSTNAME`, which will be the pod name

  (and therefore, will be different on each backend)

---

## Creating a deployment for our HTTP server

- We will create a deployment with `kubectl create deployment`

- Then we will scale it with `kubectl scale`

.exercise[

- In another window, watch the pods (to see when they are created):
  ```bash
  kubectl get pods -w
  ```

<!--
```wait NAME```
```tmux split-pane -h```
-->

- Create a deployment for this very lightweight HTTP server:
  ```bash
  kubectl create deployment httpenv --image=jpetazzo/httpenv
  ```

- Scale it to 10 replicas:
  ```bash
  kubectl scale deployment httpenv --replicas=10
  ```

]

---

## Exposing our deployment

- We'll create a default `ClusterIP` service

.exercise[

- Expose the HTTP port of our server:
  ```bash
  kubectl expose deployment httpenv --port 8888 --type=NodePort
  ```

- Look up which `NodePort` was allocated:
  ```bash
  kubectl describe service httpenv
  ```

And try to access to [http://146.59.242.188:NODE_PORT](http://146.59.242.188:NODE_PORT), or any IP of a node

]



???

:EN:- Service discovery and load balancing
:EN:- Accessing pods through services
:EN:- Service types: ClusterIP, NodePort, LoadBalancer

:FR:- Exposer un service
:FR:- Différents types de services : ClusterIP, NodePort, LoadBalancer
:FR:- Utiliser CoreDNS pour la *service discovery*
