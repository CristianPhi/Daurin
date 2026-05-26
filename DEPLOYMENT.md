# Deployment Guide

This project is set up to run the backend on Render and point the Flutter client at the deployed backend URL.

## Backend

Use the existing `render.yaml` in the repo root with these values:

- Service type: `web`
- Name: `daurin-backend`
- Root directory: `backend`
- Build command: `npm ci && npm run build`
- Start command: `npm run start:prod`
- Auto deploy: enabled

Required environment variables on Render:

- `MONGODB_URI` - your MongoDB Atlas connection string
- `PORT` - Render will provide this automatically, so do not hardcode it

After deploy, Render will give you a public URL such as `https://daurin-backend.onrender.com`.

## Flutter Client

The client already supports a production backend URL through `API_BASE_URL` in `client/lib/api_client.dart`.

Build the APK with the production backend URL like this:

```bash
flutter build apk --dart-define=API_BASE_URL=https://daurin-backend.onrender.com
```

If you are testing locally instead:

- Android emulator: `http://10.0.2.2:3000`
- Physical device via USB: run `adb reverse tcp:3000 tcp:3000`
- Physical device on the same Wi-Fi: use your laptop LAN IP, for example `http://192.168.1.20:3000`

## Database

The backend uses MongoDB Atlas, so the database can stay online without running anything on your laptop.

You only need to make sure:

- the Atlas cluster is running
- the IP allowlist includes the Render backend or is temporarily open during setup
- `MONGODB_URI` in Render points to the Atlas cluster

## Quick Check

After deploy, open the backend root endpoint in a browser:

```text
https://daurin-backend.onrender.com/
```

You should get a response like:

```json
{"message":"Daurin backend is running"}
```