# ==========================================
# STAGE 1: Builder
# ==========================================
FROM golang:1.22-alpine AS builder

# Menerima argument versi dari command docker build
ARG VERSION=dev

WORKDIR /app

# Copy dependency file & source code
COPY go.mod ./
COPY . .

# Build statically linked binary
# CGO_ENABLED=0 mematikan C bindings agar dihasilkan murni static binary
# -ldflags "-X main.version=..." melakukan injeksi nilai variabel 'version' di file main.go
RUN CGO_ENABLED=0 GOOS=linux go build -a -installsuffix cgo -ldflags="-X main.version=${VERSION}" -o app .

# ==========================================
# STAGE 2: Final Minimal Runtime
# ==========================================
FROM alpine:3.19

WORKDIR /root/

# Copy hanya binary hasil kompilasi dari stage builder
COPY --from=builder /app/app .

EXPOSE 8080

CMD ["./app"]
