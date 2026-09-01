# Publicando no GitHub

Passo a passo para publicar o NEXUS como repositório público.

## 1. Crie o repositório no GitHub

No GitHub: **New repository** → nome `federal-search` (ou `nexus`) →
descrição: *"NEXUS — Modular Intelligence Toolkit: OSINT legítimo, análise de
infraestrutura pública e diagnóstico de rede."* → **Public** → não inicializar
com README (o projeto já tem).

## 2. Envie o código

```bash
# dentro da pasta do projeto
git init
git add .
git status                     # confira: nada de .env, config/api_keys.json, data/, logs/
git commit -m "feat: NEXUS v1.0.0 — Modular Intelligence Toolkit"
git branch -M main
git remote add origin https://github.com/<seu-usuario>/federal-search.git
git push -u origin main
```

> Verifique o `.gitignore` antes do primeiro push:
> `git check-ignore .env config/api_keys.json data/nexus.db logs/nexus.log`
> deve listar os 4 arquivos.

## 3. Configure o GitHub

- **Settings → Branches → Add rule**: `main` com *Require pull request reviews*
  e *Require status checks* (CI).
- **Settings → Secrets and variables → Actions → New repository secret**:
  (nenhum segredo é obrigatório para o CI; chaves de API nunca vão para lá).
- **Issues → Labels**: adicione `good first issue`, `plugin`, `enhancement`.

## 4. Habilite os badges

Os badges do README apontam para
`nascimentopedroatila-art/federal-search` — se seu usuário/repo for outro,
atualize os links em `README.md` (buscar `federal-search`).

## 5. Release inicial

```bash
git tag -a v1.0.0 -m "NEXUS v1.0.0"
git push origin v1.0.0
```

No GitHub: **Releases → Draft** → escolha a tag `v1.0.0` → cole o resumo do
[CHANGELOG](../CHANGELOG.md) → publique. O workflow `build` gera os artefatos
`dist/` (sdist + wheel) como opção de download.

## 6. Pós-publicação

- Crie uma issue fixada com "Como contribuir" → link para `CONTRIBUTING.md`.
- Habilite **Discussions** para o roadmap (V2 APIs, V3 correlação, V4 web, V5 marketplace).
- Monitore o **Security tab** (dependabot) e aplique updates de dependências.

## Checklist final

- [ ] `pytest -v` passa localmente
- [ ] `ruff check .` sem erros
- [ ] `python nexus.py selfcheck` → "Tudo pronto."
- [ ] `.env`, `config/api_keys.json`, `data/`, `logs/` fora do git
- [ ] README com badges corretos
- [ ] CI verde no GitHub (Tests, Lint, Syntax, Build)
