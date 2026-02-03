# ---------- Build Stage ----------
FROM rust:1.75-slim AS builder

WORKDIR /app

# Copy Cargo manifest files first to cache dependency downloads
COPY Cargo.toml Cargo.lock ./

# Create a dummy src/main.rs so `cargo build` can resolve & cache deps
# without needing your full source code yet
RUN mkdir src && echo 'fn main() {}' > src/main.rs
RUN cargo build --release 2>&1

# Now copy the real source in and do the real build
COPY src ./src
# Touch main.rs to force a recompile of your code (not deps)
RUN touch src/main.rs && cargo build --release 2>&1

# ---------- Runtime Stage ----------
FROM debian:bookworm-slim

# Install CA certs (handy if your app makes HTTPS calls)
RUN apt-get update && apt-get install -y --no-install-recommends ca-certificates \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app

# Copy the compiled binary — adjust the binary name to match your package name in Cargo.toml
COPY --from=builder /app/target/release/my_app /app/my_app

# Expose the port your app listens on (change as needed)
EXPOSE 8080

# Run the binary
CMD ["./my_app"]