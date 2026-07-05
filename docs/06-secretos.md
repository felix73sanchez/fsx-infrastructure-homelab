# Gestión de Secretos

Varios servicios requieren tokens, contraseñas o claves que **no deben
estar en texto plano en el repositorio**.

## Secretos Actuales

| Variable | Servicio | Dónde se usa |
|---|---|---|
| `cloudflare_tunnel_token` | Cloudflare Tunnel | `templates/docker-services/nginx/env.j2` |
| `pihole_webpassword` | Pi-hole admin | `templates/docker-services/pihole/docker-compose.yml.j2` |
| `ma_tours_db_password` | MA Tours PostgreSQL | `templates/docker-services/ma-tours/env.j2` |
| `portfolio_jwt_secret` | Portfolio JWT | `templates/docker-services/portfolio-fsx-nxt/env.j2` |
| `portfolio_invitation_code` | Portfolio admin | `templates/docker-services/portfolio-fsx-nxt/env.j2` |

## Opción 1: --extra-vars (Rápido)

Para tests o deploys manuales:

```bash
ansible-playbook playbooks/docker-services.yml \
  --extra-vars 'cloudflare_tunnel_token=eyJ...' \
  --extra-vars 'pihole_webpassword=admin123' \
  --extra-vars 'ma_tours_db_password=mySecurePass42' \
  --extra-vars 'portfolio_jwt_secret=8HPuQm2y4jOhyUK535er7RLi4kDpJzF7...' \
  --extra-vars 'portfolio_invitation_code=99b023e3-db37-41ee-8c14-e5e616701191'
```

**Ventaja**: Simple, no requiere setup.
**Desventaja**: Los secretos quedan en el historial del shell.

## Opción 2: ansible-vault (Recomendado)

### Crear el vault

```bash
ansible-vault create group_vars/vault.yml
```

Contenido del vault:

```yaml
cloudflare_tunnel_token: "eyJ..."
pihole_webpassword: "admin123"
ma_tours_db_password: "mySecurePass42"
portfolio_jwt_secret: "8HPuQm2y4j..."
portfolio_invitation_code: "99b023e3-..."
```

### Usar el vault

```bash
# Pide la contraseña del vault
ansible-playbook playbooks/docker-services.yml --ask-vault-pass

# O con archivo de password (no committees este archivo)
ansible-playbook playbooks/docker-services.yml --vault-password-file ~/.vault_pass
```

### Variables vault en templates

Ansible mergea automáticamente `group_vars/vault.yml` con el resto,
así que los templates existentes funcionan sin cambios.

**Importante**: Agregá `*.vault` al `.gitignore` (ya está).

## Opción 3: Variables de Entorno

Podés definir las variables en tu shell y usar `--extra-vars` desde ahí:

```bash
export CLOUDFLARE_TUNNEL_TOKEN="eyJ..."

ansible-playbook playbooks/docker-services.yml \
  --extra-vars "cloudflare_tunnel_token=$CLOUDFLARE_TUNNEL_TOKEN"
```

## Generar Secretos Seguros

```bash
# Token JWT (64 chars aleatorios)
openssl rand -base64 48

# UUID para invitation code
uuidgen

# Password para DB
openssl rand -base64 32

# Cloudflare tunnel token
# Generar desde: https://one.dash.cloudflare.com → Networks → Tunnels
```

## Buenas Prácticas

1. **Nunca** committees un `.env` con secretos reales
2. Usá `ansible-vault` para producción
3. Rotá los secretos periódicamente
4. Cada servicio debería tener su propio secreto (no reuses)
5. `.env.example` files en los templates documentan qué se necesita
