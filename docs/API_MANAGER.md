# API Manager

O `core/api_manager.py` mantém o **registro canônico** de APIs integradas ao
NEXUS. Regra absoluta: **nenhuma API ou endpoint é inventado** — toda entrada
corresponde a um serviço real com documentação oficial.

## Visualização

```bash
python nexus.py apis
```

```text
NEXUS API MANAGER
API                                STATUS
─────────────────────────────────  ──────────────
ipwho.is                           ENABLED
crt.sh                             ENABLED
RDAP                               ENABLED
CIRCL hashlookup                   ENABLED
AbuseIPDB                          NOT CONFIGURED
VirusTotal                         NOT CONFIGURED
...
```

## Campos de cada API

| Campo | Descrição |
|---|---|
| `name` | nome do serviço |
| `website` | site oficial |
| `documentation` | link da documentação oficial |
| `api_key_required` | se exige chave |
| `api_key_name` | nome da chave no Secret Store |
| `free_tier` | limite do plano gratuito |
| `rate_limit` | req/s recomendado |
| `supported_targets` | tipos de alvo atendidos |
| `enabled` | pode ser desabilitada |

## Como o status é calculado

1. `enabled == False` → `DISABLED`
2. não exige chave → `ENABLED`
3. exige chave e chave presente (env / Credential Manager / arquivo) → `ENABLED`
4. senão → `NOT CONFIGURED`

## Chaves suportadas

Lista canônica em `core/secret_store.py` → `SUPPORTED_KEYS`:

`ABUSEIPDB_API_KEY`, `VIRUSTOTAL_API_KEY`, `SECURITYTRAILS_API_KEY`,
`HUNTER_API_KEY`, `EMAILREP_API_KEY`, `IPQUALITYSCORE_API_KEY`,
`SHODAN_API_KEY`, `CENSYS_API_ID`, `CENSYS_API_SECRET`, `WHOISXML_API_KEY`,
`IPINFO_API_KEY`, `GOOGLE_SAFE_BROWSING_API_KEY`.

## Gerenciando chaves

```bash
python nexus.py keys set ABUSEIPDB_API_KEY        # Windows → Credential Manager
python nexus.py keys list                          # nunca mostra valores
python nexus.py keys delete VIRUSTOTAL_API_KEY
```

## Adicionando uma API nova

1. Confirme que o serviço existe e documenta a API publicamente.
2. Crie o plugin correspondente (veja `docs/PLUGINS.md`).
3. Adicione o `ApiDefinition` no `API_REGISTRY` (com `website`, `documentation`
   e `free_tier` reais).
4. Adicione o nome da chave em `SUPPORTED_KEYS` (se exigir chave).
5. Escreva testes e rode `pytest -v`.
