## First
``` cmd
cd secret-store-csi-driver
helm repo add secrets-store-csi-driver https://kubernetes-sigs.github.io/secrets-store-csi-driver/charts
helm repo up
helm dep up
helm install -n kube-system csi-secrets-store .
```

## Second
``` cmd
cd csi-secrets-store-provider-aws
helm repo add aws-secrets-manager https://aws.github.io/secrets-store-csi-driver-provider-aws
helm repo up
helm dep up
helm install -n kube-system csi-secrets-store-provider-aws .
```

## Patch CSI Provider Service Account with the IRSA IAM Role

````kubectl
kubectl -n kube-system patch sa  csi-secrets-store-provider-aws -p '{"metadata": {"annotations": {"eks.amazonaws.com/role-arn": "arn:aws:iam::750014327084:role/security-store-csi-role"}}}'
````

kubectl -n kube-system annotate sa  csi-secrets-store-provider-aws eks.amazonaws.com/role-arn-

