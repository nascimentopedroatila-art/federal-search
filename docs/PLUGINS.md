# Criando plugins

O NEXUS descobre plugins automaticamente em `plugins/`. **Adicionar um plugin
não exige nenhuma alteração no núcleo.**

## Estrutura

```
plugins/
└── minha_categoria/
    ├── __init__.py      # pode ser vazio
    └── plugin.py        # define a classe do plugin
```

O `PluginManager` varre `plugins/` em busca de subclasses concretas de
`core.plugin.NexusPlugin` (módulos `plugin.py` e módulos soltos).

## Mínimo viável

```python
from __future__ import annotations

from core.plugin import NexusPlugin, PluginResult

class MeuPlugin(NexusPlugin):
    name = "Meu Plugin"
    version = "1.0"
    description = "Descrição curta"
    author = "Seu Nome"
    target_types = ["domain"]          # domain | ip | email | phone | username | hash | url
    requires_api_key = None            # None ou nome da chave (ex.: "ABUSEIPDB_API_KEY")
    rate_limit = 5.0                   # requisições por segundo
    timeout = 15.0                     # timeout da execução (segundos)
    cache_ttl = 3600                   # 0 desabilita cache do resultado

    async def execute(self, target, context=None):
        return [
            PluginResult(
                result_type="info",
                data={"exemplo": True},
                source="minha-fonte",
                confidence="MEDIUM",   # LOW | MEDIUM | HIGH | CONFIRMED
            )
        ]
```

## Metadados obrigatórios

| Atributo | Tipo | Descrição |
|---|---|---|
| `name` | `str` | nome exibido na CLI |
| `version` | `str` | versão do plugin |
| `description` | `str` | o que o plugin faz |
| `author` | `str` | autor |
| `target_types` | `list[str]` | tipos de alvo aceitos |
| `requires_api_key` | `str \| None` | nome da chave exigida ou `None` |
| `rate_limit` | `float` | req/s máximo do plugin |
| `timeout` | `float` | limite de execução em segundos |

## Boas práticas

1. **Nunca levante exceções** para fora do `execute` — retorne
   `PluginResult(status="ERROR", ...)` com a mensagem. A engine também captura
   exceções como última barreira, mas o resultado estruturado é melhor.
2. **Não invente fontes**: use apenas APIs com documentação oficial.
3. **Use o cliente compartilhado**: `from plugins.http import make_client, safe_get`.
4. **Respeite o rate limit declarado** — a engine já aplica.
5. **Marque a confiança honestamente**: dados inferidos = `LOW/MEDIUM`;
   observados em fonte primária = `HIGH`; validação determinística = `CONFIRMED`.
6. **Nunca logue secrets** e nunca peça senhas/credenciais.
7. Se o plugin usa uma API externa nova, adicione a entrada real no
   `core/api_manager.py` (nome, site, documentação, tier gratuito).

## Exemplo com chamada HTTP

```python
from core.plugin import NexusPlugin, PluginResult
from plugins.http import make_client, safe_get

class ExemploHttp(NexusPlugin):
    name = "Exemplo HTTP"
    target_types = ["domain"]

    async def execute(self, target, context=None):
        async with make_client(timeout=10.0) as client:
            status, payload, error = await safe_get(
                client, f"https://api.exemplo.com/v1/{target}"
            )
        if status == 200 and payload:
            return [PluginResult(
                result_type="info",
                data=payload,
                source="api.exemplo.com",
                confidence="HIGH",
            )]
        return [PluginResult(
            result_type="info",
            data={"error": error or f"HTTP {status}"},
            source="api.exemplo.com",
            confidence="LOW",
            status="ERROR",
        )]
```

## Testando

Crie `tests/test_meu_plugin.py` usando mocks de HTTP (a suíte roda offline):

```python
from core.plugin_manager import PluginManager
import asyncio

def test_meu_plugin_executa():
    manager = PluginManager()
    manager.register(MeuPlugin)
    plugin = manager.get("Meu Plugin")
    results = asyncio.run(plugin.execute("example.com", context={}))
    assert results and results[0].source
```

Depois: `pytest -v && ruff check .`.
