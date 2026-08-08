# Segurança Defensiva e Hardening - Módulo 12

O módulo **SEGURANÇA DEFENSIVA (`12`)** do ZENITH PANEL é composto por utilitários e auditorias de sistema desenvolvidos estritamente para propósitos de conformidade, endurecimento (*hardening*) e diagnóstico do próprio dispositivo ou laboratório autorizado.

---

## 🔐 Conformidade e Políticas do Projeto
O **ZENITH PANEL** **NÃO** inclui, distribui ou encoraja funcionalidades para:
- Roubo ou captura ilegal de credenciais e senhas.
- Invasão de contas ou phishing.
- Instalação de malware ou ocultação de processos maliciosos.
- Bypass de autenticação em redes ou exploração de sistemas de terceiros.
- Execução de ataques de negação de serviço (DDoS).

Todas as ferramentas de rede (`04`), auditorias (`12`) e testes (`13`) têm como escopo exclusivo:
- **O seu próprio dispositivo** (Termux / Android / PC).
- **O seu próprio servidor local ou laboratório**.
- **Sistemas onde você detém autorização explícita de auditoria**.

---

## 🛠️ Auditorias Disponíveis no Módulo 12
1. **Auditoria de Permissões Críticas**: Localiza arquivos com permissão aberta `777` no diretório HOME e verifica permissões de chaves SSH em `~/.ssh/` (garantindo o uso seguro de `chmod 600`).
2. **Hashes SHA-256 e Integridade**: Confirma a integridade de arquivos vitais de configuração (`zenith.conf`, `ai.conf`, `.bashrc`).
3. **Auditoria de Processos Ativos**: Identifica os processos com maior consumo de recursos de memória e CPU.
4. **Auditoria de Portas e Serviços**: Exibe portas TCP em escuta e serviços ativos.
5. **Detecção de Configurações Inseguras**: Analisa variáveis vulneráveis (ex: `PATH` contendo `.`, histórico exposto, etc.).
6. **Gerador de Relatório Formal**: Consegue exportar o diagnóstico de segurança estruturado para o arquivo `zenith-security-report.txt`.
