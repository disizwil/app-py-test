# Image de base légère
FROM python:3.12-slim

# On évite de tourner en mode Root pour la sécurité
RUN useradd -m devuser
USER devuser
WORKDIR /home/devuser

# Installation des dépendances
COPY --chown=devuser:devuser . .
RUN pip install --no-cache-dir flask

# Port d'écoute
EXPOSE 5000

# Lancement de l'app
CMD ["python", "app.py"]
