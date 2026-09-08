const { createApp } = require('../dist/bootstrap');

let cachedHandler;

async function getHandler() {
  if (!cachedHandler) {
    const app = await createApp();
    await app.init();
    cachedHandler = app.getHttpAdapter().getInstance();
  }

  return cachedHandler;
}

module.exports = async function handler(req, res) {
  try {
    const expressHandler = await getHandler();
    return expressHandler(req, res);
  } catch (error) {
    console.error('Failed to initialize Vercel function:', error);
    res.statusCode = 500;
    res.setHeader('Content-Type', 'application/json');
    return res.end(
      JSON.stringify({
        success: false,
        message: 'Backend gagal melakukan inisialisasi.',
      }),
    );
  }
};