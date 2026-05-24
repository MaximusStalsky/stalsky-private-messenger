FROM node:24-bookworm

WORKDIR /app/server

COPY server/package*.json ./
RUN npm ci

COPY server/ ./
COPY apps/messenger_app/build/web /app/apps/messenger_app/build/web

RUN npm run build

ENV HOST=0.0.0.0
ENV PORT=8080
ENV DATABASE_URL=/data/messenger.sqlite

EXPOSE 8080

CMD ["npm", "start"]
