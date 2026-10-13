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
                echo '=== STAGE 2: Running Unit Tests in Go Container ==='
                // Menjalankan go test di dalam container golang:1.22-alpine
                sh 'docker run --rm -v $PWD:/app -w /app golang:1.22-alpine go test -v ./...'
            }
        }

        stage('Build Image') {
            steps {
                script {
                    echo '=== STAGE 3: Building Docker Image with Commit Hash ==='
                    def commitHash = sh(script: 'git rev-parse --short HEAD', returnStdout: true).trim()
                    sh "docker build --build-arg VERSION=${commitHash} -t ${APP_NAME}:${commitHash} ."
                }
            }
        }

        stage('Push (Simulated)') {
            steps {
                echo '=== STAGE 4: Simulating Registry Push via Jenkins Credentials ==='
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
                        # Compile binary terbaru menggunakan container golang
                        docker run --rm -v \$PWD:/app -w /app -e CGO_ENABLED=0 -e GOOS=linux golang:1.22-alpine go build -ldflags="-X main.version=${commitHash}" -o app-pipeline .
                        
                        # Swap binary ke dalam container produksi & restart
                        docker cp app-pipeline ${CONTAINER_NAME}:/root/app
                        docker restart ${CONTAINER_NAME}
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
