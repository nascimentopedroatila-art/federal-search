# Política de Segurança

## Escopo

Esta política cobre o NEXUS — Modular Intelligence Toolkit. O projeto é uma
ferramenta **defensiva** de OSINT legítimo e diagnóstico de redes próprias.

## Versões suportadas

| Versão | Suportada |
|---|---|
| 1.x | ✅ |
| < 1.0 | ❌ |

## Reportando vulnerabilidades

Se você encontrou uma vulnerabilidade de segurança no NEXUS, **não** abra uma
issue pública. Envie um e-mail para os mantenedores do repositório (veja o
perfil de `nascimentopedroatila-art`) com:

- descrição da vulnerabilidade;
- passos para reprodução;
- impacto estimado;
- versão afetada.

Você receberá uma resposta em até 5 dias úteis. Após a correção, agradecemos a
divulgação responsável.

## Regras de segurança do projeto

1. **Nunca** armazenar API keys em código-fonte.
2. Chaves devem usar o Windows Credential Manager (DPAPI), variáveis de
   ambiente ou `.env` apenas em desenvolvimento.
3. Secrets nunca devem ser impressos em logs (o logger redige padrões de
   `api_key=...`, `token=...`, `Bearer ...`).
4. `.env` e `config/api_keys.json` estão no `.gitignore`.
5. Consultas de rede possuem timeouts, rate limiting e limites de resultados —
   nunca infinitas.
6. O NEXUS não executa ataques ativos: apenas consultas passivas a fontes
   públicas e diagnóstico de redes próprias.
7. Nenhuma integração com endpoint não documentado: todas as APIs listadas em
   `core/api_manager.py` possuem documentação oficial.

## Boas práticas para usuários

- Execute scans apenas contra alvos que você possui ou possui autorização.
- Respeite os termos de serviço e limites de cada fonte consultada.
- Não use o NEXUS para coletar dados pessoais sem base legal.
