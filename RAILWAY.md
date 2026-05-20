## Railway Deploy

This project is ready to deploy on Railway as a single Node service that serves:

- the web app from `public-web`
- the API from `server/serve.js`
- SQLite from a persistent volume

### Required Railway settings

1. Deploy the repo to Railway.
2. Add a Volume and mount it to:
   `/data`
3. Add this environment variable:
   `DB_PATH=/data/db.sqlite`

### Commands

Railway will use:

- build: `npm install`
- start: `npm start`

These are already defined in:

- `railway.json`
- `package.json`
