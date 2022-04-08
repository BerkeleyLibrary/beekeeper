# =============================================================================
# Target: base
#
# The base stage scaffolds elements which are common to building and running
# the application, such as installing ca-certificates, creating the app user,
# and installing runtime system dependencies.
FROM ruby:3.0-slim AS base

# ------------------------------------------------------------
# Install packages common to dev and prod.

# Install standard packages from the Debian repository
RUN apt-get update -qq && \
    apt-get install -y --no-install-recommends \
        ca-certificates \
        build-essential

# ------------------------------------------------------------
# Run configuration

# All subsequent commands are executed relative to this directory.
WORKDIR /opt/app

# Install dependencies
COPY Gemfile* ./
RUN bundle install --system

# Copy the codebase
COPY . .

# Add binstubs to the path.
ENV PATH="/opt/app/bin:$PATH"

ENTRYPOINT ["rake"]
CMD ["-T"]
