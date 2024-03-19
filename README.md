# Link's Grand Adventure 3
is a game in the ZQuest Classic engine. Play through 8 dungeons, before a final 9th, and save the princess!

## Randomizer (Archipelago)
Releases are compatible with [Archipelago Randomizer](https://archipelago.gg/)  
Randomization is done through Archipelago, with settings configured in a .yaml file.\
Related links:\
[APWorld Repo](https://github.com/EmilyV99/Archipelago/tree/lga3)  
[ZScript Archipelago API Repo](https://github.com/EmilyV99/ArchipelagoZScript)  
[Latest AP Downloads](https://github.com/EmilyV99/lga3-remaster/releases)  

### Settings
- SwordSanity: Should swords be randomized?
  - 'vanilla': All 4 swords are vanilla
  - 'vanilla_start': The starting sword is vanilla, adds the other 3 swords to the pool
  - 'rando_all': Adds all 4 swords to the pool
- KeySanity: Should keys be randomized?
  - 'vanilla': All keys are vanilla
  - 'only_big': Small keys are vanilla, adds the 8 Big Keys to the pool
  - 'all': Adds the 8 Big Keys and 16 Small Keys to the pool
- DungeonItemSanity: Should Maps/Compasses be randomized?
  - 'vanilla': Maps + Compasses are vanilla
  - 'map': Compasses are vanilla, adds the 8 Maps to the pool
  - 'compass': Maps are vanilla, adds the 8 Compasses to the pool
  - 'both': Adds the 8 Maps and 8 Compasses to the pool
- Magic Rock for Kill All: Should the 'Magic Rock' (which hints towards hidden item locations) be required for kill-all-enemies item locations?
- Easier Grinding: Improve loot tables and drop rates to decrease grind
- DeathLink: Should dying in your game kill other players playing with you? (If they also have this setting on)
- DeathLink Amnesty: If using DeathLink, allow yourself to die this many times without sending a death

### Logical access requirements:
- Basic combat
  - To enter the Mountain or Level 2, you need a Sword, Hammer, or the ability to fire Arrows
  - To enter the Desert or Graveyard, you need a L2 sword, Hammer, or BOTH the L1 Sword and ability to fire arrows
  - To enter the Ice, you need the same requirement as the Desert/Graveyard, as well as at least the L1 Tunic
  - To enter Level 8, you need L2 Traction Boots
  - To enter Level 9 or kill the 24-headed dragon, you need either the L3 sword and L1 tunic, OR either of the L2 Sword/Hammer combined with either the L2 tunic or the Divine Protection (and ability to use it)
- Ammo/Grinding
  - To be required to use ammo, you need any Sword, Boomerang, or the L2 candle (which all can cut grass!)
  - To be required to use Magic, you need either any of the above ammo requirements, or a Magic Ring (which regens your magic over time)
    - To be required to use Divine Protection, you also need 2 Magic Containers.
- Magic Rock
  - In your options, you can set "magic_rock_for_kill_all". If enabled, most Kill All Enemies -> Spawn an Item rooms will logically require the Magic Rock item (which, after standing in a room for a bit, will give you a notification if there is a secret hidden there). Notably, Boss Rooms of dungeons do not follow this requirement, and things which require killing all enemies to open a *DOOR* do not follow this requirement (only things that spawn an item in the room)
- Shops
  - Shops logically require that you have the ability to grind money (see Ammo/Grinding above), and that you can hold enough money to purchase the item. This logically accounts for both Wallet upgrades to increase your max money, and Coupon upgrades to reduce shop prices. (One wallet upgrade is enough to unlock every shop item in the game; but with 0 wallets, some items may require either 0, 1, 2, or 3 coupons)
- Victory
  - Goal: Standard - Defeat Ganon in Level 9, and progress to the credits in the next room. Requirements: L2 Sword, L2 Arrows (and ability to fire them), all 8 Triforce Fragments, and meet the "To enter Level 9" requirements in the "Basic combat" section above.

### Changes from vanilla
- 101 to 145 (depending on settings) item locations are randomized. (The `Scroll Holder`, which does nothing but status-check your currently known sword techniques, is not randomized; neither are the Green Tunic or Green Wallet, which are just inventory stand-ins for having no upgrades yet)
- "re-buyable" items will be repurchasable from the normal shop once you have been *sent* the item (this includes all 3 potions from the potion shop, and the Super Bombs from the super bomb shop). This acts as a new, separate "shop" location separate from the normal one (which now are "checks" instead)
- The L3/L4 sword do not require a certain number of heart containers to pick up, they are instead always acquirable. (both the items, and the locations)
- The triforce icon on the Overlay does not appear. Normally this *REPLACED* the boss key overlay, as in vanilla, it indicates you've already beaten the boss; obviously this logic doesn't work in rando, so it always shows the boss key instead.

### Randomizer Instructions
[Download Link](https://github.com/EmilyV99/lga3-remaster/releases)  
- Extract the ZIP from the latest download
- Place the `.apworld` in your archipelago install's `lib/worlds` folder
- Place the `.yaml` (edited with your settings) in your archipelago install's `Players` folder
- Select `Generate` in the Archipelago Launcher to generate your game
- Select `Host` in the Archipelago Launcher and choose the `.archipelago` file generated by the `Generate` to host locally
  - Currently does NOT work with the archipelago.gg web hosting; you will need to host the server locally (currently do not have `wss://` support)
 - Run `Links Grand Adventure 3.exe`
   - Bind your controls in `Settings->Controls`
   - Select `New File` and press `Start`
     - Type a name and press `Enter`
     - Select the file and press `Start`
       - Select `Start AP Randomizer` and press `Enter`
       - Input your IP/Port/Slot/Password, then select `Connect` and press `Enter`.
\
While playing:\
- Press `F6` to quit, allowing you either to `Continue` from the start of the dungeon (can get you unstuck, heals you), or `Save and quit` to save your progress, or `Quit without saving` to reset. Note that collected checks will not be reset.
