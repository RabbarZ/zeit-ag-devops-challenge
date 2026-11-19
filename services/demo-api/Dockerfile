# Build context is the repository root (npm workspaces share one lockfile).
FROM node:24-alpine AS build
WORKDIR /app
COPY package.json package-lock.json ./
COPY services/demo-api/package.json services/demo-api/
COPY services/tenant-provisioner/package.json services/tenant-provisioner/
RUN npm ci -w services/demo-api
COPY services/demo-api/tsconfig.json services/demo-api/
COPY services/demo-api/src services/demo-api/src
RUN npm run build -w services/demo-api

FROM node:24-alpine
WORKDIR /app
ENV NODE_ENV=production
COPY package.json package-lock.json ./
COPY services/demo-api/package.json services/demo-api/
COPY services/tenant-provisioner/package.json services/tenant-provisioner/
RUN npm ci -w services/demo-api --omit=dev --omit=peer
COPY --from=build /app/services/demo-api/dist services/demo-api/dist
WORKDIR /app/services/demo-api
USER node
EXPOSE 3000
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
  CMD wget -q -O /dev/null http://localhost:3000/api/health || exit 1
CMD ["node", "--require", "./dist/otel.js", "./dist/server.js"]
