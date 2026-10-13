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
                echo '=== STAGE 2: Running Unit Tests ==='
                // Jika go test bernilai non-zero (gagal), pipeline akan otomatis STOP secara tegas.
                sh 'go test -v ./...'
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
                        # 1. Compile binary terbaru di runner
                        CGO_ENABLED=0 GOOS=linux go build -ldflags="-X main.version=${commitHash}" -o app-pipeline .
                        
                        # 2. Swap binary ke dalam container produksi & restart
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
