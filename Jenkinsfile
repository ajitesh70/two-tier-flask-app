pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        AWS_ACCOUNT = "883391054308"
        REPO_NAME = "two-tier-flask-app"
        ECR_REPO = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"
        CLUSTER = "my-eks"     // FIXED CLUSTER NAME
        DEPLOYMENT = "two-tier-app"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'master', 
                    url: 'https://github.com/ajitesh70/two-tier-flask-app.git'
            }
        }

        stage('Build & Push Docker Image') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh '''
                    echo "🔍 Checking ECR repo..."
                    aws ecr describe-repositories --repository-names $REPO_NAME || \
                    aws ecr create-repository --repository-name $REPO_NAME

                    echo "🔐 Logging in to ECR..."
                    aws ecr get-login-password --region $AWS_REGION | \
                    docker login --username AWS --password-stdin $ECR_REPO

                    echo "🐳 Building Docker Image..."
                    docker build -t $REPO_NAME .

                    IMAGE_TAG=$BUILD_NUMBER
                    docker tag $REPO_NAME:latest $ECR_REPO:$IMAGE_TAG
                    docker push $ECR_REPO:$IMAGE_TAG

                    echo $IMAGE_TAG > image.txt
                    '''
                }
            }
        }

        stage('Update Kubeconfig') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh '''
                    echo "⚙️ Updating kubeconfig..."
                    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER
                    '''
                }
            }
        }

        stage('Apply K8s Manifests') {
            steps {
                sh '''
                echo "📦 Applying Kubernetes YAML files..."

                kubectl apply -f eks-manifests/mysql-configmap.yml
                kubectl apply -f eks-manifests/mysql-secrets.yml
                kubectl apply -f eks-manifests/mysql-deployment.yml
                kubectl apply -f eks-manifests/mysql-svc.yml

                kubectl apply -f eks-manifests/two-tier-app-deployment.yml
                kubectl apply -f eks-manifests/two-tier-app-svc.yml
                '''
            }
        }

        stage('Deploy New Image') {
            steps {
                sh '''
                IMAGE_TAG=$(cat image.txt)

                kubectl set image deployment/two-tier-app \
                two-tier-app=$ECR_REPO:$IMAGE_TAG

                echo "⏳ Waiting for rollout..."
                kubectl rollout status deployment/two-tier-app
                '''
            }
        }
    }
}
