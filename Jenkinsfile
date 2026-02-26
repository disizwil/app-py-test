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
    
    environment {
        // On définit le nom de l'image ici pour plus de clarté
        IMAGE_NAME = "disizwil365/mon-app-devsecops:latest"
    }

    stages {
        stage('Checkout') {
            steps {
                // Récupère le code depuis GitHub
                checkout scm
            }
        }

        stage('Build & Push Image') {
            steps {
                container('kaniko') {
                    // Utilise l'ID du credential que tu as créé dans Jenkins
                    withCredentials([usernamePassword(credentialsId: 'docker-hub-credentials', usernameVariable: 'DOCKER_USER', passwordVariable: 'DOCKER_PASSWORD')]) {
                        sh """
                        # 1. Création de la config d'authentification pour Kaniko
                        mkdir -p /kaniko/.docker
                        echo "{\\"auths\\":{\\"https://index.docker.io/v2/\\":{\\"auth\\":\\"\$(echo -n \${DOCKER_USER}:\${DOCKER_PASSWORD} | base64)\\"}}}" > /kaniko/.docker/config.json
                        
                        # 2. Construction et envoi de l'image
                        /kaniko/executor --context ${env.WORKSPACE} \
                            --dockerfile Dockerfile \
                            --destination ${IMAGE_NAME}
                        """
                    }
                }
            }
        }

        stage('Security Scan (Trivy)') {
            steps {
                container('trivy') {
                    echo "🔍 Analyse de l'image poussée : ${IMAGE_NAME}"
                    // Le pipeline échouera si des vulnérabilités CRITICAL sont trouvées
                    sh "trivy image --exit-code 1 --severity CRITICAL ${IMAGE_NAME}"
                }
            }
        }

        stage('Cleanup') {
            steps {
                echo "Nettoyage terminé. L'image est disponible sur Docker Hub."
            }
        }
    }
    
    post {
        success {
            echo "✅ Build, Push et Scan réussis !"
        }
        failure {
            echo "❌ Le pipeline a échoué. Vérifiez les logs (Auth ou Sécurité)."
        }
    }
}
