## create the docker image
https://stackoverflow.com/questions/73285601/docker-exec-usr-bin-sh-exec-format-error#:~:text=api%2Dcatalog%20%25-,Comment%3A,-This%20usually%20happens
be careful with the architecture if you run on macOS

docker buildx build --platform=linux/amd64 -t udacity-project:latest .   

## run the docker with environment variables
the environment variables are directly used in the app.py

docker run -e DB_USERNAME="admin" -e DB_PASSWORD="admin" <IMAGE_ID>

## authenticate against ECR repository
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 006712159429.dkr.ecr.us-east-1.amazonaws.com


## variables
export HELM_BITNAMI_REPO=udacity-project
export SERVICE_POSTGRESQL=coworking-postgresql

export APP_SECRET_NAME=db-credentials
export APP_CONFIG=analytic-config
export DEPLOYMENT_NAME=analytics-api
export AWS_REGION=us-east-1
export CLUSTER_NAME="udacity-project"
export BUILD_VERSION=11


## create cluster
Create the EKS Cluster manually in aWS Console
## login cluster
aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER_NAME

## install cloudwatch agent
echo $CLUSTER_NAME

ClusterName=$CLUSTER_NAME
RegionName=$AWS_REGION
FluentBitHttpPort='2020'
FluentBitReadFromHead='Off'
FluentBitReadFromTail='On'
FluentBitHttpServer='On'
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluent-bit-quickstart.yaml | sed 's/{{cluster_name}}/'${ClusterName}'/;s/{{region_name}}/'${RegionName}'/;s/{{http_server_toggle}}/"'${FluentBitHttpServer}'"/;s/{{http_server_port}}/"'${FluentBitHttpPort}'"/;s/{{read_from_head}}/"'${FluentBitReadFromHead}'"/;s/{{read_from_tail}}/"'${FluentBitReadFromTail}'"/' | kubectl apply -f -

kubectl get pods -n amazon-cloudwatch

## setup helm
echo $HELM_BITNAMI_REPO
helm repo add $HELM_BITNAMI_REPO https://charts.bitnami.com/bitnami

helm repo list

## workaround for postgresql storage
#kubectl delete pv local-storage
NODE_1_NAME=` kubectl get nodes -o jsonpath='{.items[*].metadata.name}'  | tr " " "\n" | head -n 1`
echo $NODE_1_NAME
sed "s|<NODE_INSTANCE_NAME>|$NODE_1_NAME|" local_storage_class.yml | kubectl apply -f -

# install postgresql as a service 
helm install $SERVICE_POSTGRESQL $HELM_BITNAMI_REPO/postgresql --set global.storageClass=local-storage
helm list
# helm uninstall $SERVICE_POSTGRESQL

##check installation
kubectl get svc
kubectl get pods
kubectl get pv
kubectl get pvc
# kubectl get events

## connect to postgres
kubectl port-forward --namespace default svc/$SERVICE_POSTGRESQL 5432:5432

# open in another terminal 
export POSTGRES_PASSWORD=$(kubectl get secret --namespace default coworking-postgresql -o jsonpath="{.data.postgres-password}" | base64 -d)
echo $POSTGRES_PASSWORD
PGPASSWORD="$POSTGRES_PASSWORD" psql --host 127.0.0.1 -U postgres -d postgres -p 5432

## populate data to postgres
kubectl port-forward --namespace default svc/$SERVICE_POSTGRESQL 5432:5432 &
PGPASSWORD="$POSTGRES_PASSWORD" psql -h 127.0.0.1 -U postgres -d postgres -p 5432 < ./db/1_create_tables.sql

prompt in POSTGRES password
echo -n $POSTGRES_PASSWORD | base64

change the password in secret.yml as base64

kubectl port-forward --namespace default svc/$SERVICE_POSTGRESQL 5432:5432 &
PGPASSWORD="$POSTGRES_PASSWORD" psql -h 127.0.0.1 -U postgres -d postgres -p 5432 < ./db/2_seed_users.sql

kubectl port-forward --namespace default svc/$SERVICE_POSTGRESQL 5432:5432 &
PGPASSWORD="$POSTGRES_PASSWORD" psql -h 127.0.0.1 -U postgres -d postgres -p 5432 < ./db/3_seed_tokens.sql




## deployment EKS app from dockerimage ECR


kubectl apply -f secret.yml
kubectl apply -f configmap.yml
kubectl apply -f analytics-kubernetes.yml 
