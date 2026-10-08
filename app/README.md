# Tracker frontend

Angular 21, TypeScript, Tailwind, Angular Material, and Axios. Run `npm ci` then `npm start`; build with `npm run build`. The package and Angular project are `tracker`, and the production output is `dist/tracker/browser`.

The API base defaults to `/api`. The development proxy targets `http://127.0.0.1:8080`, stripping the prefix; production Nginx proxies the same prefix to the backend. Optional `TRACKER_API_BASE_URL` configuration honors process environment ahead of `.env`.

See the monorepo [README](../README.md) for backend, deployment, model training, and verification instructions.
