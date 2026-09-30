class UZHoloDupe : HDWeapon {

    default {

        +Inventory.INVBAR
        +Weapon.WIMPY_WEAPON
        +Weapon.NO_AUTO_SWITCH
        // +HDWeapon.DROPTRANSLATION
        +HDWeapon.FITSINBACKPACK

        radius 8;
        height 24;

        Tag "$TAG_HOLODUPE";
        Inventory.PickupMessage "$PICKUP_HOLODUPE";

        HDWeapon.refID UZLD_HOLODUPE;
    }

    override bool addSpareWeapon(Actor newOwner) { return addSpareWeaponRegular(newOwner); }

    override HDWeapon getSpareWeapon(Actor newOwner, bool reverse, bool doSelect) { return getSpareWeaponRegular(newOwner, reverse, doSelect); }

    override double weaponBulk() { return ENC_HOLODUPE + (ENC_BATTERY_LOADED * 0.5 * weaponStatus[DUPE_BATTCNT]); }

    override double gunMass() { return 11; }

    override void initializeWepStats(bool idfa) {
        weaponStatus[DUPE_HEALTH] = 100;
        weaponStatus[DUPE_CHARGE] = 20;
        weaponStatus[DUPE_BATTCNT] = 2;
    }
    
    override string getHelpText() {
        LocalizeHelp();
        return (weaponStatus[DUPE_HEALTH] > 0 ? LWPHELP_FIRE..StringTable.Localize("$HOLODUPEWH_FIRE") : "")
            ..LWPHELP_RELOAD..StringTable.Localize("$HOLODUPEWH_RELOAD")
            ..LWPHELP_UNLOAD..StringTable.Localize("$HOLODUPEWH_UNLOAD")
        ;
    }

    override void drawHUDStuff(HDStatusBar sb, HDWeapon hdw, HDPlayerPawn hpl) {
        let charge = hdw.weaponStatus[DUPE_CHARGE];
        let numBat = hdw.weaponStatus[DUPE_BATTCNT];

        if (!charge) {
            sb.drawString(
                sb.mAmountFont,
                "00000",
                (-16, -8),
                sb.DI_TEXT_ALIGN_RIGHT|sb.DI_TRANSLATABLE|sb.DI_SCREEN_CENTER_BOTTOM,
                Font.CR_DARKGRAY
            );
        } else if (numBat) {
            sb.drawWepNum(charge, 20);
        }

        if (sb.hudLevel == 1) {

            let nextBat = HDMicroCell(hpl.findInventory("HDMicroCell"));

            sb.drawImage(
                HDCore.getMicroCellIcon(sb.getNextLoadMag(nextBat)),
                (-64, -4),
                flags: sb.DI_SCREEN_CENTER_BOTTOM,
                alpha: nextBat ? 1.0 : 0.3
            );
            sb.drawNum(hpl.countInv("HDMicroCell"), -56, -8, sb.DI_SCREEN_CENTER_BOTTOM);
        }

        let bob = hpl.wepbob * 0.2;

        sb.drawImage(
            "HDUPA0",
            (0, 20) + bob,
            sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
            scale: (2, 2)
        );

        for (int i = 0; i < numBat; i++) sb.drawImage(
            HDCore.getMicroCellIcon(clamp(charge - (i * 10), 0, 10)),
            (-5 + (i * 10), 40) + bob,
            sb.DI_SCREEN_CENTER|sb.DI_ITEM_CENTER,
            scale: (1, 1)
        );

        if (Level.time % 50 < 25) {
            let hp = weaponStatus[DUPE_HEALTH];
            if (hp <= 0) {
                sb.DrawString(
                    sb.pSmallFont,
                    StringTable.Localize("$HOLODUPE_INOPERABLE"),
                    bob,
                    sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_CENTER,
                    Font.CR_RED
                );
            } else if (hp < 100) {
                sb.DrawString(
                    sb.pSmallFont,
                    StringTable.Localize("$HOLODUPE_DAMAGED"),
                    bob,
                    sb.DI_SCREEN_CENTER|sb.DI_TEXT_ALIGN_CENTER,
                    Font.CR_FIRE
                );
            }
        }
    }

    states(Actor) {
        spawn:
            HDUP A -1;
            stop;
    }

    states {
        fire:
            // TNT1 AA 1 A_AddOffset(4);
            // TNT1 AAAA 1 A_AddOffset(9);
            // TNT1 AAAA 1 A_AddOffset(20);
            TNT1 A 10;
            TNT1 A 0 A_JumpIf(!pressingFire(),"ready");
            TNT1 A 1 {
                Actor a;
                int b;

                [b, a] = A_SpawnItemEx(
                    "UZHoloDupeBase",
                    12, 0, gunHeight() - 4,
                    cos(pitch) * 6, 0, -sin(pitch) * 6,
                    0,
                    SXF_NOCHECKPOSITION|SXF_TRANSFERPOINTERS|SXF_SETMASTER|SXF_SETTARGET
                );

                let dupe = UZHoloDupeBase(a);

                dupe.vel += vel;

                dupe.master = invoker.owner;
                dupe.health = invoker.weaponStatus[DUPE_HEALTH];
                dupe.charge = invoker.weaponStatus[DUPE_CHARGE];
                dupe.numBatts = invoker.weaponStatus[DUPE_BATTCNT];

                dropInventory(invoker);
                invoker.goAwayAndDie();
            }
            goto nope;

        // TODO: Fix instant battery consolidation side effect
        unload:
            TNT1 A 6 A_JumpIf(invoker.weaponStatus[DUPE_BATTCNT] <= 0, "nope");
            TNT1 A 3 A_StartSound("weapons/bfgopen", CHAN_WEAPON);
            TNT1 A 0 {
                let amt = min(invoker.weaponStatus[DUPE_CHARGE], 10);

                invoker.weaponStatus[DUPE_CHARGE] -= amt;

                invoker.weaponStatus[DUPE_BATTCNT]--;

                if (pressingUnload()) {
                    HDMagAmmo.giveMag(self, "HDMicroCell", amt);
                } else {
                    HDMagAmmo.spawnMag(self, "HDMicroCell", amt);

                    setWeaponState("nope");
                }
            }
            TNT1 A 0 A_StartSound("weapons/pocket", CHAN_POCKETS);
            goto nope;

        reload:
            TNT1 A 0 A_JumpIf(invoker.weaponStatus[DUPE_BATTCNT] >= 2, "nope");
            TNT1 A 20 A_StartSound("weapons/pocket", CHAN_POCKETS);
            TNT1 A 10 A_JumpIf(HDMagAmmo.nothingLoaded(self, "HDMicroCell"), "nope");
            TNT1 A 6 A_StartSound("weapons/bfgopen", CHAN_POCKETS);
            TNT1 A 0 {
                A_StartSound("weapons/bfgclick2", CHAN_WEAPON);

                invoker.weaponStatus[DUPE_CHARGE] += HDMagAmmo(findInventory("HDMicroCell")).takeMag(true);
                invoker.weaponStatus[DUPE_BATTCNT]++;
            }
            goto nope;

        user3:
            TNT1 A 0 A_MagManager("HDMicroCell");
            goto ready;
    }
}

// class UZHoloDupeController : HDWeapon {
//     Array<UZHoloDupeBase> bases;
//     default {
//         +Inventory.INVBAR
//         +Weapon.WIMPY_WEAPON
//         +NOINTERACTION
//         +HDWeapon.DROPTRANSLATION

//         Tag "$TAG_HOLODUPE_CONTROLLER";

//         Inventory.icon "HDPCB0";

//         Weapon.selectionOrder 1013;
//     }
// }

class UZHoloDupeBase : HDUPK {

    Actor holo;

    int charge;
    int chgTimer;
    int numBatts;

    default {
        +SHOOTABLE
        +FRIENDLY
        +DONTGIB
        +NOBLOOD
        +NOBOUNCESOUND

        radius 8;
        height 24;

        health 100;

        Tag "$TAG_HOLODUPE";

        HDUPK.pickupMessage "$PICKUP_HOLODUPE";
    }

    action void A_ProjectHologram() {

        // if we already have a hologram, quit.
        if (invoker.holo) return;

        invoker.holo = Actor.spawn('UZHoloDupeHologram', invoker.pos + (0, 0, invoker.height));

        // If we didn't spawn a hologram, quit.
        if (!invoker.holo) return;

        invoker.holo.master = invoker;

        // Set the hologram's tracer to the master/owner
        if (invoker.master) invoker.holo.tracer = invoker.master;
    }

    action void A_UnProjectHologram() {

        // If we already don't have a hologram, quit.
        if (!invoker.holo) return;

        invoker.holo.destroy();

        invoker.frame = 0;
    }

    states(Actor) {
        spawn:
            HDUP A 1 A_JumpIf(charge > 0 && vel.z == 0, "boot");
            loop;

        give:
            #### # 0 {
                let dupe = UZHoloDupe(Actor.spawn('UZHoloDupe', pos));

                dupe.weaponStatus[DUPE_HEALTH] = health;
                dupe.weaponStatus[DUPE_CHARGE] = charge;
                dupe.weaponStatus[DUPE_BATTCNT] = numBatts;

                if (dupe) GrabThinker.grab(target, dupe);

                A_UnProjectHologram();

                destroy();
            }
            goto spawn;

        boot:
            #### # 0 A_JumpIf(!master, "spawn");
            #### # 10;
        turnOn:
            #### # 0 A_ProjectHologram();
        running:
            #### BC 5 {
                A_ProjectHologram();

                A_LookEx(LOF_NOJUMP|LOF_NOSOUNDCHECK|LOF_NOSEESOUND|LOF_DONTCHASEGOAL, fov: 360, label: "running");

                if (target) {
                    target.target = holo;
                    target = null;
                }

                chgTimer++;

                if (chgTimer > TICRATE) {
                    charge--;
                    chgTimer -= TICRATE;
                }

                if (charge <= 0) setStateLabel("shutdown");

                if (random[dukesnukesrand](0, default.health) > health) A_UnProjectHologram();
            }
            loop;

        shutdown:
            #### A 1 {
                A_StartSound("holodupe/shutdown");

                A_UnProjectHologram();
            }
            goto spawn;

        death:
            #### A -1;
            stop;
    }
}

class UZHoloDupeHologram : Actor {

    default {
        +BRIGHT
        +ISMONSTER
        +NOBLOCKMONST
        +SHOOTABLE
        +FRIENDLY
        +NOFEAR
        +DONTGIB
        +NOBLOODDECALS
        +GHOST
        +NOBOUNCESOUND
        +DONTTHRUST
        // +NOINTERACTION

        height HDCONST_PLAYERHEIGHT;
        radius HDCONST_PLAYERRADIUS;
        mass Int.MAX;
        gravity 0;
        painChance 128;

        health Int.MAX;

        bloodType "IdleDummy";

        Tag "$TAG_HOLODUPE_HOLOGRAM";
    }

    override void postBeginPlay() {
        super.postBeginPlay();

        if (tracer) {
            A_SetRenderStyle(10.0, STYLE_AddShaded);
            translation = tracer.translation;

            if (HDPlayerPawn(tracer) && tracer.player) {
                SetShade(tracer.player.getColor());

                A_AttachLight(
                    'UZHoloDupeLight',
                    DynamicLight.PointLight,
                    tracer.player.getColor(),
                    HDCONST_ONEMETRE * 2,
                    HDCONST_ONEMETRE * 8,
                    DynamicLight.LF_ADDITIVE|DynamicLight.LF_ATTENUATE
                );
            }

        }
    }

    override void tick() {
        super.tick();

        health = default.health;

        if (!master) {
            destroy();

            return;
        }

        SetOrigin(master.pos + (0, 0, master.height), false);
    }

    states {
        spawn:
            TNT1 A 1 {
                if (tracer) {
                    angle = tracer.angle;
                    sprite = tracer.sprite;
                    frame = tracer.frame;
                }
            }
            loop;

        pain:
            HOLO # 1 {
                frame = random[dukesnukesrand](0, 13);

                if (!random[dukesnukesrand](0, TICRATE)) setStateLabel("spawn");

                UZHoloDupeBase(master).chgTimer++;
            }
            loop;
    }
}

class UZHoloDupeSpawn : IdleDummy {
    states {
        spawn:
            TNT1 A 1 noDelay {
                let dupe = UZHoloDupe(spawn("UZHoloDupe", pos, ALLOW_REPLACE));

                if (!dupe) return;

                HDF.transferSpecials(self, dupe);

                // dupe.charge = 20;
                // dupe.numBatts = 2;

                // if (random[dukesnukesrand]()) A_SpawnItemEx("UZHoloDupeController", 0, -8, flags: SXF_NOCHECKPOSITION);
            }
            stop;
    }
}

enum UZHoloDupeStatus {
    DUPE_FLAGS    = 0,
    DUPE_HEALTH   = 1,
    DUPE_CHARGE   = 2,
    DUPE_BATTCNT  = 3,

    DUPEF_ENABLED = 1
}