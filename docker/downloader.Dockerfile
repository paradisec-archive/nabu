# TODO: We build this ourselves instead of using upstream image because we can't work out how to subpath at runtime yet
FROM alpine/git AS code

RUN ls /
RUN git clone https://github.com/paradisec-archive/arocapi-downloader.git /code

# Stage 2: Install the deps
FROM node:lts-alpine AS deps

# Enable corepack for pnpm
RUN corepack enable

WORKDIR /app

# Copy package files
COPY --from=code /code/package.json /code/pnpm-lock.yaml ./

# Install all dependencies (including dev for build)
RUN pnpm install --frozen-lockfile

# Stage 2: Build the application
FROM node:lts-alpine AS builder

RUN corepack enable

WORKDIR /app

# Copy dependencies from deps stage
COPY --from=deps /app/node_modules ./node_modules

# Copy source files
COPY --from=code /code/package.json /code/pnpm-lock.yaml ./
COPY --from=code /code/tsconfig.json ./
COPY --from=code /code/vite.config.ts ./
COPY --from=code /code/src ./src
COPY --from=code /code/public ./public

# Build the application
RUN NITRO_APP_BASE_URL=/downloader/ pnpm build

# Stage 3: Production image
FROM node:lts-alpine AS production

RUN corepack enable

WORKDIR /app

# Create non-root user for security
RUN addgroup --system --gid 1001 nodejs && \
  adduser --system --uid 1001 appuser

# Copy package files for production install
COPY --from=code /code/package.json /code/pnpm-lock.yaml ./

# Install production dependencies only
RUN pnpm install --frozen-lockfile --prod

# Copy built application from builder stage
COPY --from=builder /app/.output ./.output

# Change ownership to non-root user
#RUN chown -R appuser:nodejs /app

# Switch to non-root user
USER appuser

# Expose the application port
EXPOSE 7000

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:7000/downloader || exit 1

# Start the application
CMD ["pnpm", "run", "start"]
