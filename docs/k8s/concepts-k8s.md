# Kubernetes concepts

- Kubernetes is a container management system

- It runs and manages containerized applications on a cluster

--

- What does that really mean?

---

## What can we do with Kubernetes?

- Let's imagine that we have a 3-tier e-commerce app:

  - web frontend

  - API backend

  - database (that we will keep out of Kubernetes for now)

- We have built images for our frontend and backend components

  (e.g. with Dockerfiles and `docker build`)

- We are running them successfully with a local environment

  (e.g. with Docker Compose)

- Let's see how we would deploy our app on Kubernetes!

---


## Basic things we can ask Kubernetes to do

--

- Start 5 containers using image `atseashop/api:v1.3`

--

- Place an internal load balancer in front of these containers

--

- Start 10 containers using image `atseashop/webfront:v1.3`

--

- Place a public load balancer in front of these containers

--

- It's Black Friday (or Christmas), traffic spikes, grow our cluster and add containers

--

- New release! Replace my containers with the new image `atseashop/webfront:v1.4`

--

- Keep processing requests during the upgrade; update my containers one at a time

---

## Other things that Kubernetes can do for us

- Autoscaling

  (straightforward on CPU; more complex on other metrics)

- Resource management and scheduling

  (reserve CPU/RAM for containers; placement constraints)

- Advanced rollout patterns

  (blue/green deployment, canary deployment)

---

## More things that Kubernetes can do for us

- Batch jobs

  (one-off; parallel; also cron-style periodic execution)

- Fine-grained access control

  (defining *what* can be done by *whom* on *which* resources)

- Stateful services

  (databases, message queues, etc.)

- Automating complex tasks with *operators*

  (e.g. database replication, failover, etc.)

---


## Interacting with Kubernetes

- We will interact with our Kubernetes cluster through the Kubernetes API

- The Kubernetes API is (mostly) RESTful

- It allows us to create, read, update, delete *resources*

- A few common resource types are:

  - node (a machine — physical or virtual — in our cluster)

  - pod (group of containers running together on a node)

  - service (stable network endpoint to connect to one or multiple containers)


## Scaling

- How would we scale the pod shown on the previous slide?

- **Do** create additional pods

  - each pod can be on a different node

  - each pod will have its own IP address

- **Do not** add more NGINX containers in the pod

  - all the NGINX containers would be on the same node

  - they would all have the same IP address
    <br/>(resulting in `Address alreading in use` errors)

---

## Together or separate

- Should we put e.g. a web application server and a cache together?
  <br/>
  ("cache" being something like e.g. Memcached or Redis)

- Putting them **in the same pod** means:

  - they have to be scaled together

  - they can communicate very efficiently over `localhost`

- Putting them **in different pods** means:

  - they can be scaled separately

  - they must communicate over remote IP addresses
    <br/>(incurring more latency, lower performance)

- Both scenarios can make sense, depending on our goals


???

:EN:- Kubernetes concepts
:FR:- Kubernetes en théorie
