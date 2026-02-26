pipeline {
    agent {
        kubernetes {
            yaml '''
              apiVersion: v1
              kind: Pod
              spec:
                containers:
                - name: kaniko
                  image: gcr.io/kaniko-project/executor:debug
                  command: ["sleep"]
                  args: ["99d"]
                - name: trivy
                  image: aquasec/trivy:latest
                  command: ["sleep"]
                  args: ["99d"]
            '''
        }
    }
    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }
        stage('Build & Push') {
            steps {
                container('kaniko') {
                    // On utilise les credentials Docker Hub créés précédemment
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh """
                        /kaniko/executor --context `pwd` \
                            --dockerfile Dockerfile \
                            --destination \$DOCKER_USER/mon-app-devsecops:latest
                        """
                    }
                }
            }
        }
        stage('Security Scan') {
            steps {
                container('trivy') {
                   // On scanne l'image qu'on vient de pousser
                    sh "trivy image --exit-code 1 --severity CRITICAL disizwil365/mon-app-devsecops:latest"
                }
            }
        }
    }
}
