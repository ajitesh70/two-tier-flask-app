pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        AWS_ACCOUNT = "883391054308"
        REPO_NAME = "two-tier-flask-app"
        ECR_REGISTRY = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com"
        ECR_REPO = "${ECR_REGISTRY}/${REPO_NAME}"
        CLUSTER = "devops-eks-demo"
        DEPLOYMENT = "two-tier-app"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/ajitesh70/two-tier-flask-app.git'
            }
        }

        stage('AWS Credentials Setup') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    echo "AWS Credentials configured"
                }
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION | \
                docker login --username AWS --password-stdin $ECR_REGISTRY
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t $REPO_NAME .
                '''
            }
        }

        stage('Tag & Push Image') {
            steps {
                sh '''
                IMAGE_TAG=${BUILD_NUMBER}
                docker tag $REPO_NAME:latest $ECR_REPO:$IMAGE_TAG
                docker push $ECR_REPO:$IMAGE_TAG

                echo $IMAGE_TAG > image.txt
                '''
            }
        }

        stage('Deploy to EKS') {
            steps {
                sh '''
                aws eks update-kubeconfig --region $AWS_REGION --name $CLUSTER

                IMAGE_TAG=$(cat image.txt)

                kubectl set image deployment/$DEPLOYMENT \
                two-tier-app=$ECR_REPO:$IMAGE_TAG --record

                kubectl rollout status deployment/$DEPLOYMENT
                '''
            }
        }
    }
}
