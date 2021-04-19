FROM golang:1.15-alpine

RUN apk update && \
    apk add ca-certificates && \
    update-ca-certificates
RUN apk add make

RUN mkdir -p /rds_exporter/promu
WORKDIR /rds_exporter
RUN wget https://github.com/prometheus/promu/releases/download/v0.12.0/promu-0.12.0.linux-amd64.tar.gz -P /rds_exporter/promu
RUN tar -xvzf /rds_exporter/promu/promu-0.12.0.linux-amd64.tar.gz -C /rds_exporter/promu/
RUN cp /rds_exporter/promu/promu-0.12.0.linux-amd64/promu /go/bin/

COPY . /rds_exporter
RUN make build

EXPOSE 9042
ENTRYPOINT  [ "./rds_exporter", "--config.file=/etc/rds_exporter/config.yml" ]
