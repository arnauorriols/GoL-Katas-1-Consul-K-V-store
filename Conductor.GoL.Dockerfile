FROM alpine:3.4
RUN apk add --no-cache jq bash curl findutils coreutils bc
WORKDIR /opt/GoL/
COPY conductor.sh .
ENTRYPOINT ["./conductor.sh"]
