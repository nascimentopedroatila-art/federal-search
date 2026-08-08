# Guia de Contribuição - ZENITH PANEL

Agradecemos o seu interesse em contribuir com o **ZENITH PANEL**! Buscamos manter um código modular, elegante e acessível tanto no Termux Android quanto em servidores Linux.

---

## 🏗️ Padrões de Código Bash
1. **Sem Código Duplicado ou `...`**: Sempre escreva funções completas, limpas e documentadas.
2. **Conformidade Termux / Sem Root**: O código nunca deve exigir permissões de root obrigatórias. Funções devem sempre funcionar sem root ou testar privilégios dinamicamente com fallback.
3. **Cores e Mensagens Padrão**: Use sempre as funções de interface disponíveis em `core/ui.sh` (`ui_msg_success`, `ui_msg_warn`, `ui_msg_error`, `ui_msg_info`, `ui_msg_exec`).
4. **Segurança Exigida**: Nunca inclua ou autorize comandos de remoção automática silenciosa de arquivos do usuário. Toda exclusão em `files.sh` ou `backup.sh` deve pedir confirmação explícita (`CONFIRMAR`).

---

## 🧩 Adicionando Novos Plugins ou Módulos
- Para recursos específicos ou integrações de terceiros, priorize a criação de um novo script em `plugins/` seguindo a especificação descrita em `docs/PLUGINS.md`.
- Todos os novos módulos funcionais em `modules/` devem ser referenciados e chamados por número no menu principal em `zenith.sh`.

---

## 🧪 Testes Automatizados
Antes de abrir um Pull Request, execute a suíte oficial de testes automatizados presente em `tests/`:

```bash
cd federal-search
bash tests/run_all_tests.sh
```

Verifique se todos os testes unitários (`test_core.sh`, `test_system.sh`, `test_plugins.sh`, `test_config.sh`, `test_diagnostic.sh`) retornam status **APROVADO (`✓`)**.
