# Contribuindo com o NEXUS

Obrigado pelo interesse em contribuir! 🎉

Este projeto é voltado para **OSINT legítimo, análise defensiva e diagnóstico
de redes próprias**. Qualquer contribuição deve respeitar o [código de
conduta](CODE_OF_CONDUCT.md) e os limites éticos descritos em
[docs/ETHICS.md](docs/ETHICS.md).

## Como contribuir

1. **Fork** o repositório e crie uma branch a partir de `main`:
   ```bash
   git checkout -b feat/meu-plugin
   ```
2. Faça suas mudanças.
3. **Escreva testes** para o que mudou (a suíte roda offline, com mocks —
   nenhum teste deve depender de rede ou de chaves de API).
4. Rode a verificação local:
   ```bash
   pip install -r requirements-dev.txt
   pytest -v
   ruff check .
   ```
5. Abra um **Pull Request** descrevendo a mudança. O CI roda testes
   (Linux/Windows, Python 3.12/3.13), lint, verificação de sintaxe e build.

## Novos plugins

- Crie uma pasta em `plugins/<categoria>/` com `__init__.py` e `plugin.py`.
- Sua classe deve herdar de `core.plugin.NexusPlugin` e implementar
  `async execute(self, target, context=None) -> list[PluginResult]`.
- Nunca invente APIs ou endpoints: use apenas documentação oficial.
- Não implemente login, bypass de CAPTCHA, quebra de senhas ou varreduras
  agressivas contra terceiros.
- Adicione sua integração ao `core/api_manager.py` (com site, docs e tier
  gratuito reais) se ela usar uma API externa.
- Veja [docs/PLUGINS.md](docs/PLUGINS.md) para o guia completo.

## Padrões de código

- Python 3.12+, type hints em todas as assinaturas, docstrings nas classes.
- PEP 8 (verificado por `ruff`, linha de 100 colunas).
- Funções pequenas e responsabilidade única.
- Tratamento de exceções: plugins **nunca** devem estourar para a engine —
  retorne `PluginResult` com `status="ERROR"`.
- Nunca registre secrets em logs.

## Relatando bugs

Abra uma issue com: passos para reproduzir, saída esperada vs. obtida,
versão do Python/SO e o `python nexus.py selfcheck`.
