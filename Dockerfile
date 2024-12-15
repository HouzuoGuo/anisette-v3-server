# Base for builder
FROM debian:stable-slim AS builder
# Deps for builder
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates ldc git clang dub libz-dev libssl-dev \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Build for builder
WORKDIR /opt/
COPY . .
RUN DC=ldc2 dub build -c "static" --build-mode allAtOnce -b release --compiler=ldc2

# Base for run
FROM debian:stable-slim
RUN apt-get update && apt-get install --no-install-recommends -y ca-certificates curl \
 && apt-get clean \
 && rm -rf /var/lib/apt/lists/*

# Copy build artefacts to run
WORKDIR /opt/
COPY --from=builder /opt/anisette-v3-server /opt/anisette-v3-server

# Setup rootless user which works with the volume mount
RUN useradd -ms /bin/bash Alcoholic \
 && mkdir /home/Alcoholic/.config/anisette-v3/lib/ -p \
 && chown -R Alcoholic /home/Alcoholic/ \
 && chmod -R 0755 /home/Alcoholic/ \
 && chown -R Alcoholic /opt/ \
 && chmod -R 0755 /opt/

# Run the artefact
USER Alcoholic
EXPOSE 6969
# 20241215(hz.gl):
# The entire /home/Alcoholic/.config needs to be persisted across restart because it contains the fake macbook's identity files.
# Among the files, the server executable creates "adi.db" but fails to set o+r in its file permission.
# The shell loop mitigates that permission issue.
CMD ["/bin/bash", "-c", "while true; do sleep 3; chmod -R 0755 /home/Alcoholic; done & /opt/anisette-v3-server"]
