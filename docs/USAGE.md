# Uso (referência de comandos)

## Scan

```bash
python nexus.py scan --target <alvo>
```

O tipo é detectado automaticamente:

| Exemplo de alvo | Tipo detectado |
|---|---|
| `+5585999999999` | `phone` |
| `user@example.com` | `email` |
| `example.com` | `domain` |
| `8.8.8.8` | `ip` |
| `https://example.com` | `url` |
| `d41d8cd98f00b204e9800998ecf8427e` | `hash` |
| `example_username` | `username` |

### Opções do scan

| Opção | Descrição |
|---|---|
| `--target <alvo>` | alvo único |
| `--targets <a,b,c>` | scan múltiplo (V2): vários alvos em paralelo |
| `--type <tipo>` | força o tipo (`phone`, `email`, `username`, `domain`, `ip`, `url`, `hash`) — sempre respeitado |
| `--plugins <a,b>` | executa apenas os plugins listados |
| `--json` | saída JSON pura (sem tabela nem logs no stdout) |
| `--no-db` | não grava o scan no banco |
| `--max-concurrent N` | override da concorrência |
| `--timeout N` | override do timeout de requisição (segundos) |

### Scan múltiplo

```bash
python nexus.py scan --targets "+5585999999999,8.8.8.8,user@example.com"
python nexus.py scan --targets "example.com,example.org" --json
```

Cada alvo é processado em paralelo (limite de concorrência) e gerado como um
`ScanResult` independente, com histórico e exportação individuais.

## Menu interativo

```bash
python nexus.py menu
```

```text
╔══════════════════════════════════════════╗
║             M E N U   P R I N C I P A L  ║
╠══════════════════════════════════════════╣
║  1. OSINT                                ║
║  2. Network                              ║
║  3. DNS                                  ║
║  4. Hash Analysis                        ║
║  5. API Manager                          ║
║  6. Reports                              ║
║  7. Plugins                              ║
║  8. Configuration                        ║
║  9. System Diagnostics                   ║
║  0. Exit                                 ║
╚══════════════════════════════════════════╝
```

## Plugins

```bash
python nexus.py plugins                    # todos
python nexus.py plugins --type domain      # filtro por tipo
```

## API Manager

```bash
python nexus.py apis
python nexus.py apis --json
```

## Histórico

```bash
python nexus.py history
python nexus.py history --limit 50
```

## Relatórios

```bash
python nexus.py export --scan <SCAN_ID> --format json
python nexus.py export --scan <SCAN_ID> --format csv
python nexus.py export --scan <SCAN_ID> --format html
python nexus.py export --scan <SCAN_ID> --format txt
python nexus.py export --scan <SCAN_ID> --format html -o meu_relatorio.html
```

O `<SCAN_ID>` aceita prefixo (ex.: `28d80fa17ad1` → `28d80f`).

## API keys (seguras)

```bash
python nexus.py keys list
python nexus.py keys set ABUSEIPDB_API_KEY          # prompt sem eco
python nexus.py keys set ABUSEIPDB_API_KEY --value "..."
python nexus.py keys set ABUSEIPDB_API_KEY --backend file   # apenas dev
python nexus.py keys delete VIRUSTOTAL_API_KEY
```

## Configuração

```bash
python nexus.py config --show
python nexus.py config --preset LOW|BALANCED|PERFORMANCE|CUSTOM
python nexus.py config --set cache_ttl 43200
python nexus.py config --set logging_level DEBUG
```

## Diagnóstico

```bash
python nexus.py diag                      # sistema + rede local
python nexus.py diag --host 1.1.1.1       # + latência/DNS/conectividade
python nexus.py diag --json
```

## Auto-verificação

```bash
python nexus.py selfcheck
```

## Status possíveis de plugins/resultados

`SUCCESS` · `NO_RESULTS` · `SKIPPED` · `RATE_LIMITED` · `TIMEOUT` · `ERROR` · `NOT_CONFIGURED`

Se uma fonte não estiver disponível → `NOT AVAILABLE`. Se não houver resultado → `NO RESULTS`.
