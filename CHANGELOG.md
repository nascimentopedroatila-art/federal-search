# Changelog

Todas as mudanças relevantes do NEXUS são documentadas neste arquivo.

O formato segue [Keep a Changelog](https://keepachangelog.com/pt-BR/1.1.0/)
e o projeto adere ao [Versionamento Semântico](https://semver.org/lang/pt-BR/).

## [1.0.0] — 2026-09-01

### Adicionado

- **Core engine** assíncrona (`core/engine.py`): `asyncio` + `httpx`, semáforo de
  concorrência, rate limiting global/por plugin, timeouts, retry com exponential
  backoff, cache de resultados e isolamento de falhas (um plugin com erro não
  interrompe o scan).
- **Sistema de plugins** (`core/plugin.py`, `core/plugin_manager.py`): descoberta
  automática em `plugins/`, metadados declarativos (`name`, `version`,
  `description`, `author`, `target_types`, `requires_api_key`, `rate_limit`,
  `timeout`) e registro programático.
- **CLI** (`cli/`): `scan`, `menu`, `plugins`, `apis`, `history`, `export`,
  `keys`, `config`, `diag`, `selfcheck`, `--version`.
- **Target Detector** (`core/target_detector.py`): detecção automática de
  phone, email, username, domain, ip, url e hash; `--type` manual é respeitado.
- **Plugins V1**: Phone Validator (offline), Email Analyzer, Username Presence,
  Domain Intelligence, IP Intelligence, DNS Records, Hash Analyzer,
  Network Diagnostics.
- **API Manager** (`core/api_manager.py`): registro canônico de 15 APIs reais e
  documentadas; status `ENABLED`/`NOT CONFIGURED`/`DISABLED`.
- **Secret Store** (`core/secret_store.py`): Windows Credential Manager (DPAPI) →
  variáveis de ambiente → arquivo local restrito (apenas dev).
- **Banco SQLite** (`database/`): tabelas `scans` e `scan_results`, migrações,
  histórico e estatísticas.
- **Relatórios** (`reports/`): JSON, CSV, TXT e HTML autossuficiente com Target,
  Target Type, Scan Time, Plugins, Results, Sources, Confidence, Errors,
  Statistics e Timeline.
- **Cache** (`core/cache.py`): SQLite com TTL e remoção LRU.
- **Rate limiter** (`core/rate_limiter.py`): token bucket síncrono e assíncrono.
- **Dedup + Confidence** (`core/deduplicator.py`): agrupamento de resultados
  idênticos de fontes diferentes, agregação de confiança e estatísticas.
- **Configuração** (`core/config.py`): `config/config.json` + presets
  `LOW`, `BALANCED`, `PERFORMANCE`, `CUSTOM` + override por env `NEXUS_*`.
- **Logging** (`core/logger.py`): `logs/nexus.log`, `logs/scans.log`,
  `logs/plugins.log`, `logs/errors.log`, com redação automática de secrets.
- **Scripts Windows 11** (`scripts/`): `install.ps1`, `start.ps1`, `update.ps1`;
  atalho `NEXUS.bat`.
- **GitHub**: workflow CI (testes em Linux/Windows × Python 3.12/3.13, lint
  com ruff, `compileall`, build), badges no README.
- **Documentação**: README, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`,
  `SECURITY.md`, `docs/` (INSTALL, USAGE, PLUGINS, ARCHITECTURE, API_MANAGER,
  SECURITY, ETHICS, GITHUB).
- **Testes automatizados** (130+ casos, offline com mocks): target detector,
  normalização, plugins, API manager, rate limiter, cache, deduplicação, banco,
  exportação, CLI, engine e tratamento de erros.

### Segurança

- Chaves de API nunca são armazenadas em código, impressas em logs ou
  commitadas (`.gitignore` cobre `.env`, `config/api_keys.json`, `data/`, `logs/`).
- Arquivo local de chaves criado com permissões restritas (owner-only).

### Ética

- Nenhuma integração inventada: todas as APIs listadas possuem documentação
  oficial e tier gratuito verificado.
- Sem ataques ativos, sem bypass de CAPTCHA/autenticação, sem quebra de senhas.

## [Não publicado]

- V2: mais integrações com chave (planejamento aberto).
- V3: correlação entre resultados de plugins distintos.
- V4: dashboard web.
- V5: marketplace/ecossistema de plugins.
