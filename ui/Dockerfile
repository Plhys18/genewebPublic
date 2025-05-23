# Stage 1: Build the Flutter web app
FROM ubuntu:22.04 AS build-stage

# Install required packages
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa

# Install Flutter
RUN git clone https://github.com/flutter/flutter.git /flutter
ENV PATH="/flutter/bin:${PATH}"

# Set Flutter to use web
RUN flutter channel stable
RUN flutter upgrade
RUN flutter config --enable-web

# Copy Flutter project
WORKDIR /app
COPY . /app/

# Build for web
RUN flutter pub get
RUN flutter build web --release

# Stage 2: Serve the app using Nginx
FROM nginx:1.25-alpine

# Copy the built web app to nginx directory
COPY --from=build-stage /app/build/web /usr/share/nginx/html

# Expose port
EXPOSE 80

# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
