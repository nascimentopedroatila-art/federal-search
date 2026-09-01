# Segurança

## Modelo de ameaças

O NEXUS processa:

- alvos informados pelo usuário (domínios, IPs, e-mails, telefones, hashes);
- respostas de APIs públicas;
- API keys do usuário.

Os controles abaixo protegem esses ativos.

## Proteção de API keys

| Camada | Mecanismo |
|---|---|
| Armazenamento preferencial | Windows Credential Manager (DPAPI) via `ctypes` |
| Portátil | variáveis de ambiente |
| Dev somente | `.env` / `config/api_keys.json` (permissões 600, gitignored) |
| Logs | redação automática (`api_key=`, `token=`, `secret=`, `Bearer ...`) |
| Git | `.env`, `config/api_keys.json`, `data/`, `logs/` no `.gitignore` |

Nunca:

- armazenar chaves no código-fonte;
- imprimir chaves no terminal ou logs;
- commitá-las.

## Limites de execução

- `max_concurrent_requests` (semáforo);
- `request_timeout` por requisição e `timeout` por plugin;
- `retry_count` com exponential backoff;
- `rate_limit_per_second` global e por plugin;
- `MAX_RESULTS_PER_PLUGIN` (500) e `max_results_per_plugin` da config;
- `MAX_HTTP_RESPONSE_BYTES` (5 MB) e `MAX_TARGET_LENGTH` (4096);
- sem consultas infinitas — sempre há limite de duração.

## Regra de confiança

- `CONFIRMED` — verificação determinística;
- `HIGH` — fonte primária observada;
- `MEDIUM` — inferência;
- `LOW` — ambíguo.

O NEXUS **nunca** apresenta informação incerta como fato e **sempre** mostra a
fonte de cada resultado.

## Não-funcionalidades (proibido)

- invasão de contas / quebra de senhas / credential stuffing;
- bypass de CAPTCHA ou autenticação;
- exploração automática contra terceiros;
- acesso a bases privadas / dados vazados;
- malware, persistência, exfiltração, ocultação de atividade.

## Reportando vulnerabilidades

Veja [SECURITY.md](../SECURITY.md) na raiz.
