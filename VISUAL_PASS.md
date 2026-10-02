# Rogue Waves visual pass

Open project.godot in Godot 4.5 or 4.5.1 and let the editor finish importing. The supplied Windows debug template identifies itself as 4.5.1.stable.official. The project folder remains TugasGIMPARTY13.

## Visual R11 build verification

Press F9 while the game has focus. The panel must say RW VISUAL R11 · 2026-09-30. Open TugasGIMPARTY13/project.godot, let Godot finish importing, then use F5 to run the project. This ZIP contains source and the supplied export templates, not an exported game.

## R11 full screen Hard transition and enemy collisions

Press F9 to confirm RW VISUAL R11. These notes supersede the earlier button flash behavior and enemy collision rules. The R10 normal mapping trial and its controls remain available without further changes.

The Hard button now immediately covers the viewport with an opaque pale white ColorRect on its own CanvasLayer above menus and other overlays. It holds for 0.08 seconds, then fades over 0.62 seconds. Hard weather reaches full intensity beneath the flash in 0.35 seconds, so the fade reveals stormy water. This is independent of the small ambient lightning wash and bolt graphic. The flash follows viewport size and stays fixed to the screen during the departing camera movement. It clears on menu reset or failed departure. Normal mode does not trigger it. F6 still disables visual extras, including this flash.

Ground enemies now detect other enemies and use the same lethal contact rule as hitting an obstacle. Gunboats, both bomber directions, sharks and both siren directions can destroy each other on contact. Both participants die once, even if physics delivers both contact signals. Parrots are excluded from ground ramming and obstacle collisions. Charging sharks retain their usual lethal contact behavior; their special exemption below applies to blast damage.

Gunboat cannonballs now detect ground enemies as well as the player and obstacles. Each deals one damage, is consumed at its first valid impact, and ignores the gunboat that fired it. Parrots do not intercept these ground cannonballs. Existing bullet immunity from a parrot and charging shark immunity still apply to projectile damage. Shooter identity is stored as an instance ID, so a bullet can outlive its shooter safely. Cannonballs move on physics ticks. Barrels are tested before ignoring other projectiles, so cannonballs can ignite them. The old firing routine accidentally emitted two identical center shots; it now emits one center shot, with the existing optional Hard side shots retained.

Damaging barrel explosions kill all ground enemy variants in their area, including enemies protected by a parrot. Parrots and actively charging sharks are exempt. A shark that stops charging inside a still-active blast becomes vulnerable again. Each blast handles a target only once. Hitting the player no longer disables the entire blast, so other targets and barrel chain reactions can still be affected. Damage ends with the authored explosion animation. Ordinary death and impact explosion visuals remain harmless. Existing parrot airstrikes already use the damaging barrel explosion type, so they share the same ground-target rules.

Enemy collision and explosion deaths retain existing rewards, drops and death effects. Bomber death still drops its barrel. Friendly fire deals ordinary projectile damage rather than instantly destroying a full-health boat or obstacle. Collision sizes, projectile speed, explosion radius, original artwork and original scene files are unchanged.

Validation used official Godot 4.5. All 101 focused runtime assertions passed. Tests used real physics overlaps for all 21 pairs of ground variants, travelling projectiles in both modes, shooter exclusion, one hit per projectile, obstacle damage, barrel ignition, parrot exemptions, all ground blast targets under parrot protection, charging shark immunity and its expiry, cosmetic explosion safety, chain reactions, player and later enemy hits from the same blast, and flash coverage and timing. A mixed encounter run simulated 24 seconds in each mode with repeated gunboat, bomber, shark, siren, parrot and timed barrel spawns. It spawned 76 enemies in Normal and 80 in Hard with no gameplay script errors. Known dummy audio resource warnings remain at headless shutdown.

Tests were headless and do not verify rendered appearance. This ZIP includes source and the supplied export templates, not a new exported executable. Original asset bytes and archive integrity are checked during packaging; source hashes are in R11_SOURCE_MANIFEST.json.

Tuning and behavior changes are in scripts/storm_fx.gd, dummy.gd, enemybullet.gd and explosion.gd.

## R10 limited normal map trial

Press F10 from the main menu to open the comparison. F7 toggles normals both in the comparison and during gameplay. F9 verifies R10. In the comparison, Space repeats the explosion flash, L toggles a slow moving light, and Escape returns to the main menu. The controls also have buttons. F10 deliberately does nothing during an active run. The comparison has no combat controllers, collision bodies, score changes, damage or save writes.

The left side uses the original R9 actor shader. The right side uses the same artwork, pose, scale, light path, energy, color, radius and timing with procedural normal mapping enabled. Different light masks isolate the two sides. Subjects are shown at 1.65 times gameplay size, stated on screen. Both sides cycle the player's idle and turning poses together. The moving light is off initially, so repeated flashes can be inspected on their own. Flash radius is 360 pixels, lifetime 0.24 seconds and energy follows VisualFX.event_light_energy, matching gameplay. The optional moving light provides a longer look at the surface response. Neither mode adds specular shine.

The trial applies to player shipbase and cannon in all three existing poses, gunboat hull and cannon, and barrels. Each of the nine existing texture variants has its own geometric profile. Other actors, player portraits, alternate weapon upgrades and the sea are outside this trial. The gameplay sprite preview near the end of departure uses the player profiles too; the earlier composite menu sprite retains its existing lighting.

These are analytic normal maps calculated in the shader, not new painted PNG maps. Broad rounded hull, cannon tube and barrel surfaces are aligned to the source texture coordinates. No brightness-to-height conversion is used, so dark outlines and colored paint are not interpreted as grooves. The barrel's painted white foam is excluded from its curved surface response. Original texture, animation and scene files are unchanged. The approach is intentionally an approximation for judging the value of normal mapping before authoring detailed maps for every character.

The bright base art remains unchanged when no event light reaches it. Normal mapping only alters the direction-dependent contribution of lights. The response is bounded between 0.45 and 1.45 times the flat light contribution. The default normal strength is 0.65, editable on VisualFX. Event lights now have a virtual height of 160 pixels for a useful surface response. F7 OFF restores the original shader rather than merely reducing normal depth. The material instance and its shared hit flash, recoil, cloud and visual motion parameters survive the switch. F6 disables the trial with other visual extras. The normal toggle lasts for the session and is not saved as a player setting.

Validation used official Godot 4.5 import and 128 focused runtime assertions, all passing. Tests covered both modes, comparison entry and exit, paired light paths and masks, flash cleanup, all player poses, exact original shader restoration, material identity, preserved hit and motion parameters, recoil, supported actor scope, retained barrel oil warnings and drift, and the gameplay event light height and mask. The known dummy audio shutdown resource warnings remain.

These tests were headless. They validate scene behavior and integration, not rendered appearance or GPU performance. Judge the visual strength in the F10 comparison before expanding this trial. The ZIP includes the project and supplied templates, not an exported executable.

Tuning is in scripts/normal_trial_surface.gd, actor_normals.gdshader, normal_comparison.gd, visual_fx.gd and visual_pulse.gd. The normal profile table uses texture-pixel centers and radii. Color artwork is never regenerated or overwritten.

## R9 actor weather, departure and shark corrections

These notes supersede the R8 cloud, lightning timing, departure foam and shark charge behavior below.

The sea, player hull and weapons, enemy ships, sharks, sirens, parrots, wrecks, bones, barrels, pickup crates and animated foam now sample one shared cloud pattern in world space. StormFX updates its shared clock and strength once per frame, and both stop with pause. Clouds locally reduce brightness by up to 26 percent in Hard mode. Normal mode has no cloud shading. Hit flash colors are applied after the shadow, while HUD, projectiles, warning areas and explosion artwork retain their existing treatment. Existing event lights still illuminate actor sprites. F6 disables the added cloud shading with the other visual extras.

Pressing Hard starts the lightning flash immediately, even at zero storm intensity. Rain and sea tint build beneath it over the existing 0.85 second transition. There is no delayed flash at 0.95 seconds. The brief cool light wash now reaches the bottom of the screen as well as the top. Normal selection and return to menu clear weather, and a failed departure clears it too.

The old departure foam inherited the menu ship root scale of 0.06, reducing it to six percent of its intended size. Departure water now uses a separate world transform, below the hull, with the same trail scale and local offset as gameplay. Both launch and camera follow update it in the same tween step as the ship. Wake emission uses a 65 pixel world offset rather than the scaled menu offset. Foam stays visible through the late hull crossfade and the gameplay handoff.

Sharks now separate approach, warning and charge movement. They cannot swim using the previous charge velocity during the second windup. The Hard retry retains its 40 percent chance but is decided only once, before crossing the inner turn boundary, using the fixed 1920 by 1080 world arena instead of window dimensions. The turn margin is 130 pixels. A retry holds position for a one second reaim, locks direction for the existing transition animation, then launches its second and final charge. The windup duration is calculated from that animation's frame durations and playback speed. Its warning ring follows the transition animation. The charge counter records actual starts and never resets between dashes. The old edge teleport and indefinite despawn exception are removed. Normal sharks still charge once. Stun pauses the windup and game over stops the behavior.

Validation used the official Godot 4.5 editor import and 120 focused headless runtime assertions with zero failed assertions. Tests exercised both menu buttons and gameplay handoffs, immediate flash visibility, absence of the old delayed strike, trail visibility and full global scale, same-frame attachment, prop materials, hit feedback, weather pause and toggle, retained bomb drift and oil radius, all four shark turn boundaries, reaim and windup stability, stun, maximum two charges and final despawn. The archive is checked against R8 to preserve original artwork, sound, scene, import, git and supplied export template bytes. Source hashes are recorded in R9_SOURCE_MANIFEST.json.

Headless runs do not render shaders, so final cloud strength, lightning balance and foam appearance still need visual confirmation in the editor. The known dummy audio shutdown resource warnings remain. This ZIP contains source and the supplied templates, not a new exported executable.

Tuning lives in scripts/cloud_shadow.gdshaderinc, storm_fx.gd, storm_rain.gd, menu_departure.gd and dummy.gd.

## R8 footage corrections

These changes supersede the R7 weather, departure wake and explosion light values below. The 26 second Hard mode recording showed the departure ship without foam until its final blend and little separation between storm effects and the painted sea.

Rain now uses 96 thin diagonal streaks with faint dark edges, drawn independently of the sea texture. It remains below the HUD. A brief branching lightning silhouette and an upper edge light wash make distant lightning distinct from painted foam. Hard weather reaches full strength over 0.85 seconds; departure lightning triggers at 0.95 seconds instead of firing while the weather is still mostly transparent. During departure, that strike also lights the ship locally. Subsequent lightning is spaced 10 to 17 seconds apart, with the first ambient strike 8 to 12 seconds after the menu reset. Clouds move faster and cast stronger localized shadows over the sea. The underlying storm tint is slightly lighter to offset these shadows. Normal mode remains bright.

The menu ship gets the existing animated foam immediately when departure starts, before the gameplay sprite blend. The foam uses the same frame smoothing as gameplay. Separate wake puffs trail the moving ship and drift at the menu ocean speed. World anchored effects avoid doubling the menu's temporary position offset. The final ship and camera positions remain unchanged.

Explosion light radius increases from 170 to 360 pixels, so it reaches past the opaque blast artwork. It lasts 0.24 seconds, with a short initial hold and 1.45 peak light energy. The additive water glow is stronger. This remains a local flash, with at most six real event lights at once. HUD and projectile colors remain outside its light mask.

Every barrel shows an oil spill warning from its first frame. The warning reads both the radius and center offset from the real explosion collision shape, currently radius 257.03113 pixels and offset 0 by 2. A dark translucent pool and irregular colored sheen distinguish it from normal waves. Timed barrels have a small warm fuse ripple near the barrel. The oil is a warning only and has no collision. It disappears at detonation. The old circle drawn over an active explosion is removed. Explosion damage, collider size, animation timing and chain reactions remain unchanged.

All barrels drift at exactly the current speed, 185 pixels per second in Normal or 215 in Hard. The timed Hard barrels keep their original 1.0 to 1.5 second fuse, but lose the old 1.8 movement multiplier. Gentle sprite bobbing changes no collision geometry. Cleanup waits until the full oil spill leaves the bottom of the arena. The oil warning remains available when F6 disables visual extras.

R8 passed official Godot 4.5 import and focused headless runtime checks in both modes. Checks cover warning radius and position, ordinary and timed barrel speed, fuse detonation, pause, oil cleanup, event light lifetime, rain overlay sizing, early departure foam, world positions of wake puffs, storm timing and the gameplay handoff. Original artwork and scene files are unchanged. Headless testing does not render the graphics, so the final visual balance still needs checking in the editor. The retained Ogg playback warnings at headless engine shutdown remain as noted below.

R8 tuning lives in scripts/storm_rain.gd, storm_fx.gd, ocean_motion.gdshader, menu_departure.gd, visual_fx.gd, barrelbomb.gd and bomb_warning.gd.

## R7 current, pace, impacts and storm

The settings below supersede older revision notes. Press F9 to confirm R7. Existing PNGs, sound files, collision shapes, bullet speeds, damage and score rewards are unchanged. This is a first balance pass, not a claim of completed human playtesting.

| Setting | Previous Normal | R7 Normal | Previous Hard | R7 Hard |
| --- | --- | --- | --- | --- |
| Sea and obstacle speed, pixels per second | 150 | 185 | 150 | 215 |
| Sailing gunboat speed | 100 | 275 | 150 | 340 |
| Player movement speed | 300 | 360 | 400 | 440 |
| First spawn timer, seconds | 6.5 | 1.0 | 4.0 | 0.65 |
| First 30 seconds, encounter rolls without events or a population cap | 5 | 11 | 7 | 16 |
| Opening spawn interval range, seconds | 4.0 to 6.5 | 2.2 to 3.6 | 4.0 until first event | 1.45 to 2.5 |
| Fully ramped interval range, seconds | Event dependent | 0.65 to 1.5 | Event dependent | 0.38 to 1.0 |
| Time to full base ramp | Event dependent | 300 seconds | Event dependent | 210 seconds |

The old ramp changed its peak only after a maze or shark event ended. Hard mode changed its configured starting peak but did not initialize the active peak to that value. R7 calculates the interval from survival time and a shorter pressure cycle. Score does not drive the ramp, so scoring a lucky multikill cannot trigger an abrupt difficulty jump. Pressure cycles still include recovery, and events retain a short pause before regular spawns resume. Survival time pauses with the game and continues through events. New regular encounters pause at a soft cap of 30 enemies in Normal or 42 in Hard.

The opening encounter is one gunboat. Later groups have at most two boats for the first 40 seconds, then up to three. Normal begins allowing bombers after 9 seconds, sharks after 16, sirens after 25 and parrots after 45. Hard introduces these at two thirds of those times. Existing spawn spacing and offscreen entry rules remain. Maze and shark events arrive earlier, and the first shark event has fewer sharks than later events. Maze row timing preserves the old 300 pixel spacing despite the faster current.

Gunboats outrun passive obstacles by 90 pixels per second in Normal and 125 in Hard. Paralysis removes their propulsion and lets them drift with the current. Pickups, sirens during screams, foam wakes and passive obstacles use the same current helper. Ordinary barrels travel a little faster than the current. Bombers move at 245 to 300 pixels per second before the existing Hard multiplier. Gunboat firing intervals are 1.7 to 2.25 seconds before the Hard multiplier. Shark acquisition takes 3.8 to 4.8 seconds before the existing Hard reduction; the final warning animation and dash speed are retained.

Impact shake is restored. A small temporary zoom, capped at 1.8 percent, makes space for a bounded translation inside the arena. The full arena framing returns as the impulse ends. Steering does not move the camera. The sea reads the same camera transform, and the existing screen shake setting still disables the effect.

Explosions create a short PointLight2D with a 170 pixel radius, 0.85 peak energy and 0.16 second fade. It lights nearby ships and obstacles without lighting HUD or projectile cues. A separate faint 0.24 second ring preserves impact motion. At most six event lights run at once. Existing explosion art and damaging lifetimes are retained.

Hard mode starts its weather transition immediately when confirmed. Over 1.1 seconds, the menu sea changes to cooler blue gray, wave motion strengthens and fast diagonal rain arrives. Cloud shadows move over the sea. A brief upper edge lightning glow accompanies departure, then recurs at irregular intervals during play. Weather persists across the existing ship and camera handoff. Normal keeps its bright cyan palette. Returning to the menu clears the storm. Weather pauses with gameplay, stays below the HUD and can be disabled with F6.

Runtime checks also exposed older errors. Explosion nodes are now added outside the physics query callback. Destroyed obstacles cannot award twice during overlapping hits. An unused lookup for a nonexistent jumpscare audio node and calls to the absent obstacle spawn_minions function were removed. Those minion calls previously produced errors and spawned nothing. Departure preview nodes clear their old scene owners, and camera effects ignore a camera after its scene leaves the tree.

### Tuning locations

* scripts/voyage_pacing.gd controls current, gunboat propulsion, spawn intervals and recovery.
* scripts/enemy_spawner.gd controls introductory timing, formation sizes and regular population limits.
* scripts/maze_spawner.gd controls event timing and shark pack sizes.
* scripts/camera_effects.gd and camera_2d.gd control shake strength and temporary overscan.
* scripts/visual_fx.gd controls explosion light size, duration, energy and light count.
* scripts/storm_fx.gd, storm_overlay.gdshader and ocean_motion.gdshader control Hard weather.

## R6 fixes and menu departure

Parrot death now occurs immediately on the fatal hit. It leaves the protection and enemy groups, hides itself and its shadow, stops its path followers, disables collision and awards its reward once. Its existing sound plays on a separate temporary audio node. Repeated bullets or beam ticks cannot restart death or award duplicate rewards. Hard mode still performs the existing delayed retaliatory airstrike after the visible death, then frees both path followers together. Shared enemy node references are optional so the smaller parrot scene no longer looks up boat and siren children that it does not contain.

The menu uses the same water textures, continuous ocean shader and palette as gameplay, initially scrolling at its original calm speed of 60. After choosing Normal or Hard, the existing little ship shoots forward from below the screen for one second. Near the top edge, the camera catches up over 1.25 seconds and settles at the actual gameplay camera position, 960 by 540. The ship settles at the actual gameplay spawn, 971 by 944. Its menu artwork blends into a copy of the existing gameplay sprite layers during the follow. The preview has no player controller or collisions. Water scroll speed rises to the gameplay speed of 150.

Gameplay begins through a short 0.28 second dissolve at the matched framing. The water phase and animation clock carry across the scene boundary. Gameplay timers, attacks and input remain paused until the dissolve is complete. Scene loading starts during the departure, repeated activation is blocked, and failed loading restores the menu. The fixed arena camera from R5 remains in effect during combat.

Confusion now appears in the same bottom icon row as the other powers, using the existing debuff image and progress bar with a seconds label. It reads the actual player timer, supports refreshed screams and pauses with the game. Restart clears and recreates it with the other icons.

Sirens drift downward at the sea's scroll speed while screaming and retreating. The scream wait respects pause and paralysis, and retreat cleanup waits for the actual diveback animation to finish instead of a separate one-second timer. Their original animation drawings and frame durations are unchanged.

Buttons use the original gray metal textures without the teal or coral tint. Disabled buttons remain dimmed. Existing font sizes and keyboard focus indicators remain.

The achievements list expands to the scroll area width. Rows use containers with explicit padding, wrapped descriptions and a separate progress column, so label offsets cannot collapse the row width. Reopening removes old rows immediately. Saved unlocks remain authoritative. No achievement requirements or saved data were changed.

## Arena and parrot guard revision R5

The camera stays centered on the full 1920 by 1080 arena. Player movement no longer shifts the foreground sideways. The previous edge-follow correction and F7 close view have been removed because they could expose cleanup areas or hide valid spawn lanes. The project explicitly keeps its 16:9 aspect with borders on other window shapes. Camera shake is constrained to the arena; at full-arena framing there is no space for camera translation, so those shake offsets are suppressed. Player movement, collision walls and steering are unchanged. Hull or wake artwork can still clip at the original arena edge; the camera no longer pans past the wall to reveal it.

The smooth ocean samples world coordinates through the inverse canvas transform. Its scroll, distortion, cyan palette and animation speed are unchanged. Camera effects and the water use the same transform on each frame, including if framing is changed later.

Gunboat groups choose one center and spacing for the whole formation, with 336 pixels of horizontal separation and 192 pixels of side clearance. Single boats no longer reach a division by zero. Placement checks existing gunboats near the entry row. Crowded groups are staggered farther upstream with 220 pixels of vertical clearance rather than dropped or overlapped. Wave timers, group counts and spawn probabilities are unchanged. Upstream boats wait until their center is at least 60 pixels inside the arena before firing.

Bombers, sirens and sharks are moved far enough outside their entry edge to account for their configured sprite and wake bounds. They sail into view rather than appearing partly drawn. Bombers wait until inside the arena to drop barrels. Enemy cleanup waits until all visible sprite rectangles and wakes have left the arena, plus a 16 pixel visual margin. Obstacle cleanup uses the same bounds check. The shark double-dash turn-around exception and the parrot's authored path remain intact.

A parrot-blocked hit triggers a pink shield and PARROT GUARD badge on the protected enemy, with a small image of the parrot. The protecting parrot pulses in the same color. Each actor reuses one cue, so lasers and multishot do not stack labels. It is hooked to the real immunity branch in take_damage, preserving the existing sound and damage rules. The cue remains enabled with F6 because it explains a combat rule. A charging shark's own immunity does not falsely trigger the parrot cue when no parrot is present.

## Combat readability revision R4

Sharks have a thin pale silhouette and a short white wake while charging. The warning lane uses the real rectangular collider width and stays visible until start_shark_charge executes. Its progress arc follows the pending charge animation. Lock durations, dash speeds, invulnerability and double dash logic are unchanged.

Siren screams emit two short pink ripples when the attack triggers. R6 places the confusion icon and actual player dizzy_timer in the shared status row. A repeated scream refreshes the existing card rather than adding another independent icon. Pause freezes the gameplay timer and display together.

Explosion and bone debris opacity clears earlier after the initial burst. A thin orange boundary marks a damaging barrel blast while its collision is active. The player's hull outline draws above nearby blast artwork and below hostile bullets. The blast animation, collider and damage lifetime remain unchanged, including their existing behavior.

Wrecks and bones receive a restrained 1.1 pixel pale outline. Small corner marks are taken from the real rectangle collider, including its offset. No obstacle formations or collision shapes were changed.

Pickup cards now have a solid navy backing, an existing icon, a name and one short explanation. At most two appear at once. Longer descriptions are available through POWER GUIDE in the pause menu. Escape or Back closes the guide. Icon timers now start after entering the scene tree. Reset clears icon references and preserves HUD anchors. The redundant scene copy of the autoload HUD was removed so there is one score and pickup UI owner.

## Earlier September 24 readability changes

All six recommendations from the gameplay review are implemented in source.

1. Bright ocean. Water brightness is restored to 1.0. The water shader selectively lifts darker blue patches toward the original artwork's dominant cyan. Its contrast softening control now affects shadows rather than mixing a dull color over the entire image. The starting strength is 0.55. Foam whites retain their color apart from a subtle animated shimmer. Both continuous water and the original flipbook use this palette treatment.
2. Hostile shots. Existing pink cannonballs get a brighter core, a thin cream rim and a short, faint directional trail. The outline fits within the original image's transparent padding. Sprite dimensions, speed, collision radius and damage are unchanged. Hostile shots draw at Z 40, above explosions at Z 20 and reward text at Z 24. F6 can disable the added projectile treatment while their safe draw order remains active.
3. Shared menu styling. Main menu, difficulty, submenu, pause and result buttons share themes/nautical.tres. R6 restores the gray metal textures with cream lettering and a visible keyboard focus border. Start and Resume use the primary style. Hard mode no longer multiplies the whole button by red. Locked mode remains disabled and readable. The movement hint and score use the same panel treatment. Achievement rows retain a dark background with a gold border for completed entries, separate progress alignment and smaller wrapped descriptions. Original UI node paths and signal targets are retained where code needs them.
4. Clearer score and rewards. The score panel has a 20 pixel top inset, internal padding, a smaller caption and larger number. It does not pulse for every score tick. Floating rewards show prominent points and a smaller enemy or object name beneath, using the existing Norwester font, light fills and navy outlines. They rise a shorter distance and fade within 0.85 seconds.
5. Explosion visibility. The initial burst remains intact. Outer regions fade earlier as the animation proceeds, while the center stays visible longer. This only changes opacity. Animation FPS, frame durations, completion signals and damage lifetime are retained. Hostile projectiles remain visible above the artwork.
6. Transitions. R6 replaces the Start fade with the departure above; other scene changes retain the shared fade. The transition covers the HUD, blocks input, pauses gameplay while loading, waits for scene initialization and fades back in. Repeated requests are ignored and failed loads reveal the old scene again. The camera treatment from that earlier pass is superseded by R5 above.

Existing duplicate signal connections encountered in the score timer, leaderboard back button and hostile projectile initialization are now guarded.

## Retained earlier changes

The sea scrolls a continuously distorted copy of its first existing drawing instead of stepping through the 2.5 FPS flipbook. Two swells, a small ripple and highlight shimmer animate every rendered frame. The shader uses the exact 1040 by 1080 pixel tile present in the source image. Its script clock pauses with gameplay.

Actor sprite layers bob and roll gently without moving collision shapes. Foam and explosion frames blend using alpha aware interpolation. Character attack timing, laser and lightning animation timing are unchanged. The existing hit flashes, cannon recoil, muzzle glow, limited event lights and bounded camera shake are retained.

The movement hint fades in, remains briefly, fades out and frees itself after about 4.2 seconds of active gameplay. Moving after the first second dismisses it sooner. Pause also pauses the hint. The obsolete tutorial animation library is no longer used.

All 586 asset and import files are identical to the preceding saved project. No artwork, sound, font or texture import configuration was edited. Shader sampling can use linear filtering without changing import files.

## Comparison controls

F9 shows or hides the build identification panel. It remains available while paused.

F6 switches the visual treatment, including ocean palette and motion, lights, glow, recoil, actor bobbing, effect blending and hostile shot rims and trails. UI improvements, projectile draw order, hint dismissal, fixed arena framing and parrot guard feedback remain active.

F7 no longer changes the camera. The full arena remains visible.

F8 switches between continuous water and the original flipbook. Keep F6 enabled for this comparison.

R7 temporarily adds up to 1.8 percent overscan during shake. The view stays inside the arena and returns to full framing afterward.

## Tuning

Select the root of scenes/visual_fx.tscn in the Inspector.

Water Brightness starts at 1.0. Water Contrast Softening starts at 0.55 and now lifts dark regions selectively. Water Wave Amplitude remains 10. Water Highlight Shimmer is 0.40, with a gentler brightness variation than before. Actor Motion Amount can be zero to disable bobbing. Existing event light limits remain available.

The sunlit cyan target is in scripts/ocean_motion.gdshader and scripts/water_polish.gdshader. Hostile projectile treatment is in scripts/hostile_projectile.gdshader and scripts/enemybullet.gd. Explosion edge fade is in scripts/effect_blend.gdshader and its controller. UI colors and button states are in themes/nautical.tres.

## Windows export

The supplied debug templates are included in export_templates. The Windows Desktop preset points to them.

Double click export_windows.bat and enter the full path to your Godot 4.5.1 editor executable. It imports the project and exports a debug build into the build folder. Keep the executable and PCK together.

Alternatively export Windows Desktop from the editor with Export With Debug enabled. A release export requires a matching release template. Original Web and macOS presets remain available, but only Windows is configured for the supplied templates.

## Validation and remaining checks

R7 was imported and exercised with the official Godot 4.5 engine in headless mode. The focused test passed 770 assertions across both modes, including current speed, gunboat drift, camera bounds, shake settings, explosion light creation and expiry, pause behavior, event recovery, parrot death, every enemy spawn path and the menu departure handoff. Separate 100 second simulations exercised each mode with an invulnerable stationary player and normal automatic shooting. This validates runtime behavior, not human difficulty or rendered visual quality. Source references, original asset bytes and ZIP integrity were checked separately. Rendered playback and Windows export were not performed. The longer headless runs reported retained Ogg playback resources on engine shutdown with the dummy audio driver. No gameplay script errors occurred in those runs; real audio shutdown still needs checking in the editor.

Check the F9 identifier, Normal and Hard departure, pause and restart, a fatal parrot hit during continuous fire, the hard mode airstrike, repeated confusion effects, siren retreat while paused or paralyzed, and scrolling/reopening achievements. No additional art or audio is needed.
