version 4.14

// Loadout Codes (RefIDs)
const UZLD_DEVASTATOR         = "dvt";
const UZLD_HOLODUPE           = "hdp";
const UZLD_LASERTRIPBOMB      = "ltb";
const UZLD_PIPEBOMB           = "pbg";
const UZLD_PIPEBOMB_DETONATOR = "pbd";
const UZLD_RIPPER             = "rip";

// Encumbrance/Bulk Constants
const ENC_HOLODUPE            = 55;
const ENC_LASERTRIPBOMB       = 12;
const ENC_PIPEBOMB            = 19;
const ENC_PIPEBOMB_DETONATOR  = 10;

// Items
#include "zscript/undeadzeratul/dukes-nukes/items/holo-dupe/HoloDupe.zs"

// Weapons
#include "zscript/undeadzeratul/dukes-nukes/weapons/devastator/Devastator.zs"
#include "zscript/undeadzeratul/dukes-nukes/weapons/laser-tripbombs/LaserTripBombs.zs"
#include "zscript/undeadzeratul/dukes-nukes/weapons/pipe-bombs/PipeBombs.zs"
#include "zscript/undeadzeratul/dukes-nukes/weapons/ripper/Ripper.zs"

// Event Handlers
#include "zscript/undeadzeratul/dukes-nukes/handlers/SpawnHandler.zs"
