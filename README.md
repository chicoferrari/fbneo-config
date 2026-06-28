# fbneo-config

Configuração do **FBNeo** (FinalBurn Neo, SDL2 standalone) no CachyOS —
arcade multi-sistema (CPS-1/2/3, Neo Geo). Complementa o MAME com o tuning
do FBNeo para boards de arcade e Neo Geo.

> O port standalone (macOS/Linux) é menos mantido que o core libretro.
> Se algum recurso faltar, o RetroArch + core FBNeo é o fallback.

## Estrutura

```
fbneo-config/
├── fbneo-bootstrap.sh              # aponta ROM paths no fbneo.ini (upsert idempotente)
├── fbneo-launch.sh                 # launcher com seletor de sistema + fzf
├── apply-input.sh                  # deploy manual de input config por sistema
├── input_configs/
│   ├── p1defaults-capcom.ini       # layout Capcom: SF 6-botões (WP/MP/HP | WK/MK/HK)
│   └── p1defaults-snk.ini          # layout SNK: Neo Geo 4-botões (A/B/C/D sequencial)
└── README.md
```

## Setup inicial

### 1. ROM paths

Edite o array `ROM_PATHS` em `fbneo-bootstrap.sh` com seus diretórios de romsets
e rode uma vez:

```bash
chmod +x fbneo-bootstrap.sh
./fbneo-bootstrap.sh
```

O script faz upsert em `~/.local/share/fbneo/config/fbneo.ini`. Estrutura esperada
de diretórios:

```
/media/GameStorage/roms/FBNeo/
├── capcom/     # CPS-1, CPS-2, CPS-3
└── neogeo/     # Neo Geo (+ neogeo.zip BIOS aqui)
```

### 2. Romsets e BIOS

FBNeo usa romsets no estilo MAME, versionados contra o build instalado.
A BIOS do Neo Geo (`neogeo.zip`) vai no mesmo diretório dos ROMs Neo Geo.
Romsets e BIOS são gitignored.

## Launch

```bash
chmod +x fbneo-launch.sh
./fbneo-launch.sh            # picker de sistema → picker de jogo (fullscreen)
./fbneo-launch.sh capcom     # picker de jogo Capcom direto
./fbneo-launch.sh snk        # picker de jogo SNK direto
./fbneo-launch.sh mslug      # romname direto, detecta sistema pelo dir
./fbneo-launch.sh mslug -w   # janela
```

Sem fzf instalado ou sem jogo selecionado, o launcher aborta com mensagem de erro (`die`) — não há fallback para o menu nativo do FBNeo.

## Input / mapeamento 8BitDo

Capcom e SNK usam layouts de botões incompatíveis — um único `p1defaults.ini`
não serve para os dois. O launcher resolve isso fazendo deploy automático do
mapa correto antes de cada sessão:

| Sistema | Arquivo | fire 1 | fire 2 | fire 3 | fire 4 | fire 5 | fire 6 |
|---------|---------|--------|--------|--------|--------|--------|--------|
| Capcom  | `p1defaults-capcom.ini` | Sul (WP) | Oeste (MP) | L1 (HP) | Leste (WK) | Norte (MK) | R1 (HK) |
| SNK     | `p1defaults-snk.ini`    | Sul (A)  | Leste (B)  | Oeste (C) | Norte (D) | L1 | R1 |

Códigos SDL2 do 8BitDo:

```
0x4080 = Sul    (face baixo)
0x4081 = Leste  (face direita)
0x4082 = Oeste  (face esquerda)
0x4083 = Norte  (face cima)
0x4089 = L1     (ombro esquerdo)
0x408A = R1     (ombro direito)
```

### Como funciona o deploy

O `fbneo-launch.sh` copia o `p1defaults-<sistema>.ini` para
`~/.local/share/fbneo/config/p1defaults.ini` antes de abrir o jogo.
Esse arquivo é o template usado pelo FBNeo para gerar o `games/<rom>.ini`
na primeira vez que um jogo é aberto.

> Jogos com `config/games/<rom>.ini` próprio ignoram o `p1defaults` —
> o per-game .ini tem precedência. Para forçar herança do novo layout,
> delete o `.ini` do jogo: `rm ~/.local/share/fbneo/config/games/<rom>.ini`

### Deploy manual

Para forçar um layout sem abrir um jogo:

```bash
./apply-input.sh capcom
./apply-input.sh snk
```

## Teclas in-game

| Tecla | Ação |
|-------|------|
| `TAB` | Menu de inputs |
| `F12` | Quit |
| `Alt+Enter` | Fullscreen toggle |

## Notas

- Arcade é leve para o 6800H — nenhum ajuste de governor necessário.
- Áudio via SDL2 → PipeWire; sem necessidade de workaround `hw:0`.
- O `fbneo.ini` real não é versionado (carrega paths de máquina).
