## Spring Boot, PostgreSQL, JPA, Hibernate REST API Demo

Pre-requisites:
--------

- Install Git
- Install Maven
- Install Docker
- EKS Cluster

Cluster-connection and add ons:
--------
aws eks --region ap-south-1 update-kubeconfig --name dev------to connect to cluster
---
eksctl create cluster --name your-cluster-name --region your-region
----
Add the ADD-ON Amazon EBS CSI Driver
---
eksctl create fargateprofile --cluster your-cluster-name --region your-region --name kube-system --namespace kube-system
----

additional option to create fargate profile:
--------
create a profile using aws eks create-fargate-profile --cli-input-json file://example.json

example.json

{
    "fargateProfileName": "demo-kube-system",
    "clusterName": "prod",
    "podExecutionRoleArn": "arn:aws:iam::792616605913:role/fargate-pod-rule",
    "subnets": [
        "subnet-08f72819e1ed6619e",
        "subnet-02469fe2d5c15a99a",
        "subnet-0b1b6c6696f8b82b5"
    ],
    "selectors": [
        {
            "namespace": "kube-system"
        }
    ]
}

link to update kube-sytem and patch remove https://docs.aws.amazon.com/eks/latest/userguide/fargate-getting-started.html

kubectl delete corednspods -n kube-system

if you want create another profile with selector u can place in the application deployment.

configmap command to be applied in the fargate namespace


Build Maven Artifact:
---
mvn clean install -DskipTests=true

Push docker image to dockerhub
-----------
Build Docker image for Springboot Application

docker build -t  .

Docker login

docker login

Push docker image to dockerhub or ecr

docker push image

Encode USERNAME and PASSWORD of Postgres using following commands in node:
--------
Encode USERNAME and PASSWORD of Postgres using following commands:

Create the Secret using kubectl apply in node:
-------
echo -n "postgresadmin" | base64
echo -n "admin123" | base64

Create the Secret using kubectl apply:

Deploying Postgres with kubectl apply in fargate node:
-----------
kubectl apply -f postgres-secrets.yml

Creating the Role with clusteraddon permission and creating Cluster Addon by maintaining OIDC permissions
---

cluster_name=my-cluster

oidc_id=$(aws eks describe-cluster --name $cluster_name --query "cluster.identity.oidc.issuer" --output text | cut -d '/' -f 5)

echo $oidc_id

copy the above value

create aws-ebs-csi-driver-trust-policy.json file with thebelow content
Note: oidc_id=5135C01B905210EE0CE6C36ED4430268
      account id=433686923958
      region=eu-west-1

you change accordingly

{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::433686923958:oidc-provider/oidc.eks.eu-west-1.amazonaws.com/id/5135C01B905210EE0CE6C36ED4430268"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "oidc.eks.eu-west-1.amazonaws.com/id/5135C01B905210EE0CE6C36ED4430268:aud": "sts.amazonaws.com",
          "oidc.eks.eu-west-1.amazonaws.com/id/5135C01B905210EE0CE6C36ED4430268:sub": "system:serviceaccount:default:ebs-csi-controller-sa"
        }
      }
    }
  ]
}


aws iam create-role --role-name AmazonEKS_EBS_CSI_DriverRoles   --assume-role-policy-document file://"aws-ebs-csi-driver-trust-policy.json"

aws iam attach-role-policy   --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy   --role-name AmazonEKS_EBS_CSI_DriverRoles

aws eks create-addon --cluster-name eks-cluster --addon-name aws-ebs-csi-driver   --service-account-role-arn arn:aws:iam::433686923958:role/AmazonEKS_EBS_CSI_DriverRoles

Create PV and PVC for Postgres using yaml file in node:
-----
Create PV and PVC for Postgres using yaml file:

kubectl apply -f postgres-storages.yaml

The above one will create the pvc

kubectl apply -f clusteraddon.yml 

Th eabove will create the storage class

Deploying Postgres with kubectl apply in node by addon ebs-csi:
-----------

kubectl apply -f postgres-deploy.yaml
kubectl apply -f postgres-service.yaml

Create a config map with the hostname of Postgres on fargate 
-------------

kubectl create configmap hostname-config --from-literal=postgres_host=$(kubectl get svc postgres -o jsonpath="{.spec.clusterIP}")

Check secrets:
---
kubectl get secrets
kubectl get configmaps
kubectl get pv
kubectl get pvc
kubectl get deploy
kubectl get pods
kubectl get svc

Create UI for Data Base
---
echo -n 'mypwd' | base64
bXlwd2Q=

kubectl apply -f pgadmin-secret.yml

and 

kubectl apply -f pgadmin-deployment.yml

Now access the UI using public Ip:32000/browser

if its load balancer DNSNAME/BROWSER

Credentials to login UI will be 

username=will be in pgadmin-deploy.yml-env(admin@admin.com)
password=will be in mypwd(refer start step)

After logging in now add the server of postgresql db

servername=refer in kubectl get svc
username=yours username in postgresql DB
password=yours password in postgresql DB
