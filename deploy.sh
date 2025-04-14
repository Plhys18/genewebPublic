#!/bin/bash

# Check if backend Dockerfile exists, if not create it
if [ ! -f "backend/Dockerfile" ]; then
  echo "Creating backend Dockerfile..."
  cat > backend/Dockerfile << 'EOL'
FROM python:3.10-slim

WORKDIR /app

# Install dependencies
COPY ./my_analysis_project/requirements_clean.txt /app/requirements.txt
RUN pip install --no-cache-dir -r requirements.txt
RUN pip install gunicorn uvicorn

# Copy project files
COPY ./my_analysis_project /app/

# Gunicorn configuration
COPY ./my_analysis_project/gunicorn_config.py /app/gunicorn_config.py

# Update the gunicorn config to use the new domain
RUN sed -i 's/golembackend.duckdns.org/golem-dev.biodata.ceitec.cz/g' /app/gunicorn_config.py

# Expose port for the application
EXPOSE 8000

# Command to run the application
CMD ["gunicorn", "-c", "gunicorn_config.py", "my_analysis_project.asgi:application"]
EOL
fi

# Check if ui Dockerfile exists, if not create it
if [ ! -f "ui/Dockerfile" ]; then
  echo "Creating frontend Dockerfile..."
  cat > ui/Dockerfile << 'EOL'
FROM nginx:1.25-alpine

# Copy the pre-built web files to the nginx directory
COPY ./build/web /usr/share/nginx/html

# Expose ports
EXPOSE 80 443

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
EOL
fi

# Build the Flutter web application
cd ui
flutter build web --release
cd ..

# Start the Docker Compose services
docker-compose up -d

echo "Golem application has been deployed successfully"
echo "Frontend and backend are now accessible at https://golem-dev.biodata.ceitec.cz"
