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
      command:
        - sleep
      args:
        - 99d
      volumeMounts:
        - name: docker-config
          mountPath: /kaniko/.docker
    - name: trivy
      image: aquasec/trivy:latest
      command:
        - sleep
      args:
        - 99d
  volumes:
    - name: docker-config
      emptyDir: {}
'''
        }
    }

    environment {
        IMAGE_NAME = "disizwil365/mon-app-devsecops:latest"
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
    "https://index.docker.io/v1/": { "auth": "$AUTH" },
    "https://index.docker.io/v2/": { "auth": "$AUTH" }
  }
}
EOF

                            /kaniko/executor \
                              --context "$WORKSPACE" \
                              --dockerfile Dockerfile \
                              --destination "$IMAGE_NAME" \
                              --verbosity=info
                        '''
                    }
                }
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                container('trivy') {
                    sh '''
                        echo "🔍 Analyse de l'image : ${IMAGE_NAME}"
                        trivy image --severity CRITICAL --exit-code 1 ${IMAGE_NAME}
                    '''
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo "Nettoyage terminé."
            }
        }
    }
        stage('Update Manifest') {
            steps {
                // On utilise un conteneur avec Git installé (on peut en ajouter un au pod ou utiliser l'image par défaut)
                container('kaniko') { // On peut détourner kaniko ou ajouter un conteneur 'alpine/git'
                    withCredentials([usernamePassword(credentialsId: 'github-creds-infra', usernameVariable: 'GIT_USER', passwordVariable: 'GIT_TOKEN')]) {
                        sh """
                        # Configuration de Git
                        git config --global user.email "jenkins@example.com"
                        git config --global user.name "Jenkins CI"
                        
                        # Clonage du repo d'infra
                        git clone https://${GIT_USER}:${GIT_TOKEN}@github.com/${GIT_USER}/app-py-test-infra.git
                        cd app-py-test-infra
                        
                        # Mise à jour de l'image dans le fichier deployment.yaml
                        # On remplace l'ancienne image par la nouvelle (ici on force le refresh)
                        sed -i "s|image: .*|image: disizwil365/mon-app-devsecops:latest|g" deployment.yaml
                        
                        # Commit et Push
                        git add deployment.yaml
                        git commit -m "Update image to latest by Jenkins Build #${env.BUILD_NUMBER}" || echo "No changes to commit"
                        git push origin main
                        """
                    }
                }
            }
        }

    post {
        success {
            echo "✅ Build, Push et Scan réussis !"
        }
        failure {
            echo "❌ Le pipeline a échoué. Vérifiez les logs (Auth Docker Hub ou vulnérabilités)."
        }
    }
}
