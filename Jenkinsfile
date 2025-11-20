pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        AWS_ACCOUNT = "883391054308"
        REPO_NAME = "two-tier-flask-app"
        ECR_REPO = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${REPO_NAME}"
        CLUSTER = "abhi-eks-eC8jy4sj"   // FIXED HERE
        DEPLOYMENT = "two-tier-app"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/ajitesh70/two-tier-flask-app.git'
            }
        }

        stage('Build & Push Image to ECR') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh '''
                    echo "Logging in to ECR..."
                    aws ecr get-login-password --region $AWS_REGION | \
                    docker login --username AWS --password-stdin $ECR_REPO

                    echo "Building Docker Image..."
                    docker build -t $REPO_NAME .

                    IMAGE_TAG=$BUILD_NUMBER

                    echo "Tagging image..."
                    docker tag $REPO_NAME:latest $ECR_REPO:$IMAGE_TAG

                    echo "Pushing image to ECR..."
                    docker push $ECR_REPO:$IMAGE_TAG

                    echo $IMAGE_TAG > image.txt
                    '''
                }
            }
        }

        stage('Deploy to EKS') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh '''
                    echo "Updating kubeconfig..."
                    aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER

                    IMAGE_TAG=$(cat image.txt)

                    echo "Updating deployment image..."
                    kubectl set image deployment/$DEPLOYMENT \
                        two-tier-app=$ECR_REPO:$IMAGE_TAG

                    echo "Waiting for rollout..."
                    kubectl rollout status deployment/$DEPLOYMENT
                    '''
                }
            }
        }
    }
}
