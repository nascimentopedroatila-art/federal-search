# Referência de Comandos - ZENITH PANEL

Além do menu interativo no terminal, o **ZENITH PANEL** possui comandos e flags de linha de comando para acesso imediato aos módulos e rotinas automatizadas.

---

## 💻 Argumentos Globais (`zenith [opção]`)

| Comando | Descrição |
| :--- | :--- |
| `zenith` | Abre o menu interativo completo do painel. |
| `zenith --help` / `-h` | Exibe o manual e lista de argumentos de terminal suportados. |
| `zenith --version` / `-v` | Exibe a versão oficial do Zenith Panel (`1.0.0`). |
| `zenith --diagnostic` | Executa o teste automático e gera o relatório `zenith-diagnostic.txt`. |
| `zenith --backup` | Executa imediatamente um backup das configurações para `~/.config/zenith/backups/`. |
| `zenith 01` a `23` | Abre diretamente o módulo numérico selecionado. |

---

## ⌨️ Atalhos de Terminal no Modo Tempo Real
- **No Monitor em Tempo Real (`02`)**: Pressione `q` ou `CTRL+C` para encerrar o loop e voltar ao submenu de monitoramento.
- **No Cronômetro Digital (`07`)**: Pressione `q` ou `CTRL+C` para congelar o cronômetro.
- **Nas Confirmações de Exclusão (`14`, `17`)**: É necessário digitar a palavra exata `CONFIRMAR` em maiúsculas para aprovar a exclusão permanente de arquivos e backups.
