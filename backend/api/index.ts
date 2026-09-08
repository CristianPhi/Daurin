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
  try {
    const expressHandler = await getHandler();
    return expressHandler(req, res);
  } catch (error) {
    console.error('Failed to initialize Vercel function:', error);

    if (!res.headersSent) {
      res.statusCode = 500;
      res.setHeader('Content-Type', 'application/json');
      res.end(
        JSON.stringify({
          success: false,
          message: 'Backend gagal melakukan inisialisasi.',
          detail:
            process.env.NODE_ENV === 'production'
              ? 'Periksa MONGODB_URI dan koneksi MongoDB Atlas di Vercel.'
              : error instanceof Error
                ? error.message
                : String(error),
        }),
      );
    }
  }
}