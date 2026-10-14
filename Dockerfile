# STAGE 1: Builder
FROM golang:1.22-alpine AS builder

ARG VERSION=dev
WORKDIR /app

COPY go.mod ./
COPY . .

# Jalankan unit test di dalam container builder
RUN go test -v ./...

# Build statically linked binary
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-X main.version=${VERSION}" -o app .

# STAGE 2: Minimal Base Image
FROM alpine:3.19

WORKDIR /root/
COPY --from=builder /app/app .

EXPOSE 8080
CMD ["./app"]
