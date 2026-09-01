# Ética e uso legítimo

## Para que o NEXUS existe

- OSINT legítimo sobre **fontes públicas**;
- pesquisa de infraestrutura pública (DNS, certificados, WHOIS, ASN);
- análise dos **próprios dados** (e-mails, números, hashes);
- auditorias **autorizadas** (escopo contratado/consentido);
- diagnóstico de **redes próprias**;
- análise **defensiva** (reputação de IPs/hashes, detecção de exposição).

## O que o NEXUS NÃO faz (por design)

| Proibido | Exemplo |
|---|---|
| Invasão de contas | tentar logar em serviços alheios |
| Quebra de senhas | cracking de hashes de senha |
| Credential stuffing | testar credenciais vazadas |
| Bypass de CAPTCHA | automatizar captchas |
| Bypass de autenticação | contornar 2FA/SSO |
| Exploração automática | scanner de vulnerabilidades contra terceiros |
| Acesso a bases privadas | vazar/comprar bancos de dados |
| Uso de dados vazados | correlacionar com dados de breaches |
| Malware / persistência / exfiltração | qualquer código malicioso |
| Ocultação | anonimização para esconder atividade maliciosa |

## Regra de ouro dos dados

**Nunca inventar:**

- APIs (todo endpoint tem documentação oficial);
- resultados (sem fonte, sem dado);
- contas/URLs/informações de pessoas/empresas.

Se uma fonte não estiver disponível → `NOT AVAILABLE`.
Se não houver resultado → `NO RESULTS`.
Se faltar chave → `NOT CONFIGURED`.
Se ocorrer erro → `ERROR`.

Sempre exibir **fonte** e **status**.

## Responsabilidade

- Respeite os termos de serviço, limites de API e políticas de acesso das
  fontes consultadas.
- Obtenha autorização antes de analisar infraestrutura que não é sua.
- Não colete dados pessoais sem base legal (LGPD/GDPR e legislação local).
- O uso indevido é de responsabilidade exclusiva do usuário.
