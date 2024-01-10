
https://www.stacksimplify.com/aws-eks/aws-fargate/learn-to-run-kubernetes-workloads-on-aws-eks-and-aws-fargate-serverless-part-2/

https://aws.amazon.com/blogs/aws/amazon-eks-on-aws-fargate-now-generally-available/---------json link to create faraget-pod-instance

First, I create the file below and save it as demo-kube-system-profile.json.

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

create a profile using aws eks create-fargate-profile --cli-input-json file://demo-kube-system-profile.json
or you can create a profile manually with pod selectors
kubectl delete corednspods -n kube-system
kubectl logs spring-boot-postgres-sample-76c467bc9-w29wg -n fargate
