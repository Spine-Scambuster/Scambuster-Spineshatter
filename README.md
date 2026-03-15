![GitHub Downloads (all assets, all releases)](https://img.shields.io/github/downloads/Spine-Scambuster/Scambuster-Spineshatter/total?style=for-the-badge)
![Last Commit](https://img.shields.io/github/last-commit/Spine-Scambuster/Scambuster-Spineshatter?style=for-the-badge)
[![Latest Release](https://img.shields.io/github/v/release/Spine-Scambuster/Scambuster-Spineshatter?style=for-the-badge)](https://github.com/Spine-Scambuster/Scambuster-Spineshatter/releases)
[![Discord](https://img.shields.io/badge/Discord-Join-blue?logo=discord&style=for-the-badge)](https://discord.gg/82FMGTWG9j)

<div align="left">

# Scambuster - Spineshatter EU

We utilize the Scambuster addon framework to compile and distribute our list of identified offenders using publicly available data from the **[Spineshatter EU PvP](https://discord.gg/spineshatter)** community. This addon is specifically designed to work seamlessly with **[Scambuster](https://github.com/hypernormalisation/Scambuster)** addon framework. If you wish to receive in-game alerts upon joining a PUG, please follow the steps outlined below.

**Setup:**
- Download and run the **[Scambuster Anniversary Updater](https://github.com/Spine-Scambuster/Scambuster-Anniversary-Updater/releases)**.
- In the updater:
   - Select your WoW Anniversary installation folder.
   - Install or update:
     - **Scambuster (framework)**
     - **Scambuster–Spineshatter**
- The updater will:
   - Download the latest GitHub releases.
   - Install them into your `_anniversary_/Interface/AddOns` folder.
   - Remember your WoW path and, whenever you run it and click Update, check for and install the latest versions of both addons.

# Commands
`/sb`  Opens the Scambuster interface.

# Manual install from GitHub
If you cannot use an addon manager or prefer manual installation, follow the steps below.

Scambuster framework:
- https://github.com/hypernormalisation/Scambuster/releases/tag/0.1.8

Download: `Scambuster-0.1.8.zip`

Blacklist data (Spineshatter):
- https://github.com/Spine-Scambuster/Scambuster-Spineshatter/releases/

Download: `Scambuster-Spineshatter-1.0.85-classic.zip` (or newer if available)

### IMPORTANT:
After unzipping, open the folders and copy ONLY the addon folders inside:

- Scambuster-0.1.8\ `Scambuster`
- Scambuster-Spineshatter-1.0.85-classic\ `Scambuster-Spineshatter`

Copy both into:
- `World of Warcraft\_anniversary_\Interface\AddOns`

Restart WoW after copying.

Note:
- When a new version is released, download the new ZIP and replace the old addon folders in your AddOns directory.

# TradeGuard – Trade Protection

TradeGuard is an optional feature included with Scambuster–Spineshatter to protect your items and gold during trades. It is enabled by default and persists across relogs.

Features:
- First popup – Shows detailed info about the trade partner (name, level, class, guild, group/raid).
  - Note: If the trade target is level 70, this popup is skipped automatically.
- Warning popup – Alerts if trade items or gold change unexpectedly.
- Toggleable via commands: `/tradeguard on|off`
- Your preference is saved in TradeGuardDB inside the `Scambuster-Spineshatter.lua` SavedVariables file.

Commands:
- `/tradeguard on` – Enables TradeGuard protection.
- `/tradeguard off` – Disables TradeGuard protection.
- `/tradeguard` – Shows current status (enabled/disabled).

Notes:
- TradeGuard is on by default on first load.
- Once toggled, your choice is remembered even after logging out or restarting WoW.
- Works for Classic TBC Anniversary client only.
