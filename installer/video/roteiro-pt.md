# Mirror Mind no Windows — instalação em um vídeo

**Para quem:** quem vai instalar o Mirror num Windows pela primeira vez · **Duração alvo:** 2 min 30 s · **Formato:** narração sobre telas reais, capturadas numa instalação de verdade (Windows Sandbox, perfil `Helena`), player 1280×720, capítulos de 10 a 30 s.

**Ao final, a pessoa sabe:** o que o instalador faz e o que pede; que não precisa de senha de administrador; onde fica a memória; que precisa de uma chave da OpenRouter; como abrir o Mirror e conversar.

| # | Capítulo | Narração | Tela e estado | Ação animada |
|---|---|---|---|---|
| 1 | Abertura | "Este é o instalador do Mirror Mind para Windows. Um arquivo, alguns cliques, e o Mirror está pronto para conversar." | Cartão de abertura: octaedro, "Mirror Mind · instalação no Windows", versão | Cartão entra |
| 2 | O arquivo | "Você recebe um único arquivo: MirrorMind-Setup. Dois cliques nele. Não pede senha de administrador: ele instala só para o seu usuário." | Área de trabalho com o `.exe` | Cursor até o arquivo; dois cliques; onda |
| 3 | Boas-vindas | "A primeira tela explica o que vai acontecer: o instalador baixa e prepara o que o Mirror precisa, e no fim pergunta duas coisas. Leva uns cinco minutos. Clique em «Instalar»." | 01-boas-vindas | Realce no texto; cursor até «Instalar»; clique |
| 4 | Instalando | "Agora é esperar. Ele instala o Node, o Git e o Pi, que é o terminal onde o Mirror conversa. Cada passo aparece na tela, com o tempo que levou. Nada para fazer aqui." | 03-instalando-meio → 04-instalando-fim (crossfade) | Realce na barra; realce no transcript rolando |
| 5 | Quase lá | "Terminou a parte pesada. Agora o Mirror quer saber quem é você. O nome que você escrever vira a sua pasta de memória, aqui neste computador. Nada é enviado para fora." | 05-quase-la | Realce no texto do meio; realce no campo «Como você quer ser chamado?» |
| 6 | A chave | "Para conversar, o Mirror usa um serviço de IA. O instalador configura a OpenRouter, uma conta que dá acesso a vários modelos. Se você ainda não tem, o botão «Criar conta e gerar chave» abre a página certa: crie a conta, adicione um crédito, cinco dólares por exemplo, gere uma chave e cole aqui. Ela começa com sk-or. Se você já tem conta na OpenAI ou na Anthropic, também pode usá-las; isso se configura depois da instalação." | 05-quase-la | Realce no botão; realce no campo da chave (mascarada) |
| 7 | Configurando | "Clique em «Avançar». O Mirror confere a chave, cria a sua identidade, carrega as doze personas e se conecta ao Pi. Uns trinta segundos." | 06-configurando | Cursor até «Avançar»; clique; realce no transcript |
| 8 | Concluído | "Pronto. Deixe marcado «Iniciar o Mirror Mind» e clique em «Concluir». Daqui em diante, o atalho na área de trabalho abre o Mirror." | 07-concluido | Realce na caixa; cursor até «Concluir»; clique |
| 9 | O Mirror abre | "O Mirror abre numa janela de texto. O cartão mostra seu nome, a versão, e o que ele já sabe: uma jornada, doze personas, nenhuma memória ainda. Ela começa agora." | 08-mirror-abre | Realce no cartão `◇ Mirror · Helena` |
| 10 | A primeira conversa | "Converse como conversaria com alguém. Por exemplo, peça para ele listar as suas personas. Ele entende, consulta a memória e responde." | 09-pergunta → 11-resposta-final | Texto digitado; Enter; realce na lista |
| 11 | Em resumo | "Um arquivo, sem senha de administrador, cinco minutos. Seu nome e uma chave da OpenRouter. E o Mirror está pronto para conversar, com a memória guardada no seu computador." | Cartão de resumo: três frases | Frases acendem uma a uma |
| 12 | Fim | "Mirror Mind." | Cartão final: octaedro, versão, data | — |

**Rótulos a verificar nas telas:** «Instalar» · «Como você quer ser chamado?» · «Criar conta e gerar chave…» · «Avançar» · «Iniciar o Mirror Mind» · «Concluir» · `◇ Mirror · Helena`.

**Voz e estilo:** ElevenLabs, Matilda (pré-definida, `eleven_multilingual_v2`, sem `language_code` — a voz decide o idioma por trecho e lê "Mirror", "OpenRouter", "Node", "Git", "Anthropic" em inglês). A alternativa gratuita, edge-tts com a voz Thalita, fica em `narrar.py`; soa mais robótica. Segunda pessoa, frases curtas, tom calmo. Só na fala: "MirrorMind-Setup" → "MirrorMind Setup", "Pi" → "Pái" (senão vira o pi português), "sk-or" → "s k, hífen, o r". Evitar frases que também existem em espanhol ("listar minhas personas" virava espanhol): a fala pede, a tela mostra o comando.

**Privacidade na gravação:** o nome é fictício (`Helena`); a chave é escrita no Sandbox só durante a gravação, aparece mascarada na tela e é apagada no fim. O log da página de configuração mostra o rótulo da chave (`sk-or-v1-` seguido de seis caracteres dela): antes de montar, esses seis caracteres são cobertos em `out/video/frames/06-configurando.png`.

**Ordem:** `record-frames.ps1` (com `OPENROUTER_API_KEY` no ambiente) → tarja no quadro 06 → `narrar.py` (com `ELEVENLABS_API_KEY`) → `gravar.py`. O resultado fica em `out/video/`, fora do git, e vai como anexo da release.

**Dados do ambiente:** Windows 11 (Sandbox); as versões do instalador, do `mirror-mind` e do Pi aparecem no cartão final e saem dos arquivos de versão e do log da instalação gravada.
