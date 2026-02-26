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
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker
    - name: trivy
      image: aquasec/trivy:latest
      command: ["sleep"]
      args: ["99d"]
    - name: git-tool
      image: alpine/git:latest
      command: ["sleep"]
      args: ["99d"]
  volumes:
    - name: docker-config
      emptyDir: {}
'''
        }
    }

    environment {
        // CONSEIL : Utilise le numéro de build pour forcer ArgoCD à voir un changement
        IMAGE_NAME = "disizwil365/mon-app-devsecops:v${env.BUILD_NUMBER}"
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
            }
        }

        stage('Build & Push Image (Kaniko)') {
            steps {
                container('kaniko') {
                    withCredentials([
                        usernamePassword(
                            credentialsId: 'docker-hub-credentials',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_TOKEN'
                        )
                    ]) {
                        sh '''
                            set -eux
                            export DOCKER_CONFIG=/kaniko/.docker
                            mkdir -p $DOCKER_CONFIG
                            AUTH=$(printf "%s:%s" "$DOCKER_USER" "$DOCKER_TOKEN" | base64 | tr -d '\\n')
                            cat > $DOCKER_CONFIG/config.json <<EOF
{
  "auths": {
    "https://index.docker.io/v1/": { "auth": "$AUTH" }
  }
}
EOF
                            /kaniko/executor \
                              --context "$WORKSPACE" \
                              --dockerfile Dockerfile \
                              --destination "$IMAGE_NAME"
                        '''
                    }
                }
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                container('trivy') {
                    sh "trivy image --severity CRITICAL --exit-code 1 ${IMAGE_NAME}"
                }
            }
        }

        stage('Update Manifest') {
            steps {
                // Utilisation du conteneur git-tool défini dans le YAML plus haut
                container('git-tool') { 
                    withCredentials([usernamePassword(credentialsId: 'github-creds-infra', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                        sh """
                            git config --global user.email "jenkins@example.com"
                            git config --global user.name "Jenkins CI"
                            
                            # Clonage du repo d'infra
                            git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/${GIT_USER}/app-py-test-infra.git
                            cd app-py-test-infra
                            
                            # Mise à jour avec le tag dynamique
                            sed -i "s|image: .*|image: ${IMAGE_NAME}|g" deployment.yaml
                            
                            git add deployment.yaml
                            git commit -m "Update image to ${IMAGE_TAG} by Jenkins Build #${env.BUILD_NUMBER}" || echo "No changes to commit"
                            git push origin main
                        """
                    }
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo "Nettoyage terminé."
            }
        }
    } // FIN DU BLOC STAGES

    post {
        success {
            echo "✅ CI/CD Terminé avec succès !"
        }
        failure {
            echo "❌ Échec du pipeline."
        }
    }
}
