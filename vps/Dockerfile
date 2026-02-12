# Build stage
FROM node:20-alpine AS build

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install

COPY tsconfig.json ./
COPY src/ ./src/

RUN npm run build

# Run stage
FROM node:20-alpine

WORKDIR /app

COPY package.json package-lock.json* ./
RUN npm install --omit=dev

COPY --from=build /app/dist ./dist

# APNs key file will be mounted as a volume or copied at deploy time
# COPY apns-key.p8 /app/apns-key.p8

USER node

CMD ["node", "dist/index.js"]
