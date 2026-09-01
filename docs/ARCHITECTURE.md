# Arquitetura

## Visão geral

O NEXUS é um CLI Python modular em camadas:

```
┌──────────────────────────────────────────────┐
│  cli/  (argparse + menu interativo + output) │
├──────────────────────────────────────────────┤
│  core/engine.py  (orquestração assíncrona)   │
│    ├─ dispatcher (seleção de plugins)        │
│    ├─ plugin_manager (descoberta)            │
│    ├─ rate_limiter · cache · logger · config │
│    └─ secret_store · api_manager             │
├──────────────────────────────────────────────┤
│  plugins/  (integrações — isoladas do núcleo)│
├──────────────────────────────────────────────┤
│  database/ (SQLite) · reports/ (json/csv/…)  │
└──────────────────────────────────────────────┘
```

**Princípio central:** o núcleo não depende de nenhuma API específica. Cada
integração é um plugin com contrato estável (`NexusPlugin`).

## Fluxo de um scan

1. `nexus.py scan --target X [--type T]`
2. `Dispatcher.resolve_target` → normaliza o alvo e resolve o tipo
   (detecção automática **ou** tipo forçado).
3. `PluginManager` (já descoberto) filtra plugins por `target_types`.
4. A `Engine` executa os plugins com `asyncio.gather` + semáforo:
   - rate limit global e por plugin (`AsyncRateLimiter`/token bucket);
   - timeout por plugin (`asyncio.wait_for`);
   - retry com exponential backoff (`1s, 2s, 4s` — configurável);
   - cache por `(plugin, target)` com TTL (`Cache`, SQLite);
   - isolamento: exceções viram `plugin_status[plugin] = ERROR`.
5. Resultados passam pelo `deduplicator` (agrupamento por chave canônica,
   merge de fontes, agregação de confiança).
6. `Database.save_scan` persiste cabeçalho + resultados.
7. `ScanResult.to_dict()` alimenta a CLI e os relatórios.

## Contrato de plugin

```python
class NexusPlugin:
    name: ClassVar[str]
    version: ClassVar[str]
    description: ClassVar[str]
    author: ClassVar[str]
    target_types: ClassVar[list[str]]
    requires_api_key: ClassVar[str | None]
    rate_limit: ClassVar[float]
    timeout: ClassVar[float]

    async def setup(self) -> None: ...      # opcional
    async def execute(self, target, context=None) -> list[PluginResult]: ...
    async def teardown(self) -> None: ...   # opcional
```

`PluginResult` carrega `result_type`, `data`, `source`, `confidence`,
`status`, `raw`, `duration`.

## Status

`SUCCESS` · `NO_RESULTS` · `SKIPPED` · `RATE_LIMITED` · `TIMEOUT` · `ERROR` · `NOT_CONFIGURED`

## Confiança

- `CONFIRMED` — validação determinística/offline (ex.: E.164, formato).
- `HIGH` — observado em fonte primária (ex.: registro DNS, resposta 200).
- `MEDIUM` — inferência razoável (ex.: tecnologia inferida de MX).
- `LOW` — ambíguo/indeterminado (ex.: serviços que respondem 200 sempre).

## Cache

SQLite (`data/cache.db`), chave = SHA-256 de `(namespace, plugin, target)`,
TTL por plugin (padrão 24 h), remoção LRU quando excede `max_cache_size`.
Config: `cache_enabled`, `cache_ttl`, `max_cache_size`.

## Rate limiting

Token bucket por plugin + limiter global. Config:
`rate_limit_per_second` (preset) ou `rate_limit` do plugin.

## Segredos

`core/secret_store.py` — prioridade:

1. Windows Credential Manager via DPAPI (ctypes → `CredReadW`/`CredWriteW`);
2. variáveis de ambiente;
3. `config/api_keys.json` (somente dev; permissões 600; gitignored).

Logs redigem `api_key=...`, `token=...`, `Bearer ...`.

## Banco de dados

SQLite (stdlib). Tabelas: `scans`, `scan_results`, `schema_version`.
Migrações idempotentes em `database/migrations.py`.

## Roadmap

- **V1** — core + primeiros plugins ✅
- **V2** — mais APIs (via plugins, sem tocar no núcleo)
- **V3** — correlação de resultados entre plugins
- **V4** — dashboard web
- **V5** — marketplace/ecossistema de plugins
