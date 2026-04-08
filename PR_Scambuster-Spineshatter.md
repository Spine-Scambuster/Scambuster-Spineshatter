# Guild Blacklist Support

## Dependency Notice

**This PR requires a companion PR in the [Scambuster](https://github.com/shockedarmor/Scambuster/tree/guild-wide-listing) repo to function.**

This PR adds the data pipeline and guild list for Spineshatter. The Scambuster PR adds the framework infrastructure that reads and enforces it. Both must be merged and deployed together.

---

## Overview

Wires up the Spineshatter provider to support guild-level blacklisting using the new `guild_data` field introduced in the companion Scambuster framework PR. Adds `t.guild_table` to `list.lua` as the single place where guild blacklist entries are maintained and distributed to all users via addon updates.

When a blacklisted guild member is moused over, targeted, traded with, or joins the player's group, a warning fires both in the tooltip and as a chat message.

---

## What Changed

### `core.lua`

Added `guild_data` to the provider table registered with the Scambuster framework:

```lua
local provider_table = {
    name        = t.my_name,
    provider    = t.my_provider,
    description = t.my_description,
    url         = t.my_url,
    realm_data  = { [t.my_realm] = t.case_table },
    guild_data  = { [t.my_realm] = t.guild_table },
}
```

The realm key `t.my_realm` (set to `"Spineshatter"` in `settings.lua`) ensures these guild entries are only ever active on a Spineshatter character. The framework enforces this at load time and will never apply Spineshatter guild entries on any other realm.

### `list.lua`

Added `t.guild_table` near the top of the file, between `t.version` and `t.case_table`. This is the authoritative place to add and remove guild blacklist entries for distribution to all users.

### `Scambuster-Spineshatter.toc`

Removed `GuildGuardDB` from `SavedVariables`. Guild blacklisting is now handled entirely by the Scambuster framework using the existing `ScambusterDB` SavedVariable.

---

## How to Add a Blacklisted Guild (for list maintainers)

Open `list.lua` and find the `t.guild_table` block near the top of the file. Add an entry:

```lua
t.guild_table = {
    ["GuildNameHere"] = {
        reason = "Brief description of why this guild is blacklisted.",
        added  = "YYYY-MM-DD",
    },
}
```

Multiple guilds:

```lua
t.guild_table = {
    ["Blablabla"] = {
        reason = "Guild leadership organised mass trade scam.",
        added  = "2025-04-08",
    },
    ["Another Guild"] = {
        reason = "Repeat ninja looters, multiple SR incidents.",
        added  = "2025-04-08",
    },
}
```

Commit and push. Users receive the updated guild list on their next addon update with no further action required.

To remove a guild, delete its entry from `t.guild_table` and push. The removal takes effect for all users on next update with no stale data left in their SavedVariables.

**Guild name matching is case and space sensitive. Always use the exact in-game capitalisation.**

---

## How to Add a Blacklisted Guild In-Game (for individual players)

Players can maintain a personal guild blacklist at runtime using the `/sbguild` command. Personal entries only affect that player's own client and are not distributed to other users.

```
/sbguild add <GuildName> | <Reason>    Add a guild
/sbguild remove <GuildName>            Remove a guild
/sbguild list                          Show all blacklisted guilds
/sbguild on / off                      Toggle guild blacklisting
```

Examples:
```
/sbguild add Blablabla | Mass scam, ninja looted SR run
/sbguild remove Blablabla
/sbguild list
```

---

## Realm Scoping

Guild entries in `t.guild_table` are keyed under `t.my_realm` in the provider table. The Scambuster framework only loads entries for the realm the player is currently logged into. A guild blacklisted here on Spineshatter will never trigger a warning for a player on any other realm, even if a guild with the same name exists there.
