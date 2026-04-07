FROM golang:1.25-alpine AS builder

WORKDIR /build

RUN apk add --no-cache gcc musl-dev git

COPY backend/go.mod ./
RUN go mod download

COPY backend/ ./
COPY frontend/index.html ./

RUN go mod tidy

RUN CGO_ENABLED=1 GOOS=linux go build -o registry -ldflags="-s -w" .

FROM alpine:3.21

RUN apk add --no-cache --virtual .rundeps ca-certificates

RUN mkdir -p /data /app

COPY --from=builder /build/registry /app/registry
COPY --from=builder /build/index.html /app/static/index.html

RUN mkdir -p /data

RUN adduser -D -u 1000 appuser && chown -R appuser:appuser /app /data

USER appuser

EXPOSE 8080

ENV PORT=8080
ENV DB_DRIVER=mysql

HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD wget -q --spider http://localhost:8080/api/v1/health || exit 1

ENTRYPOINT ["/app/registry"]
