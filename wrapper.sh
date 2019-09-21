sudo cp libs/terraform /usr/local/bin/
sudo cp libs/kubectl /usr/local/bin/
sudo cp libs/helm /usr/local/bin/

terraform init
terraform apply -var="aws_secret_key=$AWS_SECRET_ACCESS_KEY" -var="aws_access_key=$AWS_ACCESS_KEY_ID" -auto-approve
terraform output config_map_aws_auth > config_map_aws_auth.yaml


sudo apt-get update -y
sudo apt install python-pip -y
sudo pip install awscli


aws eks --region us-east-2 update-kubeconfig --name eks-test
kubectl apply -f config_map_aws_auth.yaml
kubectl apply -f helm/rbac.yaml

helm init --service-account tiller
sleep 50
helm install helm/helm-chart


