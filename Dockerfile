FROM ghcr.io/cirruslabs/flutter:3.22.3 AS build
WORKDIR /app

COPY pubspec.yaml pubspec.lock* ./
RUN flutter pub get

COPY . .
RUN flutter build web --release

FROM nginx:1.27-alpine
COPY nginx.conf.template /etc/nginx/conf.d/default.conf.template
COPY --from=build /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["/bin/sh", "-c", "envsubst '$PORT' < /etc/nginx/conf.d/default.conf.template > /etc/nginx/conf.d/default.conf && nginx -g 'daemon off;'"]
