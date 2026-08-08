# Guia de Uso Geral - ZENITH PANEL

O **ZENITH PANEL** é um mega toolkit interativo para terminal que centraliza 23 módulos operacionais em uma interface limpa, colorida e navegável numéricamente.

---

## 🎨 Interface do Painel

A tela principal exibe o banner ASCII futurista e um menu em caixa padronizada com 23 opções numeradas (`01` a `23`) e a opção de saída (`0`).

```
╔══════════════════════════════════════════════╗
║          Z E N I T H   P A N E L             ║
║            ULTIMATE TERMUX TOOLKIT           ║
╠══════════════════════════════════════════════╣
║ 01 │ 🖥️  SISTEMA                             ║
║ 02 │ 📊  MONITOR                             ║
...
║  0 │ 🚪  SAIR                                ║
╚══════════════════════════════════════════════╝
```

### Navegação nos Submenus
1. Para acessar qualquer módulo, digite o número correspondente (ex: `1`, `01`, `14`, etc.) e pressione `ENTER`.
2. Em cada submenu, você terá opções numeradas de funcionalidades ou a opção `0` para retornar ao menu anterior sem perder as suas configurações ou sessão.
3. Mensagens do painel seguem cores semânticas padronizadas:
   - `[✓] Operação concluída` (Verde - Sucesso)
   - `[!] Aviso` (Amarelo - Atenção ou fallback de recurso não disponível)
   - `[×] Erro` (Vermelho - Erro ou arquivo inexistente)
   - `[•] Informação` (Azul - Informação geral)
   - `[>] Executando` (Ciano - Processo em andamento)

---

## ⚡ Recursos Principais por Área
- **Monitoramento e Hardware (`01`, `02`, `03`)**: Acompanhe o consumo de CPU, RAM, disco e bateria em tempo real no Android ou Linux.
- **Redes e Servidores (`04`, `10`, `13`)**: Teste conectividade, ping, portas de hosts autorizados e cadastre servidores locais.
- **Automação e Ferramentas (`07`, `09`, `14`)**: Gerencie arquivos com confirmação explícita em exclusões e rode agendamentos.
- **Desenvolvimento (`05`, `06`, `08`, `20`)**: Utilize a IA (OpenAI, Groq, Ollama), gerencie Git e adicione plugins na pasta `plugins/`.
