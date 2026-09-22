# Kopia Repository Server — Deploy and Host

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/kopia)

# Deploy and Host

[![Deploy on Railway](https://railway.app/button.svg)](https://railway.com/deploy/kopia)

Kopia is a fast and secure open-source backup tool. This template deploys a **Kopia Repository Server** on Railway — a central server that stores backups from all your machines, with a built-in web UI and per-user access control.

## About Hosting

Kopia runs as a single container on port 51515. Railway provides compute, TLS at the edge, and a public URL. The repository (encrypted backup data), cache, and logs live at `/app` — a Railway Volume keeps them persistent across restarts and redeploys.

On first deploy, the entrypoint creates the filesystem repository automatically. The web UI and API are protected by basic auth (`KOPIA_SERVER_USERNAME` / `KOPIA_SERVER_PASSWORD`).

## Why Deploy

- **Central backup hub** — One server stores encrypted, deduplicated, compressed backups from every machine you own.
- **Web UI included** — Manage snapshots, policies, and users from the browser.
- **Per-user isolation** — Each user sees only their own snapshots via server-managed accounts.
- **Client-side encryption** — Data is encrypted before it leaves your machines; the server never sees plaintext.
- **Deduplication & compression** — Identical data across machines is stored once, saving storage and bandwidth.
- **Scheduled snapshots** — Clients run on cron/systemd and push automatically.
- **No vendor lock-in** — The repository is a standard Kopia filesystem repo; move it anywhere.
- **Lightweight** — ~80MB image, minimal RAM at idle.

## Common Use Cases

- **Laptop fleet backups** — Point every laptop's Kopia client at your server.
- **Server backups** — Nightly snapshots of app servers, databases dumps, and config trees.
- **Family backups** — Isolated per-user accounts with one shared storage location.
- **Home lab** — Central backup target for NAS, Raspberry Pis, and workstations.
- **Off-site copy** — A Railway-hosted repo as the second copy of an on-prem backup.

## Dependencies for Kopia

### Deployment Dependencies

- **Volume (required)** — A Railway Volume must be mounted at `/app`. The repository, cache, and logs all live there. Without it, every restart loses all backup data.
- **No external services** — Kopia uses its own filesystem repository format. No companion database, cache, or queue is needed.
- **Client software** — Machines backing up to this server need the Kopia CLI or KopiaUI installed locally.

## Configuration

| Variable | Description |
|----------|-------------|
| `KOPIA_PASSWORD` | Repository password (encrypts the backup repository). Generated once on first deploy. |
| `KOPIA_SERVER_PASSWORD` | Web UI / API basic-auth password. Generated on deploy. |
| `KOPIA_SERVER_USERNAME` | Web UI / API basic-auth username (default `kopia`). |
| `PORT` | HTTP listen port (default `51515`, matches Railway's routing). |

### Connect a client

On each machine you want to back up, install Kopia and connect to the server:

```bash
kopia repository connect server \
  --url=https://YOUR-SERVER.up.railway.app \
  --override-username=user@laptop \
  --override-hostname=laptop
```

The server admin adds the user first via the web UI or `kopia server user add user@laptop`.

### Snapshots

Once connected, take snapshots:

```bash
kopia snapshot create /home/user/documents
```

## FAQ

### How do I add users?

Open the web UI (basic auth with `KOPIA_SERVER_USERNAME`/`KOPIA_SERVER_PASSWORD`), or run `kopia server user add user@hostname` from a connected admin client. Each user gets their own snapshot space.

### Where is my data stored?

All repository data lives at `/app/repository` on the Railway Volume, encrypted with `KOPIA_PASSWORD`. Railway never sees plaintext backup contents.

### Can I use S3/B2/GCS storage instead of the volume?

Yes. Replace the `repository create filesystem` call in `entrypoint.sh` with `repository create s3` (or any supported provider) and connect the server to it. The volume then only holds cache and config.

### What happens if the volume isn't mounted?

Without a volume the repository is recreated empty on every restart — all backups would be lost. The volume is required.

### Is the connection encrypted?

Yes, twice: Railway terminates TLS at the edge, and Kopia's repository-level encryption protects data end-to-end — content is encrypted on the client before upload.

### How do I restore a backup?

From any connected client: `kopia snapshot list` then `kopia restore <snapshot-id> /restore/target`. Mounting is also supported: `kopia mount <snapshot-id> /mnt/restore`.
