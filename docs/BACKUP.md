# Sistema de Backup e Restauração - ZENITH PANEL (Módulo 17)

O módulo **ZENITH BACKUP** oferece um sistema profissional e à prova de falhas para criar, inspecionar, restaurar e excluir backups do painel.

---

## 💾 Menu do Backup (`17`)

```
╔══════════════════════════════╗
║       ZENITH BACKUP          ║
╠══════════════════════════════╣
║ 1 │ Criar backup             ║
║ 2 │ Restaurar                ║
║ 3 │ Listar backups           ║
║ 4 │ Ver tamanho              ║
║ 5 │ Excluir backup           ║
║ 6 │ Configurar diretório     ║
║ 0 │ Voltar                   ║
╚══════════════════════════════╝
```

---

## 🛡️ Regras de Proteção de Dados
1. **Nunca apagar backups automaticamente**: Nenhuma rotina automática ou script de atualização exclui os seus arquivos de backup em `~/.config/zenith/backups/`.
2. **Inspeção Prévia antes da Restauração**: Ao selecionar a opção `2` (Restaurar), o painel lista os arquivos e pastas que serão sobrescritos no seu dispositivo e solicita confirmação do usuário antes de aplicar.
3. **Exclusão Explícita (`CONFIRMAR`)**: Para excluir um arquivo de backup (`5`), você é obrigado a digitar a palavra exata **`CONFIRMAR`** para aprovar a ação.

---

## 🔄 Backups Automáticos
- Sempre que você opta por atualizar o painel na opção **`21 — ATUALIZAR`**, o sistema gera de forma automática e preventiva um backup de segurança (`zenith_pre_update_<data>.tar.gz`) com todas as suas configurações visuais, chaves de API e cadastros.
