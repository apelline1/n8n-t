# Use a well-known, accessible base image for Node.js 20 on OpenShift
FROM registry.redhat.io/rhel8/nodejs-20:latest AS builder

USER root
RUN npm install -g pnpm@9.6.0
USER 1001

WORKDIR /opt/app-root/src

COPY package.json pnpm-lock.yaml ./
COPY pnpm-workspace.yaml ./ 
# If you have this
COPY packages packages/
COPY scripts scripts/
# Copy the 'patches' directory
COPY patches/ patches/
# Install all dependencies (including devDependencies for build)
RUN pnpm install --frozen-lockfile --production=false

RUN pnpm install --frozen-lockfile --production=false

COPY . . # Copy remaining files

RUN pnpm run build

FROM registry.redhat.io/rhel8/nodejs-20:latest # Use the same base for consistency

USER 1001

WORKDIR /opt/app-root/src

# Copy only essential runtime files from the builder stage
# This requires knowing n8n's output structure. Example:
COPY --from=builder /opt/app-root/src/packages/cli/bin /opt/app-root/src/packages/cli/bin
COPY --from=builder /opt/app-root/src/packages/core /opt/app-root/src/packages/core # Example for built core
# ... and so on for all your built packages/dist directories needed at runtime

# Copy package.json (or a slimmed down version) for production dependencies
COPY --from=builder /opt/app-root/src/package.json ./package.json
COPY --from=builder /opt/app-root/src/pnpm-lock.yaml ./pnpm-lock.yaml

# Install production dependencies only in the final image
RUN pnpm install --production --frozen-lockfile

EXPOSE 5678 # Default n8n port

# Define your startup command
CMD ["pnpm", "start:default"]
