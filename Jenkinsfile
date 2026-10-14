pipeline {
    agent any

    environment {
        APP_NAME         = 'my-go-app'
        CONTAINER_NAME   = 'go-app-prod'
        REGISTRY_CRED_ID = 'docker-registry-cred'
    }

    stages {
        stage('Checkout') {
            steps {
                echo '=== STAGE 1: Checking out code from repository ==='
                checkout scm
            }
        }

        stage('Test') {
            steps {
                echo '=== STAGE 2: Running Unit Tests via Docker Build Context ==='
                sh 'docker build --target builder -t ${APP_NAME}-test .'
            }
        }

        stage('Build Image') {
            steps {
                script {
                    echo '=== STAGE 3: Building Final Docker Image with Commit Hash ==='
                    def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    sh "docker build --build-arg VERSION=${commitHash} -t ${APP_NAME}:${commitHash} ."
                }
            }
        }

        stage('Push (Simulated)') {
            steps {
                withCredentials([usernamePassword(credentialsId: env.REGISTRY_CRED_ID, usernameVariable: 'REG_USER', passwordVariable: 'REG_PASS')]) {
                    sh '''
                        echo "Authenticating to registry using credentials: $REG_USER"
                        echo "Simulating: docker push ${APP_NAME}:${BUILD_NUMBER}"
                    '''
                }
            }
        }

        stage('Deploy (Automated Hotfix Swap)') {
            steps {
                script {
                    echo '=== STAGE 5: Deploying via Binary Swap Strategy ==='
                    def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()

                    sh """
                        # 1. Ekstrak binary terkompilasi dari image terbaru via docker cp
                        docker create --name temp-build ${APP_NAME}:${commitHash}
                        docker cp temp-build:/root/app ./app-pipeline
                        docker rm temp-build

                        # 2. Swap binary ke dalam container produksi & restart
                        docker cp app-pipeline ${CONTAINER_NAME}:/root/app
                        docker restart ${CONTAINER_NAME}

                        # Hapus binary sementara
                        rm -f app-pipeline
                    """
                }
            }
        }
    }

    post {
        success {
            echo "SUCCESS: Pipeline executed successfully! End-to-end flow complete."
        }
        failure {
            echo "FAILURE: Pipeline failed! Deployment aborted. Check logs for details."
        }
    }
}
