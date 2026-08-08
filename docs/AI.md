# Inteligência Artificial (ZENITH AI) - Módulo 06

O módulo **ZENITH AI** é um centro de IA interativo no terminal compatível com múltiplos provedores em nuvem e servidores de modelo de linguagem locais (OLLAMA).

---

## 🤖 Provedores Suportados

| Provedor | Modelo Padrão | Variável da Chave / Host |
| :--- | :--- | :--- |
| **OpenAI** | `gpt-4o-mini` | `OPENAI_API_KEY` |
| **Anthropic** | `claude-3-5-sonnet` | `ANTHROPIC_API_KEY` |
| **Google Gemini** | `gemini-1.5-flash` | `GEMINI_API_KEY` |
| **Groq** | `llama-3.1-8b-instant` | `GROQ_API_KEY` |
| **Ollama (Local)** | `llama3.1` | `OLLAMA_HOST` (Padrão: `http://127.0.0.1:11434`) |

---

## 🛡️ Segurança de Chaves de API
- **Nenhuma chave de API fica no código-fonte**. Elas são armazenadas no arquivo `~/.config/zenith/ai.conf`.
- O arquivo é protegido automaticamente com permissões restritas (**`chmod 600`**), impedindo leitura por outros usuários do sistema.
- Na tela de configuração e relatórios, as chaves são mascaradas (ex: `sk-abc************1234`), nunca exibidas por inteiro.

---

## ⚡ Usando o Chat
1. Acesse o Módulo **`06`** no menu principal.
2. Escolha **`1`** para abrir o chat interativo.
3. Se você possuir uma chave configurada para o provedor selecionado, a resposta será obtida online e em tempo real.
4. Caso ainda não tenha configurado uma chave, o painel utilizará o modo local de simulação para que você possa testar os templates e histórico de comandos de imediato.
