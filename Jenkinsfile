pipeline {
    agent any

    environment {
        AWS_REGION   = "ap-south-1"
        AWS_ACCOUNT  = "883391054308"
        APP_NAME     = "two-tier-flask-app"
        ECR_REPO     = "${AWS_ACCOUNT}.dkr.ecr.${AWS_REGION}.amazonaws.com/${APP_NAME}"
        CLUSTER_NAME = "abhi-eks-eC8jy4sj"   // your cluster
        DEPLOYMENT   = "two-tier-app"
    }

    stages {

        stage('Checkout App Repo') {
            steps {
                git branch: 'master', url: 'https://github.com/ajitesh70/two-tier-flask-app.git'
            }
        }

        stage('Build and Push Docker Image') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh '''
                    echo "Logging in to ECR..."
                    aws ecr get-login-password --region $AWS_REGION | \
                    docker login --username AWS --password-stdin $AWS_ACCOUNT.dkr.ecr.$AWS_REGION.amazonaws.com

                    echo "Building Docker image..."
                    docker build -t $APP_NAME .

                    IMAGE_TAG=$BUILD_NUMBER
                    docker tag $APP_NAME:latest $ECR_REPO:$IMAGE_TAG
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
                    echo "Updating kubeconfig..."
                    aws eks update-kubeconfig --name $CLUSTER_NAME --region $AWS_REGION
                    '''
                }
            }
        }

        stage('Apply K8s Manifests (MySQL + App + Services)') {
            steps {
                sh '''
                echo "Applying MySQL and App manifests..."
                kubectl apply -f eks-manifests/
                '''
            }
        }

        stage('Deploy New Image to EKS') {
            steps {
                withAWS(credentials: 'aws-creds', region: "${AWS_REGION}") {
                    sh '''
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
