# Multi-stage Dockerfile for MyHarur Flutter Web

# Stage 1: Build Flutter Web Release with pre-configured official Flutter image
FROM ghcr.io/cirruslabs/flutter:stable AS build-stage

WORKDIR /app
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

COPY . .

# Build-time credentials. Render passes these from its dashboard env vars
# as Docker build args (configure "Docker Build Args" in the Render service
# settings to forward SUPABASE_URL / SUPABASE_PUBLISHABLE_KEY here).
# Without these, the app builds successfully but every Supabase call fails
# at runtime — this was the root cause of the app appearing broken.
ARG SUPABASE_URL
ARG SUPABASE_PUBLISHABLE_KEY
RUN flutter build web --release \
    --dart-define=SUPABASE_URL=${SUPABASE_URL} \
    --dart-define=SUPABASE_PUBLISHABLE_KEY=${SUPABASE_PUBLISHABLE_KEY}

# Stage 2: Serve via Lightweight Nginx
FROM nginx:alpine-slim AS production-stage

COPY --from=build-stage /app/build/web /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
