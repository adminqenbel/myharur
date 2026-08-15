# Multi-stage Dockerfile for MyHarur Flutter Web

# Stage 1: Build Flutter Web Release with pre-configured official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build-stage

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

# Stage 2: Serve via Lightweight Nginx
FROM nginx:alpine-slim AS production-stage

COPY --from=build-stage /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
