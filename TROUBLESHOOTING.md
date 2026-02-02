# Troubleshooting: self.plumoai.com connection timeout

**ERR_CONNECTION_TIMED_OUT** or **curl: Failed to connect** usually means traffic never reaches Traefik. Use this checklist.

---

## 1. Run the connectivity script on the server

```bash
cd /path/to/plumoai-self-hosted
chmod +x check-connectivity.sh
./check-connectivity.sh
```

- If **curl to 127.0.0.1** fails → Traefik/Docker issue (see step 2).
- If **curl to 127.0.0.1** works but browser still times out → firewall/DNS (see steps 3–4).

---

## 2. Docker and Traefik on the server

```bash
docker ps
docker port traefik
```

- `traefik` container must be **Up** and show ports `0.0.0.0:80->80/tcp`, `0.0.0.0:443->443/tcp`.
- If **No process listening on 80/443** or `docker port traefik` shows nothing: recreate Traefik so it gets port bindings:

```bash
cd /path/to/plumoai-self-hosted
docker compose up -d --force-recreate traefik
```

Then check again: `ss -tlnp | grep -E ':(80|443)'` and `curl -v http://127.0.0.1`.
- If not running: `docker compose up -d` (from the repo directory with `docker-compose.yml`).

From inside the server, test:

```bash
curl -v --connect-timeout 5 http://127.0.0.1
```

- If this works, Traefik is fine; the problem is network/firewall/DNS.

---

## 3. AWS Security Group (most common cause)

EC2 must allow **inbound** traffic on **80** and **443**.

1. AWS Console → **EC2** → **Instances** → select your instance.
2. **Security** tab → click the **Security group**.
3. **Edit inbound rules** → **Add rule**:
   - Type: **HTTP** → Port **80** → Source **0.0.0.0/0**
   - Type: **HTTPS** → Port **443** → Source **0.0.0.0/0**
4. Save.

Then from your laptop:

```bash
curl -v --connect-timeout 10 http://self.plumoai.com
```

(You may get a redirect to HTTPS; that’s OK.)

---

## 4. DNS

- **self.plumoai.com** must have an **A record** pointing to the **public IP** of your EC2 instance.
- Check: `nslookup self.plumoai.com` or `dig self.plumoai.com` — result should be that IP.

---

## 5. Gateway timeout (504) in browser but curl works from server

- **Cause:** Traefik cannot reach the backends (main-app, auth). Often because Traefik was on a different Docker network than main-app/auth.
- **Fix:** Ensure Traefik is on the same `internal` network as main-app and auth (see `docker-compose.yml`: `traefik` must have `networks: - internal`).
- Then on the server: `docker compose up -d --force-recreate traefik`.
- Check: `docker logs traefik` for "backend not found" or connection errors; `docker logs main-app` for app errors.

---

## 6. Why curl from inside the server to self.plumoai.com fails

When you run **on the server**:

```bash
curl http://self.plumoai.com
```

the server resolves `self.plumoai.com` to the **public IP**, so the connection goes **out** to the internet and back in. That path is blocked if the **Security Group** doesn’t allow 80/443. So:

- Use **http://127.0.0.1** (or **http://localhost**) on the server to verify Traefik.
- Fix **Security Group** and **DNS** so the outside world can reach the public IP on 80/443.

---

## 7. Auth DB init: "SUPER or SYSTEM_VARIABLES_ADMIN privilege(s)"

- **Cause:** The auth service runs `authdb.sql` as the app user (`plumoai_user`). That SQL uses statements that need root (e.g. `SET GLOBAL`, `DEFINER`), so MySQL returns "Access denied; you need (at least one of) the SUPER or SYSTEM_VARIABLES_ADMIN privilege(s)".
- **Fix:** Load the schema **once** as MySQL root, then restart auth so it sees existing tables and skips (or doesn’t re-run) the init.

**One-time on the server:**

```bash
cd ~/plumoai-self-hosted
chmod +x init-auth-db.sh
./init-auth-db.sh
docker compose restart auth
```

Or manually:

```bash
docker cp auth-service:/app/db_backups/authdb.sql ./
docker exec -i plumoai-mysql mysql -uroot -proot_disabled authdb_prod < ./authdb.sql
rm -f ./authdb.sql
docker compose restart auth
```

(Use the same root password as in `docker-compose.yml`: `MYSQL_ROOT_PASSWORD`.)

---

## Quick checklist

| Check | Command / action |
|-------|-------------------|
| Traefik running | `docker ps` → traefik Up, 80 and 443 mapped |
| Traefik responds locally | `curl -v http://127.0.0.1` (on server) |
| Ports open on instance | AWS Security Group: inbound 80, 443 from 0.0.0.0/0 |
| DNS | `self.plumoai.com` A record = EC2 public IP |
