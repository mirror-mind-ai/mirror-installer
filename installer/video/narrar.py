# Narração dos capítulos do vídeo do instalador, a partir da tabela do roteiro.
#   uv run --with requests --with imageio-ffmpeg python installer/video/narrar.py [roteiro] [pasta] [eleven|edge]
# Padrões: installer/video/roteiro-pt.md e out/video/narracao.
# Gera <pasta>/c<N>.mp3, <pasta>/timings.json e <pasta>/textos.json.
#
# Motor padrão: ElevenLabs, voz Matilda (pré-definida; funciona no plano gratuito),
# eleven_multilingual_v2 sem language_code: forçar pt fazia "Mirror" e "OpenRouter" soarem
# em português; com a detecção automática a voz lê os nomes em inglês. A alternativa
# gratuita, edge-tts com a voz Thalita, soa mais robótica.
# A chave vem só de ELEVENLABS_API_KEY no ambiente.
# Pronúncia só na fala; a legenda mantém a grafia do roteiro.
import json, os, re, subprocess, sys
from pathlib import Path

import imageio_ffmpeg

RAIZ = Path(__file__).resolve().parents[2]
FFMPEG = imageio_ffmpeg.get_ffmpeg_exe()
ELEVEN_VOICE = "XrExE9yKIg1WjnnlVkGX"   # Matilda - Knowledgable, Professional
ELEVEN_MODEL = "eleven_multilingual_v2"
ELEVEN_SETTINGS = {"stability": 0.5, "similarity_boost": 0.75, "style": 0.2, "use_speaker_boost": True}
EDGE_VOICE, EDGE_RATE, EDGE_PITCH = "pt-BR-ThalitaMultilingualNeural", "-12%", "-5Hz"

# The multilingual models read English names on their own; only what neither
# guesses gets help. The edge voice also needs the three product names respelled.
PRONUNCIA_COMUM = [
    (r"MirrorMind-Setup", "MirrorMind Setup"),
    (r"sk-or", "s k, hífen, o r"),
    (r"\bPi\b", "Pái"),   # both voices read "Pi" as the Portuguese letter otherwise
    (r"OpenRouter", "Ôpenrauter"),   # chosen by ear over seven spellings
    (r"«|»", ""), (r"·", ","), (r"…", ""), (r"—", ","),
]
PRONUNCIA_EDGE = [(r"\bNode\b", "Nôud"), (r"\bGit\b", "Guitt"), (r"Anthropic", "Antrópic")]


def para_fala(t: str, engine: str) -> str:
    for a, b in PRONUNCIA_COMUM + (PRONUNCIA_EDGE if engine == "edge" else []):
        t = re.sub(a, b, t)
    return re.sub(r"\s+", " ", t).strip()


def eleven_key() -> str:
    k = os.environ.get("ELEVENLABS_API_KEY")
    if not k:
        sys.exit("ELEVENLABS_API_KEY is not set (or use the edge engine, which needs no key)")
    return k


def sintetiza(texto: str, f: Path, engine: str):
    if engine == "eleven":
        import requests
        r = requests.post(f"https://api.elevenlabs.io/v1/text-to-speech/{ELEVEN_VOICE}",
                          headers={"xi-api-key": eleven_key(), "accept": "audio/mpeg"},
                          json={"text": texto, "model_id": ELEVEN_MODEL, "voice_settings": ELEVEN_SETTINGS}, timeout=180)
        if not r.ok:
            sys.exit(f"elevenlabs {r.status_code}: {r.text[:200]}")
        f.write_bytes(r.content)
    else:
        subprocess.run(["uv", "run", "--quiet", "--with", "edge-tts", "edge-tts", "--voice", EDGE_VOICE, f"--rate={EDGE_RATE}", f"--pitch={EDGE_PITCH}",
                        "--text", texto, "--write-media", str(f)], check=True)


md = Path(sys.argv[1]) if len(sys.argv) > 1 else RAIZ / "installer/video/roteiro-pt.md"
pasta = Path(sys.argv[2]) if len(sys.argv) > 2 else RAIZ / "out/video/narracao"
engine = sys.argv[3] if len(sys.argv) > 3 else "eleven"
pasta.mkdir(parents=True, exist_ok=True)
timings, textos, chars = {}, {}, 0
for linha in md.read_text(encoding="utf-8").replace("\r\n", "\n").splitlines():
    m = re.match(r"^\| (\d+) \| ([^|]+) \| (.+?) \| ", linha)
    if not m:
        continue
    n, texto = int(m.group(1)), m.group(3).strip()
    if texto.startswith('"') and texto.endswith('"'):
        texto = texto[1:-1]
    textos[n] = texto
    fala = para_fala(texto, engine)
    chars += len(fala)
    f = pasta / f"c{n}.mp3"
    sintetiza(fala, f, engine)
    info = subprocess.run([FFMPEG, "-i", str(f)], capture_output=True, text=True).stderr
    d = re.search(r"Duration: (\d+):(\d+):([\d.]+)", info)
    timings[n] = round(int(d.group(1)) * 3600 + int(d.group(2)) * 60 + float(d.group(3)), 3)
(pasta / "timings.json").write_text(json.dumps(timings, indent=1), encoding="utf-8")
(pasta / "textos.json").write_text(json.dumps(textos, indent=1, ensure_ascii=False), encoding="utf-8")
print(f"{md.name}: {len(timings)} capítulos, {sum(timings.values()):.0f}s de fala, {chars} caracteres ({engine})")
