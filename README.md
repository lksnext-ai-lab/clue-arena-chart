# clue-arena-app Helm chart
  <img src="./clue-logo.png" alt="Clue Arena logo" width="100" />

This chart deploys the Clue Arena application on Kubernetes with an app-focused
`values.yaml`. The exposed values map closely to Clue Arena runtime settings,
while the templates keep the Kubernetes wiring inside the chart.

## Chart summary

- Chart name: `clue-arena-app`
- Chart version: `1.0.2`
- App version: `1.0.1`
- Container port: `3000`

## Rendered resources

The current chart definition renders these Kubernetes resources:

- `Deployment` with `replicas: 1` and `strategy: Recreate`
- `ServiceAccount` with token automount disabled
- `Service` of type `ClusterIP`
- `ConfigMap` for non-secret application configuration
- Optional `Secret` when secret-backed values are provided
- Optional `Ingress` when `exposure.enabled=true`
- Optional `PersistentVolumeClaim` when persistence is enabled and no existing
  claim is supplied
- Helm test pod for connectivity checks

The `Deployment` includes startup, readiness, and liveness probes against
`/api/health`, runs the container as a non-root user, and mounts persistent
storage at `/app/data` when `app.database.persistence.enabled=true`.

## Runtime assumptions

- Clue Arena is currently deployed as a single writable replica because the
  default database is SQLite.
- The rollout strategy is intentionally `Recreate` to avoid concurrent writers
  against the same SQLite database file.
- Persistence is enabled by default through `app.database.persistence`.
- Runtime migrations run by default unless
  `app.database.skipMigrations=true`.

## Configuration model

The chart separates plain configuration from secrets:

- `ConfigMap`: public URL, websocket settings, log level, auth toggles, Firebase
  browser values, agent backend selection, and SQLite path
- `Secret`: Auth.js secret, Firebase admin credentials, MCP token, Gemini API
  key, and MattinAI API key

When `app.publicUrl` is empty and ingress is enabled, the chart derives the
public URL from `exposure.host`.

## Build-time note

Several `NEXT_PUBLIC_*` variables are embedded into the frontend at image build
time. This chart can still pass them as runtime environment variables for
server-side code, but it cannot rewrite an already built client bundle. The
application image should therefore be built with the same public URL and
Firebase browser settings that you intend to deploy.

## Values you will usually set

At minimum, review these values:

- `image.repository`
- `image.tag`
- `exposure.enabled`
- `exposure.host`
- `app.publicUrl`
- `app.auth.authSecret`
- `app.mcp.authToken`

Depending on the authentication mode, you may also need:

- `app.auth.disableAuth`
- `app.auth.demoMode`
- `app.auth.firebaseAuthProviders`
- `app.auth.firebaseClient.*`
- `app.auth.firebaseAdmin.projectId`
- `app.auth.firebaseAdmin.clientEmail`
- `app.auth.firebaseAdmin.privateKey`

For the local agent backend:

- `app.agents.backend=local`
- `app.agents.genkitModel`
- `app.agents.geminiApiKey`

For the MattinAI backend:

- `app.agents.backend=mattin`
- `app.agents.mattin.apiUrl`
- `app.agents.mattin.apiKey`

For persistence behavior:

- `app.database.persistence.enabled`
- `app.database.persistence.existingClaim`
- `app.database.persistence.size`
- `app.database.persistence.storageClassName`

## Sample values

```yaml
image:
  repository: ghcr.io/acme/clue-arena
  tag: "1.0.0"

exposure:
  enabled: true
  host: clue-arena.example.com
  ingressClassName: nginx
  tls:
    enabled: true
    secretName: clue-arena-tls

app:
  publicUrl: https://clue-arena.example.com
  logLevel: info

  auth:
    disableAuth: false
    demoMode: false
    trustHost: true
    authSecret: replace-me
    firebaseAuthProviders: password,google.com
    firebaseClient:
      apiKey: replace-me
      authDomain: clue-arena.firebaseapp.com
      projectId: clue-arena
      appId: 1:1234567890:web:replace-me
      messagingSenderId: "1234567890"
      storageBucket: clue-arena.appspot.com
    firebaseAdmin:
      projectId: clue-arena
      clientEmail: firebase-adminsdk@clue-arena.iam.gserviceaccount.com
      privateKey: "-----BEGIN PRIVATE KEY-----\\nreplace-me\\n-----END PRIVATE KEY-----\\n"

  mcp:
    authToken: replace-me

  agents:
    backend: local
    genkitModel: googleai/gemini-2.5-flash
    geminiApiKey: replace-me

  websocket:
    maxConnectionsPerSession: 5
    heartbeatIntervalMs: 30000

  database:
    filename: clue-arena.db
    skipMigrations: false
    persistence:
      enabled: true
      size: 5Gi
      storageClassName: standard
```

## Example install

```bash
helm upgrade --install clue-arena . \
  --namespace clue-arena \
  --create-namespace \
  --set image.repository=ghcr.io/acme/clue-arena \
  --set image.tag=1.0.0 \
  --set exposure.enabled=true \
  --set exposure.host=clue-arena.example.com \
  --set app.publicUrl=https://clue-arena.example.com \
  --set app.auth.authSecret=replace-me \
  --set app.mcp.authToken=replace-me
```

## CI expectations

The repository CI currently runs:

- `helm unittest .`
- `ct lint --config ct.yaml --charts .`
- `ct install --config ct.yaml --charts .`
- `helm test` on a Kind-installed release using [`ci/ct-values.yaml`](/home/jjrodrig/projects/cluedo-workspace/clue-arena-chart/ci/ct-values.yaml)

## Releases

The repository includes a release workflow at [`.github/workflows/release.yml`](/home/jjrodrig/projects/cluedo-workspace/clue-arena-chart/.github/workflows/release.yml).

It supports two entry points:

- Manual `workflow_dispatch`, where you provide the release version and optionally the application image repository.
- Automatic `repository_dispatch` from the app repository after a successful application release.

The manual dispatch also supports `republish_last_version=true`, which republishes the latest released chart into `gh-pages` without creating a new tag or GitHub Release. This is useful for reconciling the Helm repository metadata when the chart release already exists.

During a chart release, the workflow updates `Chart.yaml` to the requested version, validates the chart against the released application image, packages the chart, tags the repository, and creates a GitHub Release with the packaged chart attached.
