## run the docker with environment variables
the environment variables are directly used in the app.py

docker run -e DB_USERNAME="admin" -e DB_PASSWORD="admin" <IMAGE_ID>

## authenticate against ECR repository
aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 006712159429.dkr.ecr.us-east-1.amazonaws.com