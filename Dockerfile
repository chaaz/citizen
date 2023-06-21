# build stage
FROM node:18 as build

WORKDIR /citizen

COPY package.json .
COPY package-lock.json .

RUN curl -s https://ngrok-agent.s3.amazonaws.com/ngrok.asc | tee /etc/apt/trusted.gpg.d/ngrok.asc >/dev/null && echo "deb https://ngrok-agent.s3.amazonaws.com buster main" | tee /etc/apt/sources.list.d/ngrok.list && apt update && apt install ngrok

RUN mkdir /root/.ngrok

# ngrok downloads are busted, just copy the cached linux:amd64 binaries
# into the cache so we don't try to download them
COPY aHR0cHM6Ly9iaW4uZXF1aW5veC5pby9jL2JOeWoxbVFWWTRjL25ncm9rLXYzLXN0YWJsZS1saW51eC1hbWQ2NC56aXA=.zip /root/.ngrok/aHR0cHM6Ly9iaW4uZXF1aW5veC5pby9jL2JOeWoxbVFWWTRjL25ncm9rLXYzLXN0YWJsZS1saW51eC1hbWQ2NC56aXA=.zip
COPY aHR0cHM6Ly9iaW4uZXF1aW5veC5pby9jLzRWbUR6QTdpYUhiL25ncm9rLXN0YWJsZS1saW51eC1hbWQ2NC56aXA=.zip /root/.ngrok/aHR0cHM6Ly9iaW4uZXF1aW5veC5pby9jLzRWbUR6QTdpYUhiL25ncm9rLXN0YWJsZS1saW51eC1hbWQ2NC56aXA=.zip

RUN npm install

COPY . .

RUN npm run client

RUN npm run build:linux

# final stage
FROM bitnami/minideb

LABEL maintainer="outsideris@gmail.com"
LABEL org.opencontainers.image.source = "https://github.com/outsideris/citizen"

RUN apt update && apt install -y git jq vim curl

COPY --from=build /citizen/dist/citizen-linux-x64 /usr/local/bin/citizen

WORKDIR /citizen

ENV CITIZEN_DATABASE_TYPE mongodb_or_sqlite
ENV CITIZEN_DATABASE_URL protocol//username:password@hosts:port/database?options
ENV CITIZEN_STORAGE file
ENV CITIZEN_STORAGE_PATH /path/to/store
#ENV CITIZEN_STORAGE_BUCKET BUCKET_IF_STORAGE_IS_S3
ENV NODE_ENV=production

EXPOSE 3000

#COPY ./entrypoint.sh /
#RUN chmod +x /entrypoint.sh
#CMD ["/entrypoint.sh"]

CMD citizen server
