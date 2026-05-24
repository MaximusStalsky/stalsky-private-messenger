import 'dotenv/config';
import { buildApp } from './app.js';

const port = Number(process.env.PORT ?? 8080);
const host = process.env.HOST ?? '127.0.0.1';

const app = buildApp();

app.listen({ port, host }).then(() => {
  console.log(`My Messenger server listening on http://${host}:${port}`);
});
