# Toucan (42, qwerty) — owner's guide & assistant playbook

This document does double duty: it's the **playbook the AI assistant uses to guide a
first-time owner**, and the **reference** for how the firmware works.

---

## ▶ For the assistant: how to onboard the owner

The person here most likely just got this keyboard and is **not a developer**. On your
first interaction, **proactively** greet them and offer to help — don't wait to be asked.
Say, in plain language, that you can help them:

1. **Flash the firmware** onto the two halves (Walkthrough A).
2. **Use ZMK Studio** to change keys *live in a browser*, no rebuilding (Walkthrough B).
3. **Customize the layout** to what they want (Walkthrough C).

Then ask what they'd like to do first. Keep it friendly and non-technical; only mention
Nix/CLI/build internals if they ask. Adapt to their OS where it matters (mostly Studio's
USB access). Walk through one step at a time and wait for them to confirm each step.

---

## Walkthrough A — Flash the firmware

The keyboard runs **ZMK** firmware. Each half (left and right) is flashed separately by
copying a `.uf2` file onto it. You only need to re-flash when changing firmware — for
*key changes*, prefer ZMK Studio (Walkthrough B), which needs no flashing.

**Step 1 — Get the firmware files.** Easiest, no tools required:
1. Open the repo on GitHub → **Actions** tab → click the most recent successful **build**
   run → under **Artifacts**, download **firmware** (a `.zip`).
2. Unzip it. Inside are two files — one for each half (names contain `toucan_left` and
   `toucan_right`).

*(Alternative for Nix users: `nix build` → `result/zmk_left.uf2` + `result/zmk_right.uf2`.)*

**Step 2 — Put a half into "flashing mode" (bootloader).** Plug **one** half into the
computer with a USB-C **data** cable (not a charge-only cable). Find the small reset
button on its controller board and **press it twice, quickly** (double-tap). The half
will pop up as a **USB drive** (often named `XIAO-SENSE`), like a flash drive.

**Step 3 — Copy the firmware.** Drag the matching `.uf2` onto that drive (the
`toucan_left` file for the left half, `toucan_right` for the right). The drive
disappears on its own when done — that's success; the half reboots.

**Step 4 — Repeat for the other half.** Unplug, plug in the other half, double-tap reset,
drag its `.uf2`.

**Step 5 — Pair over Bluetooth.** The **left** half is the one your computer connects to.
Turn on Bluetooth on the computer and pair with **"Toucan"**. (The right half talks to the
left wirelessly; you don't pair it separately.) Type to confirm it works.

> Tip: flashing wipes the Bluetooth pairing. If it won't reconnect later, "forget"/remove
> the keyboard in the computer's Bluetooth settings and pair fresh. See §Bluetooth below.

---

## Walkthrough B — ZMK Studio (change keys live, no flashing)

ZMK Studio lets you remap keys **instantly** from a web browser while the keyboard is
plugged in — no firmware rebuild, no flashing. It's the easy way to customize.

1. Use a **Chromium-based browser** — Chrome, Edge, or Brave. (Firefox and Safari can't
   do this.)
2. Plug the **left** half into the computer with a USB-C **data** cable.
3. Go to **app.zmk.studio** and click **Connect**, then pick the keyboard's serial port.
4. To make edits, **unlock**: on the keyboard, **hold an outer thumb key** (the GUI or ESC
   thumb) and tap **`B` + `N`** together. Now you can drag keys around and changes apply
   live.
5. Changes are saved on the keyboard and survive reboots — but a future *re-flash* resets
   them to the repo's layout. To make a change permanent across re-flashes, it has to go
   into `config/toucan.keymap` (offer to do that for them — Walkthrough C).

**USB access by OS** (only thing that differs):
- **Windows / macOS**: nothing to set up — just pick the port in the browser.
- **Linux**: the user must have permission on the serial port (`/dev/ttyACM*`). On most
  distros add their user to the **`dialout`** group (Arch: **`uucp`**), then log out/in.

---

## Walkthrough C — Customize the layout

Two ways, depending on what they want:

- **Quick / live changes → ZMK Studio** (Walkthrough B). Best for "swap this key,"
  "move that one." No tools.
- **Permanent / advanced changes → edit `config/toucan.keymap`**, then re-flash
  (Walkthrough A). Needed for things Studio doesn't cover (new combos, hold-tap behaviors,
  macros) or to make Studio changes survive a re-flash. If they want this, you (the
  assistant) can make the edit, build, and hand them the new firmware.

Ask what they actually want changed, then pick the simplest route. The current layout and
all the combos are in the **Reference** below — use it to explain what's already there.

---

# Reference

## Hardware
- **Beekeeb Toucan**: 42-key (3×6 + 3 thumbs per hand) **split**, **QWERTY**.
- **Seeed XIAO nRF52840** (`seeeduino_xiao_ble`) per half — BLE + USB + UF2 bootloader.
- **Left = central**: runs the keymap, connects to the host, has the **nice!view** display
  (`nice_view_gem`) + **RGB LED** (`rgbled_adapter`), and **ZMK Studio**.
- **Right = peripheral**: reports its matrix, has the **Cirque GlidePoint trackpad** (cursor
  works on every layer).
- Uses the published **`beekeeb/zmk-keyboard-toucan`** shield (pinned in `config/west.yml`),
  so there's no custom board in this repo. It defines a **42-key physical layout**, which is
  what makes the board fully editable in ZMK Studio.

## Firmware / build
- **ZMK `v0.3`** (a stable release — *not* `main`), plus the Toucan shield, Cirque module,
  and RGB-LED widget (`config/west.yml`).
- **Three ways to build:** GitHub Actions (`build.yaml` → downloadable artifact, the easy
  path); `nix build` (→ `result/*.uf2`); or `./` west locally for Nix users.
- The deep-sleep "won't wake" bug that affects ZMK `main` (#3207) does **not** apply on
  `v0.3`, so the sleep config is safe.

## Layers & layout
Layers (held with thumbs): `0 home`, `1 num`, `2 nav`, `3 spaces`. Home-row mods on the base
layer (`&hm`, tap-preferred). The **outer pinky column** is the full 3×6: base layer is
`TAB / CTRL / SHFT` (left) and `BSPC / ' / ESC` (right); other layers inherit it (`&trans`).
The `nav` layer's right cluster is arrows; the right half is the trackpad for pointing.

## Combos
Base-layer text combos have a `require-prior-idle-ms` misfire-guard; BT/Studio combos are on
the `spaces` layer (held GUI/ESC thumb) and cross-keyboard so a stray tap can't fire them:

| Combo | Keys | Output |
|---|---|---|
| caps lock | `F`+`J` | Caps Lock |
| jk→esc | `J`+`K` | Escape |
| underscore | `V`+`M` | `_` |
| dash | `R`+`U` | `-` |
| cut / copy / paste | `W`+`E` / `S`+`D` / `X`+`C` | Ctrl+X / C / V |
| question | both outer thumbs | `?` |
| **BT clear** (spaces) | `Z`+`/` | clear current Bluetooth profile |
| **BT next** (spaces) | `Q`+`P` | cycle Bluetooth profile |
| **Studio unlock** (spaces) | `B`+`N` | unlock ZMK Studio for editing |

> Left-hand cut/copy/paste is intentional — the right hand stays on the trackpad.

## Bluetooth
- ZMK keeps **5 profiles** (one per device); only the **active** one types. "Connected but
  nothing happens" = wrong profile → cycle **BT next** (`Q`+`P` on spaces).
- BT controls are **gated behind combos** (not single keys) so they can't be hit by accident
  — a stray "BT clear" wipes the pairing and causes reconnect loops.
- **Recovery**: clear *both* sides — forget the keyboard on the computer **and** do **BT
  clear** (`Z`+`/`) on the keyboard — then pair fresh.
- BLE is tuned for reliability: max TX power + improved connection params (`*.conf`).

## Files
```
config/toucan.keymap        # the layout — edit for permanent changes
config/toucan_{left,right}.conf  # per-half settings (pointing, sleep, BLE)
config/west.yml             # ZMK + Toucan-shield + module pins
build.yaml                  # GitHub Actions firmware build (downloadable artifacts)
flake.nix                   # nix build entry (+ `nix run .#keymap-pdf` to render the layout)
CLAUDE.md / SETUP.md        # assistant onboarding + this reference
```
