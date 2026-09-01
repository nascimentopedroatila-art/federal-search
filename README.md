# 🔗 NEXUS — Modular Intelligence Toolkit

[![CI](https://github.com/nascimentopedroatila-art/federal-search/actions/workflows/ci.yml/badge.svg)](https://github.com/nascimentopedroatila-art/federal-search/actions/workflows/ci.yml)
[![Python](https://img.shields.io/badge/Python-3.12%2B-3776AB?logo=python&logoColor=white)](https://www.python.org/downloads/)
[![Platforms](https://img.shields.io/badge/Windows%2011-Linux-macOS-Termux-0078D6?logo=windows)](https://github.com/nascimentopedroatila-art/federal-search)
[![License](https://img.shields.io/github/license/nascimentopedroatila-art/federal-search)](LICENSE)
[![Version](https://img.shields.io/badge/version-2.0.0-blue)](CHANGELOG.md)
[![Tests](https://img.shields.io/badge/tests-140%2B%20passing-brightgreen)](https://github.com/nascimentopedroatila-art/federal-search/actions/workflows/ci.yml)
[![Plugins](https://img.shields.io/badge/plugins-16-orange)](docs/PLUGINS.md)
[![PRs Welcome](https://img.shields.io/badge/PRs-welcome-brightgreen.svg)](CONTRIBUTING.md)

> **OSINT legítimo • Análise de infraestrutura pública • Diagnóstico de rede • Automação de consultas a APIs autorizadas**

O **NEXUS** é uma ferramenta profissional, modular e extensível de linha de comando para inteligência de código aberto (OSINT), análise de infraestrutura pública, diagnóstico de redes próprias e consultas a APIs públicas autorizadas.

---

## 🚨 Aviso ético e legal

O NEXUS foi criado **exclusivamente** para:

- OSINT legítimo sobre **fontes públicas**;
- análise dos **seus próprios dados**;
- auditorias **autorizadas**;
- diagnóstico de **redes próprias**;
- análise defensiva e pesquisa de infraestrutura pública.

O NEXUS **não** implementa (e nunca implementará): invasão de contas, quebra de senhas, credential stuffing, bypass de CAPTCHA ou autenticação, exploração automática contra terceiros, acesso a bases privadas, uso de dados vazados, malware, persistência, exfiltração ou ocultação de atividade maliciosa. Respeite os termos de serviço, os limites de API e as políticas de acesso das fontes utilizadas. O uso indevido é de responsabilidade exclusiva do usuário. Veja [SECURITY.md](SECURITY.md) e [docs/ETHICS.md](docs/ETHICS.md).

---

## ✨ Características

- **CLI profissional** — comando direto (`python nexus.py scan --target example.com`) **e** menu interativo (`python nexus.py menu`);
- **Scan múltiplo** — vários alvos em paralelo com `python nexus.py scan --targets alvo1,alvo2,alvo3`;
- **Detector automático de alvos** — telefone, e-mail, domínio, IP, URL, username e hash; tipo manual respeitado com `--type`;
- **Sistema de plugins** — plugins descobertos automaticamente em `plugins/`, sem alterar o núcleo;
- **Engine assíncrona** — `asyncio` + `httpx`, semáforos, rate limiting, timeouts, retry com *exponential backoff*, cache;
- **API Manager** — registro central de APIs reais e documentadas (nada é inventado), com status por configuração;
- **Segurança de chaves** — Windows Credential Manager (DPAPI) → variáveis de ambiente → arquivo local apenas em dev;
- **Banco SQLite** — histórico de scans (`python nexus.py history`);
- **Relatórios** — JSON, CSV, TXT e HTML autossuficiente (`python nexus.py export --scan <ID> --format html`);
- **Dedup + confiança** — resultados de fontes diferentes agrupados, com `LOW/MEDIUM/HIGH/CONFIRMED` e fontes sempre visíveis;
- **Diagnóstico local** — interfaces, gateway, DNS configurado, memória, CPU (offline);
- **Pronto para Windows 11** — `install.ps1`, `start.ps1`, `update.ps1`, `NEXUS.bat`;
- **GitHub-ready** — CI (testes, lint, sintaxe, build), badges, `SECURITY.md`, `CONTRIBUTING.md`, `CODE_OF_CONDUCT.md`.

---

## 📋 Requisitos

| Requisito | Mínimo |
|---|---|
| Sistema | Windows 11 (prioridade) · Linux · macOS · Termux |
| Python | **3.12+** (funciona em 3.11 com aviso) |
| RAM | 8 GB (usa mais recursos quando disponíveis) |
| Docker | **Não é necessário** |

---

## 🚀 Instalação

### Windows 11 (PowerShell)

```powershell
git clone https://github.com/nascimentopedroatila-art/federal-search.git
cd federal-search

.\scripts\install.ps1        # cria .venv, instala dependências, roda selfcheck
.\scripts\start.ps1          # abre o menu interativo
```

Ou, sem clone: baixe o ZIP e execute `install.ps1` dentro da pasta.

Atalho rápido: **`NEXUS.bat`** (usa o `.venv` se existir):

```bat
NEXUS.bat
NEXUS.bat scan --target example.com
```

### Linux / macOS / Termux

```bash
git clone https://github.com/nascimentopedroatila-art/federal-search.git
cd federal-search
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
python nexus.py selfcheck
```

### Atualizar

```powershell
.\scripts\update.ps1     # Windows
git pull && pip install -r requirements.txt   # outros SO
```

---

## 🧑‍💻 Uso

```bash
# Scan com detecção automática do tipo de alvo
python nexus.py scan --target example.com
python nexus.py scan --target 8.8.8.8
python nexus.py scan --target user@example.com
python nexus.py scan --target +5585999999999
python nexus.py scan --target d41d8cd98f00b204e9800998ecf8427e
python nexus.py scan --target https://example.com

# Scan múltiplo (V2): vários alvos em paralelo
python nexus.py scan --targets "+5585999999999,8.8.8.8,user@example.com"

# Tipo manual (sempre respeitado)
python nexus.py scan --target "exemplo de username" --type username

# Filtro de plugins
python nexus.py scan --target example.com --plugins "Domain Intelligence"

# Saída JSON pura / sem gravar no banco
python nexus.py scan --target 8.8.8.8 --json --no-db

# Menu interativo
python nexus.py menu

# Gerenciamento
python nexus.py plugins
python nexus.py apis
python nexus.py history
python nexus.py config --show
python nexus.py config --preset PERFORMANCE
python nexus.py diag
python nexus.py diag --host 1.1.1.1
python nexus.py selfcheck
python nexus.py keys list
python nexus.py keys set ABUSEIPDB_API_KEY
python nexus.py keys delete VIRUSTOTAL_API_KEY

# Relatórios
python nexus.py export --scan <SCAN_ID> --format json
python nexus.py export --scan <SCAN_ID> --format csv
python nexus.py export --scan <SCAN_ID> --format html
python nexus.py export --scan <SCAN_ID> --format txt
```

### Exemplo real de execução

```text
$ python nexus.py scan --target +5585999999999

╔══════════════════════════════════════════╗
║              N E X U S                   ║
║       Modular Intelligence Toolkit       ║
╚══════════════════════════════════════════╝

Target       : +5585999999999
Type         : phone
Scan ID      : 28d80fa17ad1
Status       : SUCCESS

Plugin               Status
───────────────────  ───────
Network Diagnostics  SUCCESS
Phone Validator      SUCCESS

Results (2)
Plugin               Type        Data                    Source                                 Confidence
───────────────────  ──────────  ──────────────────────  ─────────────────────────────────────  ──────────
Phone Validator      VALIDATION  normalized=+55859999..  phonenumbers (dados públicos offline)  CONFIRMED
```

> As consultas a APIs externas dependem de conectividade. Sem rede, os plugins retornam `ERROR`/`NO RESULTS` — nunca resultados falsos.

---

## 🔌 Plugins

Cada plugin em `plugins/<categoria>/plugin.py` declara metadados e implementa `execute()`:

```python
from core.plugin import NexusPlugin, PluginResult

class MeuPlugin(NexusPlugin):
    name = "Meu Plugin"
    version = "1.0"
    description = "..."
    author = "você"
    target_types = ["domain"]
    requires_api_key = None        # ou "MINHA_CHAVE"
    rate_limit = 5.0
    timeout = 15.0

    async def execute(self, target, context=None):
        return [PluginResult(result_type="info", data={...}, source="fonte", confidence="MEDIUM")]
```

**Adicionar um plugin não exige nenhuma alteração no núcleo.** Basta criar a pasta e rodar `python nexus.py plugins`. Veja [docs/PLUGINS.md](docs/PLUGINS.md).

### Plugins incluídos (16 na V2)

**Sem chave de API:**

| Plugin | Tipos | Descrição |
|---|---|---|
| Phone Validator | phone | validação, país, região, operadora, tipo de linha (offline) |
| Username Presence | username | presença pública (GitHub, GitLab, X, Reddit, Instagram, Telegram, Mastodon) |
| Domain Intelligence | domain | DNS completo, WHOIS (RDAP), certificados (crt.sh), tecnologias, subdomínios |
| DNS Records | domain | A, AAAA, MX, NS, TXT, CNAME, SOA, CAA |
| Network Diagnostics | todos | diagnóstico local e conectividade TCP básica |

**Com API key (opcional — respondem `NOT CONFIGURED` sem chave):**

| Plugin | Tipos | Fonte |
|---|---|---|
| Email Analyzer | email | formato, MX, DNS, SPF/DMARC + emailrep.io |
| IP Intelligence | ip | ipwho.is, RDAP, DNS reverso + AbuseIPDB |
| Hash Analyzer | hash | identificação + CIRCL hashlookup + VirusTotal |
| Safe Browsing URL Check | url | Google Safe Browsing v4 |
| IPQualityScore URL Scan | url | IPQualityScore URL Scanner |
| IPQualityScore IP | ip | IPQualityScore IP Scoring |
| VirusTotal IP | ip | VirusTotal v3 |
| VirusTotal Domain | domain | VirusTotal v3 |
| SecurityTrails Subdomains | domain | SecurityTrails v1 |
| Hunter Domain Search | domain | Hunter.io v2 |
| EmailRep.io IP | ip | emailrep.io |

---

## 🔑 APIs

O NEXUS **nunca inventa APIs ou endpoints**. Todas as integrações usam documentação oficial:

| API | Chave | Tier gratuito | Tipos |
|---|---|---|---|
| [ipwho.is](https://ipwho.is/) | — | sem chave | ip |
| [crt.sh](https://crt.sh/) | — | aberto | domain |
| [RDAP (rdap.org)](https://rdap.org/) | — | aberto (IANA) | domain, ip |
| [CIRCL hashlookup](https://hashlookup.circl.lu/) | — | aberto | hash |
| [AbuseIPDB](https://docs.abuseipdb.com/) | sim | 1.000/dia | ip |
| [VirusTotal](https://developers.virustotal.com/reference) | sim | 500/dia | domain, ip, hash, url |
| [emailrep.io](https://docs.emailrep.io/) | sim | gratuito | email |
| [IPQualityScore](https://www.ipqualityscore.com/documentation/) | sim | 5.000/mês | ip, email, url |
| [SecurityTrails](https://docs.securitytrails.com/) | sim | 50/mês | domain, ip |
| [Hunter.io](https://hunter.io/api-documentation) | sim | 25/mês | domain, email |
| [Shodan](https://developer.shodan.io/api) | sim | gratuito | ip, domain |
| [Censys](https://search.censys.io/api) | sim | gratuito | ip, domain, hash |
| [WHOIS XML](https://whois.whoisxmlapi.com/documentation/making-requests) | sim | 500/mês | domain, ip |
| [ipinfo.io](https://ipinfo.io/developers) | sim | 50.000/mês | ip, domain |
| [Google Safe Browsing](https://developers.google.com/safe-browsing/v4) | sim | 10.000/dia | url, domain, ip |

Status: `python nexus.py apis` → `ENABLED` / `NOT CONFIGURED` / `DISABLED`. Detalhes em [docs/API_MANAGER.md](docs/API_MANAGER.md).

### Armazenamento seguro de chaves (prioridade)

1. **Windows Credential Manager (DPAPI)** — preferencial:
   ```powershell
   python nexus.py keys set ABUSEIPDB_API_KEY
   ```
2. **Variáveis de ambiente** — portátil (Linux/macOS/Termux/CI):
   ```bash
   export ABUSEIPDB_API_KEY="..."
   ```
3. **`.env` / arquivo local** — apenas desenvolvimento (ver `.env.example`; `.env` está no `.gitignore`).

**Nunca** são impressas chaves em logs; o arquivo local é criado com permissões restritas; `config/api_keys.json` e `.env` estão no `.gitignore`.

---

## ⚙️ Configuração

`config/config.json` (criado na primeira execução):

```json
{
  "performance_preset": "BALANCED",
  "max_concurrent_requests": 5,
  "request_timeout": 15.0,
  "retry_count": 2,
  "rate_limit_per_second": 5.0,
  "cache_enabled": true,
  "cache_ttl": 86400,
  "max_cache_size": 10000,
  "output_format": "json",
  "logging_level": "INFO"
}
```

Presets: `LOW`, `BALANCED`, `PERFORMANCE`, `CUSTOM`:

```bash
python nexus.py config --preset PERFORMANCE
python nexus.py config --set cache_ttl 43200
python nexus.py config --show
```

Variáveis de ambiente com prefixo `NEXUS_` sobrescrevem (ex.: `NEXUS_CACHE_ENABLED=false`, `NEXUS_LOG_LEVEL=DEBUG`).

---

## 🏗️ Arquitetura

```
nexus/
├── nexus.py                 # ponto de entrada único
├── core/                    # núcleo (sem dependência de APIs específicas)
│   ├── engine.py            # engine assíncrona (asyncio, semáforo, retry, cache)
│   ├── dispatcher.py        # seleção/ordenação de plugins por tipo de alvo
│   ├── plugin.py            # interface NexusPlugin / PluginResult
│   ├── plugin_manager.py    # descoberta automática de plugins
│   ├── target_detector.py   # detecção automática de tipos de alvo
│   ├── normalizer.py        # normalização canônica dos alvos
│   ├── deduplicator.py      # agrupamento de resultados + confiança
│   ├── result_manager.py    # agregação de resultados
│   ├── cache.py             # cache SQLite (TTL + LRU)
│   ├── rate_limiter.py      # token bucket global e por plugin
│   ├── secret_store.py      # Credential Manager → env → arquivo
│   ├── api_manager.py       # registro canônico de APIs reais
│   ├── config.py            # configuração (JSON + env + presets)
│   └── logger.py            # logs redigidos em logs/*.log
├── cli/                     # argparse + menu interativo + output
├── plugins/                 # plugins (cada um em sua pasta)
├── database/                # SQLite (migrations, models, acesso)
├── reports/                 # geradores json/csv/html/txt
├── config/                  # exemplos de configuração
├── tests/                   # suíte automatizada (offline, com mocks)
├── scripts/                 # install.ps1 / start.ps1 / update.ps1
└── docs/                    # documentação
```

**Regra de ouro:** o núcleo não depende de nenhuma API específica. Novas integrações são sempre plugins.

Roadmap: V1 core + primeiros plugins ✅ → V2 mais APIs + scan múltiplo ✅ → V3 correlação de resultados → V4 dashboard web → V5 marketplace de plugins.

---

## 🧪 Testes

```bash
pip install -r requirements-dev.txt
pytest -v          # suíte completa (offline, com mocks)
ruff check .       # lint
```

A suíte cobre: detector de alvos, normalização, plugins, API manager, rate limiter, cache, deduplicação, banco, exportação, CLI (incluindo scan múltiplo), engine e tratamento de erros.

---

## 📚 Documentação

- [docs/INSTALL.md](docs/INSTALL.md) — instalação passo a passo
- [docs/USAGE.md](docs/USAGE.md) — todos os comandos
- [docs/PLUGINS.md](docs/PLUGINS.md) — como criar plugins
- [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) — desenho do sistema
- [docs/API_MANAGER.md](docs/API_MANAGER.md) — catálogo de APIs e chaves
- [docs/SECURITY.md](docs/SECURITY.md) — modelo de segurança
- [docs/ETHICS.md](docs/ETHICS.md) — limites éticos e legais
- [docs/GITHUB.md](docs/GITHUB.md) — como publicar no GitHub

---

## 🤝 Contribuição

Veja [CONTRIBUTING.md](CONTRIBUTING.md). Resumo:

1. Faça um fork e crie uma branch.
2. Escreva o plugin/teste/correção.
3. Rode `pytest` e `ruff check .`.
4. Abra um PR. CI roda testes (Linux + Windows, Python 3.12/3.13), lint, sintaxe e build.

---

## 📄 Licença

MIT — veja [LICENSE](LICENSE).

---

**NEXUS é uma ferramenta de defesa e pesquisa legítima.** Use com responsabilidade.
