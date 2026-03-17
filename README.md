# clue-arena-app Helm chart

This chart deploys `clue-arena-app` to Kubernetes with an app-first
`values.yaml`. The templates keep the Kubernetes implementation details inside
the chart so a system administrator mainly edits Clue Arena settings instead of
raw Kubernetes internals.

## What it includes

- A `Deployment` exposing the app on port `3000`
- Health probes against `/api/health`
- A `Service` for in-cluster access
- Optional `Ingress`
- Optional `PersistentVolumeClaim` for the SQLite database at `/app/data`
- Chart-managed `ConfigMap` and `Secret`

## Important runtime assumptions

- The app currently uses SQLite by default, so the chart is intentionally
  single-replica and uses a `Recreate` rollout strategy internally.
- Persistence is enabled by default through `app.database.persistence`.
- The container entrypoint runs runtime database migrations unless
  `app.database.skipMigrations=true`.

## Important build-time note

Several `NEXT_PUBLIC_*` variables are baked into the frontend when the Docker
image is built. This chart can pass those values at runtime for server-side
code, but it cannot rewrite a prebuilt client bundle. In practice that means
your image should already be built with the same public URL and Firebase values
you plan to deploy.

## Values you will usually set

At minimum, review these:

- `image.repository`
- `image.tag`
- `exposure.enabled`
- `exposure.host`
- `app.publicUrl`
- `app.auth.authSecret`
- `app.mcp.authToken`

Depending on your authentication mode, you may also need:

- `app.auth.disableAuth`
- `app.auth.firebaseClient.*`
- `app.auth.firebaseAdmin.projectId`
- `app.auth.firebaseAdmin.clientEmail`
- `app.auth.firebaseAdmin.privateKey`

For local-agent mode:

- `app.agents.backend=local`
- `app.agents.genkitModel`
- `app.agents.geminiApiKey`

For MattinAI mode:

- `app.agents.backend=mattin`
- `app.agents.mattin.apiUrl`
- `app.agents.mattin.apiKey`

## Example install

```bash
helm upgrade --install clue-arena ./clue-arena-chart \
  --namespace clue-arena \
  --create-namespace \
  --set image.repository=ghcr.io/acme/clue-arena-app \
  --set image.tag=1.0.0 \
  --set exposure.enabled=true \
  --set exposure.host=clue-arena.example.com \
  --set app.publicUrl=https://clue-arena.example.com \
  --set app.auth.authSecret=replace-me \
  --set app.mcp.authToken=replace-me
```
