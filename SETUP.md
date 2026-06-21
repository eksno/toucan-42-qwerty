# Toucan (42, qwerty) — repo & firmware reference

Context document for working on this keyboard's ZMK firmware. Reference info, not a
step-by-step guide. Platform-agnostic; OS-specific notes are inline.

---

## 1. Hardware

- **Beekeeb Toucan**: a 42-key (3×6 + 3 thumbs per hand) **split** wireless keyboard, **QWERTY** base layout. (Same physical board as the 36-key config — this layout uses the full outer pinky column instead of leaving it unbound.)
- **Controller**: a **Seeed XIAO nRF52840** (`seeeduino_xiao_ble`) per half. nRF52840 = BLE + USB + Adafruit UF2 bootloader.
- **Left half = central**: runs the keymap, talks to the host, carries a **nice!view** display (`nice_view_gem` widget) and the **RGB LED widget** (`rgbled_adapter`). **ZMK Studio** is enabled here.
- **Right half = peripheral**: reports its matrix, carries a **Cirque Pinnacle GlidePoint trackpad** (`CONFIG_ZMK_POINTING`/`CONFIG_ZMK_MOUSE`). Cursor works on every layer.
- Uses the upstream **published** Toucan shield from the `zmk-keyboard-toucan` module (pinned in `config/west.yml`) — there is **no custom shield in this repo**, so don't go looking for `boards/`.

## 2. Firmware stack & versions

- **ZMK pinned to the stable tag `v0.3`** (see `config/west.yml`), plus `zmk-keyboard-toucan` (the Toucan shield) and `zmk-rgbled-widget`. This is a **released ZMK, not `main`** — notably, the deep-sleep "central won't wake" regression that affects ZMK `main` (zmkfirmware/zmk#3207) does **not** apply here, so the deep-sleep config is safe as-is.
- Built reproducibly via a **Nix flake** using [`zmk-nix`](https://github.com/lilyinstarlight/zmk-nix). The pinned Zephyr deps are fixed-output, keyed by `zephyrDepsHash` in `flake.nix` (update it if you change the ZMK/Zephyr pins).
- GitHub Actions build the firmware on push (`.github/workflows/`).

## 3. Repo layout

```
flake.nix                  # nix build entry: firmware-left (central+display+Studio) / firmware-right; also a keymap-pdf app
config/
  toucan.keymap            # THE KEYMAP — edit this
  toucan_left.conf         # left Kconfig: pointing, battery, sleep, BLE tuning
  toucan_right.conf        # right Kconfig
  west.yml                 # ZMK + Toucan-shield + rgbled-widget pins (the build manifest)
.github/workflows/         # CI builds
SETUP.md                   # this file
```

## 4. Building & flashing (concepts)

**Build** (any machine with Nix + flakes):
- `nix build` → `result/zmk_left.uf2` and `result/zmk_right.uf2`. First build fetches the pinned Zephyr deps (slow); later builds are cached.
- `nix run .#keymap-pdf` renders the keymap to a PDF (uses `keymap-drawer`).

**Flash** (UF2 bootloader — same on Linux/macOS/Windows):
- Double-tap the XIAO reset to enter the **UF2 bootloader**; it mounts as a small **USB mass-storage drive**. Copy a `.uf2` onto it; it flashes and reboots. (Drag-and-drop, no tooling.)
- **Which half:** the **left/central** holds the keymap, combos, layers, display, and Studio — so **keymap changes only need the left reflashed**. The right only needs it for firmware/shield changes. Flashing wipes the BLE bond, so re-pair afterward.

## 5. ZMK Studio (live keymap editing)

- **What it is**: edit the keymap **live over USB** from a browser — no rebuild/flash. Enabled on the **left** half (`enableZmkStudio = true` in `flake.nix`).
- **Client**: the web app at **app.zmk.studio**, which needs a **Chromium-based browser** (Chrome/Edge/Brave — WebSerial; Firefox/Safari don't support it). A desktop app also exists.
- **Unlock**: Studio connects read-only; to edit, trigger `&studio_unlock` — bound here to a combo: **hold an outer (ESC or GUI) thumb to reach the spaces layer + press `B` + `N`**.
- **Serial access by OS** (the one real platform difference):
  - **Linux**: `/dev/ttyACM*`, owned `root:dialout` (or `uucp` on Arch) — the user must be in that group.
  - **macOS**: `/dev/tty.usbmodem*`, no setup.
  - **Windows**: a COM port, no setup — just pick it in the browser prompt.
- **Model**: Studio edits persist on the keyboard's flash but are **separate from this repo**. The repo keymap is the baseline a **reflash restores** — so reflashing overwrites Studio-only edits. Fold anything you want to keep back into `config/toucan.keymap`.

## 6. Power / sleep / BLE

In `toucan_{left,right}.conf`:
- `CONFIG_ZMK_IDLE_TIMEOUT=30000` (30 s light idle — also gates trackpad power), `CONFIG_ZMK_SLEEP=y` + `CONFIG_ZMK_IDLE_SLEEP_TIMEOUT=3600000` (60-min deep sleep), `CONFIG_ZMK_PM_SOFT_OFF=y` (the PM machinery the Cirque driver needs). On `v0.3` this is all safe.
- **BLE tuning (ported from the Corne):** `CONFIG_BT_CTLR_TX_PWR_PLUS_8=y` (max TX power, best low-risk reliability knob) and `CONFIG_ZMK_BLE_EXPERIMENTAL_CONN=y` (improved connection params — the first flag to disable if any BLE oddness shows up).

## 7. Bluetooth model & recovery (cross-platform)

- ZMK keeps **5 BLE profiles**; only the **active** one receives keystrokes. "Connected but nothing types" = wrong active profile → cycle `BT_NXT`.
- **Controls are gated** (see §8): `BT_CLR` (clears the current profile's bond) and `BT_NXT` (cycle) live behind spaces-layer combos, **not lone keys** — a stray `BT_CLR` wipes the bond on the keyboard while the host keeps the old key, so every reconnect then drops in ~0.5 s.
- **Desync recovery**: clear **both** sides — forget the keyboard on the host *and* `BT_CLR` on that profile — then pair fresh. Clearing one side leaves a half-bond that reproduces the symptom.

## 8. Keymap (`config/toucan.keymap`)

**Layers** (thumb-activated): `0 home`, `1 num`, `2 nav`, `3 spaces`. Home-row mods via `&hm` (tap-preferred, 185 ms). Both outer thumbs are `&lt 3` (either reaches the spaces layer). The `nav` layer's right-hand cluster is arrows; the right half is the trackpad for pointing.

**Combos** — base-layer text combos are `layers=<0>` + `require-prior-idle-ms` (misfire guard); BT/Studio combos are `layers=<3>` (only while holding a GUI/ESC thumb) and cross-keyboard so a single tap can't fire them:

| Combo | Keys (positions) | Output | Layer |
|---|---|---|---|
| caps | `F`+`J` (16,19) | Caps Lock | 0 |
| jk→esc | `J`+`K` (19,20) | Escape | 0 |
| under | `V`+`M` (28,31) | `_` | 0 |
| dash | `R`+`U` (4,7) | `-` | 0 |
| cut | `W`+`E` (2,3) | Ctrl+X | 0 |
| copy | `S`+`D` (14,15) | Ctrl+C | 0 |
| paste | `X`+`C` (26,27) | Ctrl+V | 0 |
| ? | both outer thumbs (36,41) | `?` | 0 |
| **BT clear** | `Z`+`/` (25,34) | `&bt BT_CLR` | 3 |
| **BT next** | `Q`+`P` (1,10) | `&bt BT_NXT` | 3 |
| **Studio unlock** | `B`+`N` (29,30) | `&studio_unlock` | 3 |

> Left-hand cut/copy/paste is deliberate: the **right half is the trackpad**, so you edit one-handed with the left while the right points.

**Position numbering** (for adding combos): row-major 0–41. Row 1 = `0–11`, row 2 = `12–23`, row 3 = `24–35`, thumbs = `36–41` (36–38 left, 39–41 right). The outer-pinky columns (`0,11,12,23,24,35`) are the full 3×6 layout: on the base layer they're `TAB / CTRL / SHFT` (left) and `BSPC / ' / ESC` (right); on other layers they're `&trans` (inherit base).

## 9. Notes

- HRM is tap-preferred. If misfires bother you, the community-standard upgrade is positional/"timeless" home-row mods: `flavor="balanced"` + `hold-trigger-key-positions` (opposite hand) + `hold-trigger-on-release` + `require-prior-idle-ms`.
- No `build.sh` fast-path in this repo (it builds via `nix build` / CI). A west-based one can be added if seconds-fast local iteration is wanted.
