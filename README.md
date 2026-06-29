# fbneo-config

Scripted config for **FBNeo** (FinalBurn Neo, SDL2 standalone) on CachyOS —
multi-system arcade (CPS-1/2/3, Neo Geo). Complements the MAME repo with FBNeo's
tuning for arcade boards and Neo Geo.

> The standalone port (macOS/Linux) is less maintained than the libretro core.
> If a feature is missing, RetroArch + the FBNeo core is the fallback.

## Structure

```
fbneo-config/
├── fbneo-bootstrap.sh              # points ROM paths in fbneo.ini (idempotent upsert)
├── fbneo-launch.sh                 # launcher with system selector + fzf
├── apply-input.sh                  # manual per-system input deploy
├── input_configs/
│   ├── p1defaults-capcom.ini       # Capcom layout: SF 6-button (WP/MP/HP | WK/MK/HK)
│   └── p1defaults-snk.ini          # SNK layout: Neo Geo 4-button (A/B/C/D sequential)
├── README.md
└── .gitignore
```

## Initial setup

### 1. ROM paths

Edit the `ROM_PATHS` array in `fbneo-bootstrap.sh` with your romset directories
and run it once:

```bash
chmod +x fbneo-bootstrap.sh
./fbneo-bootstrap.sh
```

The script upserts into `~/.local/share/fbneo/config/fbneo.ini`. Expected
directory layout:

```
/media/GameStorage/roms/FBNeo/
├── capcom/     # CPS-1, CPS-2, CPS-3
└── neogeo/     # Neo Geo (+ neogeo.zip BIOS here)
```

### 2. Romsets and BIOS

FBNeo uses MAME-style romsets, versioned against the installed build. The Neo Geo
BIOS (`neogeo.zip`) goes in the same directory as the Neo Geo ROMs. Romsets and
BIOS are gitignored.

## Launch

```bash
chmod +x fbneo-launch.sh
./fbneo-launch.sh            # system picker → game picker (fullscreen)
./fbneo-launch.sh capcom     # Capcom game picker, direct
./fbneo-launch.sh snk        # SNK game picker, direct
./fbneo-launch.sh mslug      # direct romname, system detected from dir
./fbneo-launch.sh mslug -w   # windowed
```

Fullscreen is the default: the launcher injects `-fullscreen` (the SDL2 build
honors `fbneo.ini`, which defaults to windowed, so the flag is what forces it).
Passing `-w` drops `-fullscreen` and runs windowed instead.

If `fzf` is missing or no game is selected, the launcher aborts with an error
(`die`) — there is **no** fallback to the native FBNeo menu.

## Input / 8BitDo mapping

Capcom and SNK use incompatible button layouts — a single `p1defaults.ini` can't
serve both. The launcher solves this by auto-deploying the correct map before
each session:

| System | File | fire 1 | fire 2 | fire 3 | fire 4 | fire 5 | fire 6 |
|--------|------|--------|--------|--------|--------|--------|--------|
| Capcom | `p1defaults-capcom.ini` | South (WP) | West (MP) | L1 (HP) | East (WK) | North (MK) | R1 (HK) |
| SNK    | `p1defaults-snk.ini`    | South (A)  | East (B)  | West (C) | North (D) | L1 | R1 |

8BitDo SDL2 codes:

```
0x4080 = South  (face down)
0x4081 = East   (face right)
0x4082 = West   (face left)
0x4083 = North  (face up)
0x4089 = L1     (left shoulder)
0x408A = R1     (right shoulder)
```

### How the deploy works

`fbneo-launch.sh` copies `p1defaults-<system>.ini` to
`~/.local/share/fbneo/config/p1defaults.ini` before opening the game. That file
is the template FBNeo uses to generate `games/<rom>.ini` the first time a game is
opened.

> Games that already have their own `config/games/<rom>.ini` ignore
> `p1defaults` — the per-game `.ini` takes precedence. To force inheritance of
> the new layout, delete the game's `.ini`:
> `rm ~/.local/share/fbneo/config/games/<rom>.ini`

### Manual deploy

To force a layout without opening a game:

```bash
./apply-input.sh capcom
./apply-input.sh snk
```

## In-game keys

| Key | Action |
|-----|--------|
| `TAB` | Input menu |
| `F12` | Quit |
| `Alt+Enter` | Toggle fullscreen |

## Notes

- Arcade is light for the 6800H — no governor tuning needed.
- Audio via SDL2 → PipeWire; no `hw:0` workaround required.
- The real `fbneo.ini` isn't versioned (carries machine-specific paths).
