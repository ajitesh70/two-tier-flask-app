pipeline {
    agent any

    environment {
        AWS_REGION = "ap-south-1"
        ECR_REPO   = "883391054308.dkr.ecr.ap-south-1.amazonaws.com/two-tier-flask-app"
        CLUSTER    = "devops-eks-demo"
        DEPLOYMENT = "two-tier-app"
    }

    stages {

        stage('Checkout Code') {
            steps {
                git branch: 'master', url: 'https://github.com/ajitesh70/two-tier-flask-app.git'
            }
        }

        stage('Login to ECR') {
            steps {
                sh '''
                aws ecr get-login-password --region $AWS_REGION \
                | docker login --username AWS --password-stdin $ECR_REPO
                '''
            }
        }

        stage('Build Docker Image') {
            steps {
                sh '''
                docker build -t two-tier-flask-app .
                '''
            }
        }

        stage('Tag & Push Image') {
            steps {
                sh '''
                IMAGE_TAG=${BUILD_NUMBER}
                docker tag two-tier-flask-app:latest $ECR_REPO:$IMAGE_TAG
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
                two-tier-app=$ECR_REPO:$IMAGE_TAG

                kubectl rollout status deployment/$DEPLOYMENT
                '''
            }
        }
    }
}
