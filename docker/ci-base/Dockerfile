# Rebuild trigger: manual 2025-07-11b
# syntax=docker/dockerfile:1
FROM ubuntu:24.04

LABEL maintainer="bee-mvp CI" description="Unified toolchain image for GitHub Actions and local act runs"

ARG FLUTTER_VERSION=3.32.6
ARG NODE_VERSION=20.9.0
ARG DENO_VERSION=2.3.5
ARG GITLEAKS_VERSION=8.18.2

ENV DEBIAN_FRONTEND=noninteractive \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:/root/.deno/bin:$PATH"

# ---------------- Base packages ----------------
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      curl wget git bash make zip unzip xz-utils jq ca-certificates gnupg lsb-release sudo python3 python3-pip python-is-python3 postgresql-client && \
    rm -rf /var/lib/apt/lists/*

# ---------------- Node.js ----------------
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - && \
    apt-get update && \
    apt-get install -y nodejs && \
    npm install -g npm@latest && \
    npm --version && node --version

# ---------------- Deno ----------------
RUN curl -fsSL https://deno.land/x/install/install.sh | sh -s v${DENO_VERSION} && \
    deno --version

# ---------------- Flutter ----------------
# Use shallow git clone of the desired Flutter tag instead of unavailable SDK archive.
RUN git clone --depth 1 --branch ${FLUTTER_VERSION} https://github.com/flutter/flutter.git /opt/flutter && \
    # Fix "dubious ownership" warning and ensure write perms for root build user
    git config --global --add safe.directory /opt/flutter && \
    chmod -R a+w /opt/flutter

# ---------------- Supabase CLI ----------------
RUN curl -L https://github.com/supabase/cli/releases/latest/download/supabase_linux_amd64.tar.gz \
      -o /tmp/supabase.tar.gz && \
    tar -xzf /tmp/supabase.tar.gz -C /usr/local/bin supabase && \
    rm /tmp/supabase.tar.gz && \
    supabase --version

# ---------------- Gitleaks ----------------
RUN curl -L https://github.com/gitleaks/gitleaks/releases/download/v${GITLEAKS_VERSION}/gitleaks_${GITLEAKS_VERSION}_linux_x64.tar.gz -o /tmp/gitleaks.tar.gz && \
    tar -xzf /tmp/gitleaks.tar.gz -C /usr/local/bin gitleaks && \
    rm /tmp/gitleaks.tar.gz && \
    gitleaks version

# ---------------- Android SDK & NDK ----------------
RUN apt-get update && apt-get install -y --no-install-recommends openjdk-17-jdk wget unzip && \
    mkdir -p /opt/android-sdk/cmdline-tools && \
    curl -sSL https://dl.google.com/android/repository/commandlinetools-linux-11076708_latest.zip -o /tmp/cmdline-tools.zip && \
    unzip -q /tmp/cmdline-tools.zip -d /opt/android-sdk/cmdline-tools && \
    mv /opt/android-sdk/cmdline-tools/cmdline-tools /opt/android-sdk/cmdline-tools/latest && \
    yes | /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android-sdk --licenses && \
    /opt/android-sdk/cmdline-tools/latest/bin/sdkmanager --sdk_root=/opt/android-sdk \
      "platform-tools" "platforms;android-34" "build-tools;34.0.0" "ndk;26.3.11579264" && \
    rm /tmp/cmdline-tools.zip

ENV ANDROID_HOME=/opt/android-sdk
ENV PATH="/opt/android-sdk/platform-tools:/opt/android-sdk/cmdline-tools/latest/bin:${PATH}"

RUN ln -sf /usr/bin/python3 /usr/bin/python && ln -sf /usr/bin/python3 /usr/local/bin/python

WORKDIR /workspace

CMD ["/bin/bash"] 