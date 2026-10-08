FROM rust:1.96-bookworm AS build
# The Rust image supplies GCC; AWS-LC has pregenerated Linux bindings, so Clang is unnecessary.
RUN apt-get update && apt-get install -y --no-install-recommends libcrypt-dev cmake && rm -rf /var/lib/apt/lists/*
WORKDIR /build
COPY backend/ backend/
RUN cargo build --manifest-path backend/Cargo.toml --release --locked -p tracker-backend

FROM build AS tests
COPY models/ /build/models/
WORKDIR /build
CMD ["cargo", "test", "--manifest-path", "backend/Cargo.toml", "--workspace", "--locked", "--", "--include-ignored"]

FROM debian:bookworm-slim
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates tzdata libcrypt1 curl && rm -rf /var/lib/apt/lists/* \
 && useradd --system --uid 10001 --create-home tracker
WORKDIR /app
COPY --from=build /build/backend/target/release/tracker-backend /usr/local/bin/tracker-backend
COPY models/ /app/models/
COPY backend/furnace.toml /app/furnace.toml
ENV FURNACE_TRACKER__MODEL_PATH=/app/models/transaction-model.json TZ=Asia/Jakarta
USER 10001
EXPOSE 8080
HEALTHCHECK --interval=15s --timeout=5s --start-period=30s --retries=5 CMD curl -fsS http://127.0.0.1:8080/health/ready || exit 1
CMD ["tracker-backend"]
