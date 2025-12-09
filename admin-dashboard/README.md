# Admin Dashboard - API Base URL Configuration

The admin dashboard talks to the backend via a configurable base URL.
To avoid accidental calls to localhost in production, always set VITE_API_BASE_URL.

## Quick start

1) Install dependencies

```
yarn
# or
npm install
```

2) Create a .env file with your API base URL

- Local development (runs the backend on localhost):

```
# .env.development
VITE_API_BASE_URL=http://localhost:5000/api
```

- Production / Staging (Render deployment):

```
# .env.production
VITE_API_BASE_URL=https://music-app-backend-aijn.onrender.com/api
```

You can also set VITE_API_BASE_URL in your deployment provider’s environment settings.

3) Start the dashboard

```
yarn dev
# or
npm run dev
```

## Behavior when VITE_API_BASE_URL is missing

- In development: the app falls back to http://localhost:5000/api and prints a console warning.
- In production builds: the app will throw at startup to prevent accidentally using the wrong backend.

See src/api/api.js for details.

## Align with the Flutter app

The Flutter client uses:

```
ApiConstants.baseUrl = "https://music-app-backend-aijn.onrender.com/api"
```

Be sure the admin dashboard VITE_API_BASE_URL points to the same environment as Flutter to keep data consistent.

## Test matrix

Please verify these core flows against your chosen backend environment:
- Admin login
- Manage users (list, delete)
- Manage songs (list)
- Manage reports (list, grouped, delete)

Test both:
- Local: VITE_API_BASE_URL=http://localhost:5000/api
- Render: VITE_API_BASE_URL=https://music-app-backend-aijn.onrender.com/api
