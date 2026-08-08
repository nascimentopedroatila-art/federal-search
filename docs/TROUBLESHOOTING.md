# Solução de Problemas (Troubleshooting) - ZENITH PANEL

Este guia reúne respostas e soluções para as situações mais comuns ao executar o **ZENITH PANEL** no Termux Android e em distribuições Linux.

---

## 1. O comando `zenith` não é reconhecido no terminal
**Sintoma**: Ao digitar `zenith`, o terminal exibe `command not found`.  
**Solução**:
- Verifique se você executou o instalador oficial (`bash install.sh`).
- O instalador cria um link ou wrapper em `$PREFIX/bin/zenith` (no Termux) ou `/usr/local/bin/zenith` (Linux).
- Se a sua variável `PATH` não incluir esse diretório, você pode adicionar no seu `~/.bashrc`:
  ```bash
  export PATH="$PREFIX/bin:$PATH"
  ```
- Para testar sem reinstalar, você sempre pode executar diretamente na pasta do projeto:
  ```bash
  bash zenith.sh
  ```

---

## 2. A Termux:API exibe a caixa de aviso "NÃO ENCONTRADA"
**Sintoma**: Ao acessar o módulo Android (`03`), a caixa `TERMUX:API NÃO ENCONTRADA` aparece no topo.  
**Solução**:
- No Termux Android, são necessários 2 passos:
  1. Instalar o pacote no terminal: `pkg install termux-api -y`
  2. Instalar o aplicativo **Termux:API** compatível pela F-Droid ou Play Store e conceder as permissões solicitadas no Android (Bateria, Notificações, etc.).
- O Zenith Panel continuará rodando os demais módulos mesmo com essa dependência ausente.

---

## 3. Os caracteres das caixas ou ícones ASCII parecem desalinhados
**Sintoma**: Linhas de borda ou emojis no menu ficam com quebras extras.  
**Solução**:
- Certifique-se de estar utilizando uma fonte monospace compatível (ex: *Fira Code*, *JetBrains Mono* ou a fonte padrão do Termux).
- Se o seu terminal for antigo ou tiver largura muito restrita, ative o **Modo Compacto** no Módulo **`15 — PERSONALIZAÇÃO`** ou **`18 — CONFIGURAÇÕES`**.

---

## 4. Como gerar o relatório de diagnóstico do sistema
Se encontrar algum comportamento inesperado, execute o diagnóstico automático de saúde do sistema pela linha de comando:

```bash
zenith --diagnostic
```

O relatório será gravado em `zenith-diagnostic.txt` e pode ser analisado ou anexado ao abrir uma issue.
