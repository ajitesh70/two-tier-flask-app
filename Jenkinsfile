pipeline {
    agent any

    environment {
        AWS_REGION   = "ap-south-1"
        AWS_ACCOUNT  = "883391054308"
        REPO_NAME    = "two-tier-flask-app"
        ECR_REPO     = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"
        CLUSTER      = "my-eks"
        DEPLOYMENT   = "two-tier-app"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'master',
                    credentialsId: 'github-creds',
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

        stage('Update Kubeconfig for Jenkins') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh '''
                    echo "⚙️ Updating kubeconfig for Jenkins user..."

                    # Create Jenkins kube dir
                    mkdir -p /var/lib/jenkins/.kube
                    chmod 700 /var/lib/jenkins/.kube

                    # Update kubeconfig
                    aws eks update-kubeconfig \
                        --region $AWS_REGION \
                        --name $CLUSTER \
                        --kubeconfig /var/lib/jenkins/.kube/config

                    chmod 600 /var/lib/jenkins/.kube/config
                    '''
                }
            }
        }

        stage('Apply Kubernetes Manifests (MySQL + App + Services)') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh '''
                    echo "📦 Applying Kubernetes manifests..."

                    export KUBECONFIG=/var/lib/jenkins/.kube/config

                    kubectl apply --validate=false -f eks-manifests/mysql-configmap.yml
                    kubectl apply --validate=false -f eks-manifests/mysql-secrets.yml
                    kubectl apply --validate=false -f eks-manifests/mysql-deployment.yml
                    kubectl apply --validate=false -f eks-manifests/mysql-svc.yml

                    kubectl apply --validate=false -f eks-manifests/two-tier-app-deployment.yml
                    kubectl apply --validate=false -f eks-manifests/two-tier-app-svc.yml
                    '''
                }
            }
        }

        stage('Deploy New Image') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {

                    sh '''
                    export KUBECONFIG=/var/lib/jenkins/.kube/config
                    IMAGE_TAG=$(cat image.txt)

                    echo "🚀 Deploying new image: $IMAGE_TAG"

                    kubectl set image deployment/$DEPLOYMENT \
                        two-tier-app=$ECR_REPO:$IMAGE_TAG

                    kubectl rollout status deployment/$DEPLOYMENT
                    '''
                }
            }
        }
    }
}
