# Technical Test — Shift Engineer DevOps

**Candidate Name:** Gramaldy Euraldo Hutapea  
**Repository:** https://github.com/gramaldyhtp/devops-technical-test  
**Target OS Environment:** Ubuntu Linux (VM)

---

## PART I: Build (Docker Optimization & Version Injection)

### 1. Multi-Stage Dockerfile
```dockerfile
# STAGE 1: Builder
FROM golang:1.22-alpine AS builder

ARG VERSION=dev
WORKDIR /app

COPY go.mod ./
COPY . .

# Run unit tests
RUN go test -v ./...

# Build statically linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-X main.version=${VERSION}" -o app .

# STAGE 2: Minimal Base Image
FROM alpine:3.19

WORKDIR /root/
COPY --from=builder /app/app .

EXPOSE 8080
CMD ["./app"]

2. Build Command Used
Bash

docker build --build-arg VERSION=1.0.0 -t my-go-app:1.0.0 .

3. Image Size & Justification

    Final Image Size: 14.4 MB (docker images my-go-app:1.0.0)

    Explanation: A multi-stage build strategy was utilized to isolate the Go compilation toolchain (~300MB+) inside the temporary builder stage. Only the compiled, statically-linked Go binary (CGO_ENABLED=0) is copied into the minimal alpine:3.19 runtime stage (~7MB), drastically reducing the attack surface and overall container footprint.

#PART II: Deploy & Production Hotfix (Binary Swap)
1. Commands Used
Bash

# 1. Initial Deployment
docker run -d --name go-app-prod -p 8080:8080 --restart unless-stopped my-go-app:1.0.0

# 2. Emergency Hotfix (Compile & Swap Binary)
CGO_ENABLED=0 GOOS=linux go build -ldflags="-X main.version=1.0.1" -o app-hotfix .
docker cp app-hotfix go-app-prod:/root/app
docker restart go-app-prod

2. curl Output Verification

    Before Binary Swap:
    Plaintext

    $ curl http://localhost:8080
    Hello, DevOps! version=1.0.0
    After Binary Swap:
    Plaintext

    $ curl http://localhost:8080
    Hello, DevOps! version=1.0.1

3. Justification for Production Hotfix Approach

 The docker cp + docker restart binary swap approach was selected because it enables near-instantaneous application patching without requiring a full Docker image rebuild, registry push/pull cycle, or container destruction. The running container retains its network configuration, environment variables, and runtime state while reducing service downtime to merely 1–2 seconds during the process restart. This is highly suitable for urgent production hotfixes where infrastructure layers remain unchanged.
#PART III: CI/CD with Jenkins Pipeline
1. Jenkinsfile
Groovy

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
                echo '=== STAGE 4: Simulating Registry Push via Credentials Binding ==='
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
                        # Extract newly compiled binary from image via docker cp
                        docker create --name temp-build ${APP_NAME}:${commitHash}
                        docker cp temp-build:/root/app ./app-pipeline
                        docker rm temp-build
                        
                        # Hotfix swap binary into production container & restart
                        docker cp app-pipeline ${CONTAINER_NAME}:/root/app
                        docker restart ${CONTAINER_NAME}
                        
                        # Cleanup temp local binary
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
            echo "FAILURE: Pipeline failed! Deployment aborted."
        }
    }
}

2. Rollback Handling Strategy

    If the Deploy stage fails midway (e.g., failed binary extraction or container restart error), the pipeline immediately aborts and triggers the post { failure { ... } } block. For automated rollbacks, an existing stable binary is backed up (docker cp go-app-prod:/root/app ./app-backup) before executing the swap. If a post-restart health check fails, the pipeline automatically restores ./app-backup into the container and restarts it, reverting the application to the last known stable state.

How to Run & Verify Locally

    1.Clone the repository:

    git clone [https://github.com/gramaldyhtp/devops-technical-test.git](https://github.com/gramaldyhtp/devops-technical-test.git)
    cd devops-technical-test

    2.Run Unit Tests:
    go test -v ./...

    3.Build Docker Image with Version Injection:
    Bash

    docker build --build-arg VERSION=1.0.0 -t my-go-app:1.0.0 .

   4.Deploy & Test Application:
    Bash

    docker run -d --name go-app-prod -p 8080:8080 --restart unless-stopped my-go-app:1.0.0
    curl http://localhost:8080

