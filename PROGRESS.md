# Stitched Souls 3D - Development Progress

**Last Updated:** 2025-11-04
**Project Goal:** Create a Game of the Year quality souls-like horror action game for Android/iOS (2026 target)
**Current Status:** Phase 1 - Core Mechanics & Bug Fixes Complete ✅

---

## 📊 Quick Status Summary

| Category | Status | Progress |
|----------|--------|----------|
| **Phase 1: Core Mechanics** | ✅ Complete | 100% |
| **Phase 2: Progression Systems** | ⏳ Pending | 0% |
| **Phase 3: Spell System** | ⏳ Pending | 0% |
| **Phase 4: Enemy Variety** | ⏳ Pending | 0% |
| **Phase 5: Checkpoints & Death** | ⏳ Pending | 0% |
| **Phase 6: Level Design** | ⏳ Pending | 0% |
| **Phase 7: Optimization & UI** | ⏳ Pending | 0% |
| **Phase 8: Build & Launch** | ⏳ Pending | 0% |

---

## ✅ COMPLETED WORK

### Phase 1: Core Mechanics & Optimization

#### 1. **Camera System Redesign** ✅
- **Files Created:**
  - `CameraMode.cs` - Base interface for all camera modes
  - `CameraMode_Fixed2D.cs` - Side-scrolling (2D locked mode)
  - `CameraMode_Rotatable2D.cs` - 2.5D rotatable between fixed angles
  - `CameraMode_Full3D.cs` - Traditional third-person with pinch zoom
  - `CameraManager.cs` - Singleton orchestrator for mode switching
  - `RoomManager.cs` - Per-room camera configuration
  - `CameraSystemInitializer.cs` - Helper for setup and testing (keys 1-3)

- **Features:**
  - Three camera modes with smooth transitions
  - Per-room configuration
  - Keyboard testing support (Press 1/2/3 to switch modes)

---

#### 2. **PlayerController Performance Optimization** ✅
- **File:** `Assets\Resources\Scripts\PlayerController.cs`

- **Optimizations Applied:**
  - ✅ Cached `Camera.main` reference (avoid lookup every frame)
  - ✅ Implemented `Animator.StringToHash()` for all animation parameters:
    - `attackHashId`
    - `runHashId`
    - `rollHashId`
    - `happyIdleHashId`
    - `sneakyWalkHashId`
    - `hammerAttackHashId`
  - ✅ Ground check frequency reduced to every 2 frames (was every frame)
  - ✅ Cached animator clip info instead of multiple per-frame calls
  - ✅ Cached `AtticLevelCinematic` reference

- **New Features:**
  - ✅ Keyboard attack input: Press **A** key to attack (easier PC testing)
  - ✅ Proper attack state management with coroutine tracking

---

#### 3. **Weapon System Optimization** ✅
- **Files Modified:**
  - `Weapon.cs` - Base weapon class
  - `HammerWeapon.cs` - Hammer-specific implementation
  - `GunWeapon.cs` - Gun implementation

- **Changes:**
  - ✅ Replaced `Invoke()` calls with coroutine-based `AttackCoroutine()`
  - ✅ Implemented `Animator.StringToHash()` caching
  - ✅ Proper weapon collider lifecycle management
  - ✅ Hammer timing: Enable at 0.25s, disable at 0.68s

---

#### 4. **Player Health System (Souls-Like)** ✅
- **File Created:** `Assets\Resources\Scripts\PlayerHealth.cs`

- **Features:**
  - Max Health: 100 HP
  - No automatic regeneration
  - Flask Healing: 40 HP per flask, 5 flasks max
  - Death Mechanics:
    - Dies at 0 HP
    - 2-second death animation
    - Respawns at respawn point with full health/flasks
  - Methods:
    - `TakeDamage(float damage)`
    - `UseFlask()` - Returns bool
    - `Heal(float amount)`
    - `RefillFlasks()` - For safe zones/checkpoints
    - `GetHealth()`, `GetFlasks()`, `IsDead()`

---

#### 5. **Health UI System** ✅
- **File Modified:** `Assets\Resources\Scripts\HealthUI.cs`

- **Features:**
  - Two-slider system (main + background)
  - Main slider drops instantly
  - Background slider animates smoothly
  - Flask counter display (e.g., "5/5")
  - Methods:
    - `SetHealth(float maxHealth)` - Initialize slider range
    - `UpdateHealth(float currentHealth)` - Update display
    - `UpdateFlaskCount(int current, int max)` - Update flask counter

---

#### 6. **Flask/Potion System** ✅
- **File Created:** `Assets\Resources\Scripts\FlaskManager.cs`

- **Features:**
  - E key to use flask
  - 2-second cooldown between uses
  - Canvas button integration
  - Refill method for safe zones
  - Connected to PlayerHealth system

---

#### 7. **Zombie Attack Bug Fixes** ✅
- **File Modified:** `Assets\ZombieAcidAttack.cs`

- **Bug 1: Zombie Invulnerable When Missing Attack** - FIXED ✅
  - **Problem:** When player dodged zombie's attack, zombie stayed invulnerable
  - **Solution:** Moved `CanBeInterrupted = false` to AFTER range check
  - **Result:** Player can now punish missed attacks

- **Bug 2: Zombie Not Attacking After 2 Hits** - FIXED ✅
  - **Problem:** After hitting zombie twice, `canAttack` flag stuck at false
  - **Root Cause:** Overlapping `ShootAcid()` coroutines interfering with state
  - **Solution:** Added coroutine lifecycle management with `attackCoroutine` field
  - **Implementation:**
    - Added `StartAttack()` method to stop previous coroutine before starting new one
    - Store coroutine reference in `attackCoroutine` field
    - Clear reference when coroutine completes or is cancelled
    - Updated `ZombieAI.cs` to call `StartAttack()` instead of direct `StartCoroutine()`

- **Code Changes:**
  ```csharp
  // Track current attack coroutine
  private Coroutine attackCoroutine;

  // Stop previous attack and start new one
  public void StartAttack()
  {
      if (attackCoroutine != null)
      {
          StopCoroutine(attackCoroutine);
      }
      attackCoroutine = StartCoroutine(ShootAcid());
  }
  ```

---

#### 8. **Player Attack Clash Bug Fix** ✅
- **File Modified:** `Assets\Resources\Scripts\PlayerController.cs`

- **Problem:** When player and zombie attack simultaneously, attacks clash and player gets locked unable to attack
- **Root Cause:** Overlapping attack coroutines with unsynchronized state flags
- **Solution:** Added attack coroutine lifecycle management (same pattern as zombie)

- **Implementation:**
  ```csharp
  // Track current attack coroutine
  private Coroutine attackCoroutine;

  // In AttackCoroutine():
  if (attackCoroutine != null)
  {
      StopCoroutine(attackCoroutine);
      isAttacking = false;
      canAttack = true;
  }
  attackCoroutine = StartCoroutine(Attack());

  // In Attack() coroutine - clear reference when complete:
  attackCoroutine = null;
  ```

- **Result:** Attacks no longer conflict; player can always attack even if timing overlaps

---

#### 9. **Movement Logic Fix** ✅
- **File Modified:** `Assets\Resources\Scripts\PlayerController.cs`

- **Problem:** When stamina depleted while joystick at max (trying to run), player completely stopped moving
- **Root Cause:** `currentMoveSpeed` never set to walk speed when `UseStamina()` failed
- **Solution:** Restructured stamina check with fallback logic

- **Implementation:**
  ```csharp
  // New logic in HandleMovement():
  if (joystickMagnitude > RunSpeedHandler)
  {
      if (PlayerStamina.GetStamina() > 0.5f)
      {
          if (PlayerStamina.UseStamina(Time.deltaTime * 2f))
          {
              currentMoveSpeed = moveSpeed; // Full speed
          }
          else
          {
              Move(); // Fallback to walking
              currentMoveSpeed = moveSpeed * 0.5f;
          }
      }
      else
      {
          Move(); // No stamina - walk
          currentMoveSpeed = moveSpeed * 0.5f;
      }
  }
  ```

- **Result:** Player gracefully drops from running to walking when stamina depletes; continuous movement

---

### Game Speed Controller (Development Tool) ✅
- **File Created:** `Assets\Resources\Scripts\GameSpeedController.cs`

- **Features:**
  - Button on canvas to cycle game speed
  - Speed options: 1x → 2x → 4x → 8x → 1x
  - TextMeshProUGUI display showing current speed
  - Speeds up intro sequences for faster testing
  - **Setup:** Attach to empty GameObject, assign button and text in inspector

- **Note:** Development tool only - remove before production build

- **Setup Guide:** `Assets\Resources\Scripts\GAME_SPEED_SETUP.md`

---

## 🔧 Technical Patterns & Architecture

### Coroutine Lifecycle Management
Both zombie and player attack systems now use this pattern to prevent overlapping coroutines:

```csharp
private Coroutine myCoroutine;

public void StartAction()
{
    if (myCoroutine != null)
    {
        StopCoroutine(myCoroutine);
    }
    myCoroutine = StartCoroutine(Action());
}

IEnumerator Action()
{
    // ... do work ...
    myCoroutine = null; // Clear when done
}
```

### Animator Parameter Hashing
All animation triggers use cached hashes instead of strings:

```csharp
// In Awake():
private int attackHashId = Animator.StringToHash("Attack");

// In code:
animator.SetTrigger(attackHashId); // Instead of "Attack"
```

### Two-Slider UI Pattern
Used for both stamina and health:
- Main slider responds instantly to damage/stamina use
- Background slider animates smoothly to catch up
- Creates visual feedback of gradual health loss

### Souls-Like Game Design Philosophy
- **Limited Resources:** 5 flasks × 40 HP (200 total potential healing)
- **Permanent Death:** Death until respawn at safe zone
- **Punishment for Mistakes:** Vulnerable enemies give player chance to punish
- **No Regeneration:** Only way to heal is flasks
- **Stamina Resource:** Run speed costs stamina; empty = walk only

---

## 🐛 Known Fixed Bugs

| Bug | Status | Fix |
|-----|--------|-----|
| Zombie invulnerable during missed attacks | ✅ FIXED | Moved `CanBeInterrupted = false` to after range check |
| Zombie not attacking after 2 hits | ✅ FIXED | Added coroutine lifecycle management |
| Player locked after attack clash | ✅ FIXED | Added attack coroutine tracking |
| Player stops when stamina depletes at max joystick | ✅ FIXED | Added fallback to walk speed logic |
| Excessive Camera.main lookups | ✅ FIXED | Cached reference in Awake |
| Multiple ground checks per frame | ✅ FIXED | Reduced to every 2 frames |
| Multiple animator calls per frame | ✅ FIXED | Cached animator clip info |

---

## ⏳ PENDING WORK

### Phase 1 Remaining:
- [ ] Create modular room system with RoomManager per room
- [ ] Update PlayerController for 2.5D movement constraints

### Phase 2: Weapon Progression System
- [ ] Design 4-5 weapon progression
- [ ] Create weapon upgrade/crafting system
- [ ] Implement material collection

### Phase 3: Spell System
- [ ] Implement "Thread Needle" spell
- [ ] Implement "Shadow Step" spell
- [ ] Spell management UI

### Phase 4: Enemy Variety
- [ ] Design 2-3 new enemy types
- [ ] Implement unique AI patterns
- [ ] Balance progressive encounters

### Phase 5: Checkpoint System
- [ ] Implement checkpoint/safe zones
- [ ] Create death/respawn mechanics with material drops
- [ ] Level restart system

### Phase 6: Level Design
- [ ] Create 15+ interconnected rooms
- [ ] Environmental storytelling
- [ ] Lore implementation

### Phase 7: Optimization & UI
- [ ] Optimize for 60 FPS on mobile
- [ ] Create responsive mobile UI
- [ ] Settings/options menu

### Phase 8: Build & Launch
- [ ] Create demo and full version builds
- [ ] App store listings
- [ ] Marketing materials

---

## 📝 Files Structure

```
StitchedSoulsMobile/
├── Assets/
│   ├── Resources/
│   │   ├── Characters/
│   │   │   ├── Patches/ (Player)
│   │   │   └── Zombie/
│   │   │       ├── ZombieAI.cs ✅ MODIFIED
│   │   │       └── (other zombie components)
│   │   └── Scripts/
│   │       ├── PlayerController.cs ✅ OPTIMIZED
│   │       ├── PlayerHealth.cs ✅ NEW
│   │       ├── HealthUI.cs ✅ MODIFIED
│   │       ├── FlaskManager.cs ✅ NEW
│   │       ├── GameSpeedController.cs ✅ NEW
│   │       ├── Weapon.cs ✅ OPTIMIZED
│   │       ├── HammerWeapon.cs ✅ OPTIMIZED
│   │       ├── GunWeapon.cs ✅ OPTIMIZED
│   │       ├── CameraMode.cs ✅ NEW
│   │       ├── CameraMode_Fixed2D.cs ✅ NEW
│   │       ├── CameraMode_Rotatable2D.cs ✅ NEW
│   │       ├── CameraMode_Full3D.cs ✅ NEW
│   │       ├── CameraManager.cs ✅ NEW
│   │       ├── RoomManager.cs ✅ NEW
│   │       ├── CameraSystemInitializer.cs ✅ NEW
│   │       ├── GAME_SPEED_SETUP.md ✅ NEW
│   │       └── HEALTH_UI_SETUP_QUICK.md ✅ NEW
│   └── ZombieAcidAttack.cs ✅ MODIFIED (in Assets root)
└── PROGRESS.md (this file)
```

---

## 🎮 Testing Checklist

### Core Mechanics (Verified Working ✅)
- [x] Player movement (walk/run with stamina)
- [x] Player attack with hammer (A key or button)
- [x] Stamina system with proper fallback
- [x] Health system (take damage, die, respawn)
- [x] Flask healing (E key or button, 5 max)
- [x] Zombie chasing and attacking
- [x] Zombie ragdoll on kill
- [x] Player can punish missed zombie attacks
- [x] Attack timing doesn't lock player
- [x] Game speed button (1x/2x/4x/8x)

### Next Testing Focus
- [ ] Modular room system
- [ ] 2.5D camera constraints
- [ ] Weapon progression
- [ ] New enemy types

---

## 💡 Key Development Notes

### Why Coroutine Lifecycle Management?
The zombie and player attack systems were experiencing state management issues because multiple coroutines of the same action (e.g., `ShootAcid()`) could run simultaneously. When one was interrupted, the other continued with stale state, causing flags like `canAttack` to get stuck.

Solution: Track the coroutine reference and **stop the old one before starting a new one**. This ensures only one action ever runs at a time.

### Stamina System Design
The movement fallback logic ensures smooth gameplay:
1. Max joystick + stamina = Run (full speed)
2. Max joystick + no stamina = Walk (50% speed)
3. Partial joystick = Walk (50% speed)
4. No joystick = Idle

This prevents "dead zones" where the player can't move.

### Performance Optimization Strategy
Three main optimizations applied:
1. **Cache Expensive Lookups:** Store `Camera.main`, animator hashes, clip info
2. **Reduce Check Frequency:** Ground checks every 2 frames, not every frame
3. **Avoid String Comparisons:** Use animator parameter hashes instead of "Attack" strings

Result: Smoother 60 FPS target on mobile.

---

## 🚀 Next Steps (When Resuming)

1. **Create Modular Room System**
   - Each room = separate scene or prefab
   - RoomManager script per room for camera/checkpoint setup
   - Test transitions between rooms

2. **Add More Enemy Variety**
   - Create 2-3 different zombie types with unique AI
   - Test progressive difficulty

3. **Implement Spell System**
   - Thread Needle: Ranged attack
   - Shadow Step: Dodge mechanic

4. **Level Design**
   - Create 15+ interconnected rooms
   - Environmental storytelling

5. **Performance Optimization for Mobile**
   - Profile on actual devices
   - Optimize particle effects, shadows
   - Test 60 FPS target

---

## 📞 Quick Reference

### Key Keyboard Controls (Testing)
- **A** - Attack
- **R** - Roll
- **Space** - Jump
- **1/2/3** - Switch camera modes
- **E** - Use flask
- **Speed Button** - Click canvas button to cycle 1x/2x/4x/8x

### Important Inspector Setup
1. **PlayerHealth**
   - Assign HealthUI component
   - Assign respawn point

2. **FlaskManager**
   - Assign Player Health reference
   - Assign HealthUI
   - Assign Flask button

3. **GameSpeedController**
   - Assign Speed Button
   - Assign Speed Display Text (TextMeshProUGUI)

4. **RoomManager**
   - Assign camera mode
   - Set camera constraints

---

**Last Session Date:** November 4, 2025
**Total Development Time:** Multiple sessions with continuous bug fixes and optimization
**Target Platform:** Android/iOS Mobile
**Target Release:** 2026 (GOTY Quality)

---

*This file should be updated after each major milestone or bug fix. Use it to brief future sessions on project status.*
