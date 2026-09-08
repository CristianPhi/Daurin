import { createApp } from '../src/bootstrap';

type ExpressHandler = (req: any, res: any) => any;

let cachedHandler: ExpressHandler | undefined;

async function getHandler() {
  if (!cachedHandler) {
    const app = await createApp();
    await app.init();
    cachedHandler = app.getHttpAdapter().getInstance() as ExpressHandler;
  }

  return cachedHandler;
}

export default async function handler(req: any, res: any) {
  const expressHandler = await getHandler();
  return expressHandler(req, res);
}