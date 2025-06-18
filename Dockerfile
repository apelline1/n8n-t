# Use a UBI Node.js image that supports Node.js 20
# Replace 'ubi8/nodejs-20' with the actual image stream tag available in your OpenShift 4.18
# For example: registry.redhat.io/ubi8/nodejs-20:latest or openshift/nodejs-20-centos7 (older)
FROM registry.access.redhat.com/rhel8/ubi8/nodejs-20:latest AS builder

# Set working directory
WORKDIR /app

# Copy package.json and pnpm-lock.yaml first to leverage Docker layer caching
COPY package.json pnpm-lock.yaml ./
# If you have specific pnpm-workspace.yaml, copy that too
# COPY pnpm-workspace.yaml ./

# Install pnpm globally (or ensure it's available)
# The UBI Node.js image might already have npm, so we install pnpm specifically.
RUN npm install -g pnpm@9.6.0

# Install dependencies
# Use 'pnpm install --frozen-lockfile' for CI/CD to ensure consistent builds
RUN pnpm install --frozen-lockfile

# Copy the rest of your application code
COPY . .

# Build the application
# This assumes your 'build' script handles the monorepo build with turbo
RUN pnpm build

# --- Runtime Stage (Optional, for smaller production images) ---
FROM registry.access.redhat.com/ubi8/nodejs-20:latest AS runner

WORKDIR /app

# Copy only necessary files from the builder stage
# This depends on what your 'n8n' application needs to run.
# Typically, you'd copy:
# - node_modules
# - built application code (e.g., dist, build folders)
# - package.json (for start script)
COPY --from=builder /app/package.json ./package.json
COPY --from=builder /app/node_modules ./node_modules
COPY --from=builder /app/packages ./packages
# Add other necessary files/folders as per your n8n structure

# Set the command to run your application
# Ensure this matches your 'start' script in package.json
CMD ["pnpm", "start"]
