# Health System Setup Guide

## Overview
A complete souls-like health system with:
- ✅ **Max Health**: 100 HP
- ✅ **No Regeneration**: Only healing through flasks
- ✅ **Death at 0 HP**: Triggers respawn at room start
- ✅ **Flask System**: 5 flasks per attempt, each heals 40 HP
- ✅ **Respawn Points**: Return to beginning of room with fresh flasks
- ✅ **UI Display**: Health bar with smooth animation (like stamina)

## Files Created

```
Assets/Resources/Scripts/
├── PlayerHealth.cs          # Core health system
├── HealthUI.cs              # Canvas health bar display
├── FlaskManager.cs          # Flask/potion management
└── HEALTH_SYSTEM_SETUP.md   # This file
```

## Setup Instructions

### Step 1: Add PlayerHealth to Patch Character

1. Select your **Patch** player character in the scene
2. Add component: **PlayerHealth**
3. Configure in Inspector:
   ```
   Max Health: 100
   Max Flasks: 5
   Flask Heal Amount: 40
   ```

4. **Important**: Assign respawn point:
   - Create an empty GameObject at the beginning/entry of your room
   - Name it `RespawnPoint`
   - Drag it into PlayerHealth's **Respawn Point** field

### Step 2: Set Up Health UI on Canvas

1. In your Canvas, create a new Panel called **HealthPanel**
   - Anchor: Top-Left
   - Position: Similar to stamina bar

2. Create **Health Bar** (Slider):
   ```
   Panel Name: HealthPanel
   ├── HealthSlider (Slider)
   │   ├── Background (Image - red color)
   │   ├── Fill (Image - bright red)
   │   └── Handle (optional)
   └── HealthBackgroundSlider (Slider)
       ├── Background (Image - dark red/gray)
       └── Fill (Image - dark red)
   ```

3. Add **HealthUI** script to HealthPanel:
   ```
   Assign:
   - Health Slider: HealthSlider component
   - Background Slider: HealthBackgroundSlider component
   - Flask Count Text: (new Text UI element)
   - Flask Icon: (optional, flask image)
   ```

4. Add **FlaskButton** to canvas:
   - Create a Button UI element
   - Label: "Flask" or "E"
   - Assign to FlaskManager

### Step 3: Create Flask Visual Elements

1. In Canvas, add **Flask UI Text** for flask counter:
   ```
   Text Content: "5/5" (will update dynamically)
   Position: Near health bar
   ```

2. Optional: Add Flask Icon image next to text

### Step 4: Add FlaskManager to Patch

1. Select your **Patch** player
2. Add component: **FlaskManager**
3. Configure:
   ```
   Player Health: (drag Patch with PlayerHealth)
   Health UI: (drag HealthUI from canvas)
   Flask Button: (drag Flask button from canvas)
   Flask Key: E (for keyboard testing)
   Flask Cooldown: 2 (seconds between flasks)
   ```

### Step 5: Connect Zombie Attack to Health

✅ **Already Done!** ZombieAcidAttack.cs now deals 20 damage when it hits.

Damage values are configurable in ZombieAcidAttack.cs line 80:
```csharp
playerHealth.TakeDamage(20f); // Change this number for balance
```

### Step 6: Test the System

**Test Scenarios:**

1. **Taking Damage**:
   - Get hit by zombie
   - Health bar should drop
   - Check console for damage message

2. **Using Flask** (Keyboard):
   - Press **E** to use flask
   - Health should increase by 40
   - Flask count decreases (5/5 → 4/5)
   - Can't use flask while at full health

3. **Using Flask** (Canvas Button):
   - Click "Flask" button
   - Same behavior as keyboard

4. **Death**:
   - Take enough damage to reach 0 HP
   - "Die" animation triggers
   - After 2 seconds, respawn at RespawnPoint
   - Health and flasks reset to max
   - Should spawn at room beginning

5. **Flask Cooldown**:
   - Press E multiple times quickly
   - Flask can only be used every 2 seconds
   - "Flask is on cooldown!" message appears

## Health Values (Adjustable)

Current balance (can tweak for difficulty):
- **Player Health**: 100 HP
- **Flask Healing**: 40 HP (recover 40% of health)
- **Max Flasks**: 5 per attempt (200 HP total healing available)
- **Zombie Attack Damage**: 20 HP (20% of max health)
- **Flask Cooldown**: 2 seconds (strategic potion management)

To change difficulty:
- Increase zombie damage → harder
- Increase flask healing → easier
- Decrease max flasks → harder
- Increase flask cooldown → harder

## Scene Hierarchy Example

```
Scene
├── Patch (Player)
│   ├── PlayerController
│   ├── PlayerHealth ← Add this
│   ├── PlayerStamina
│   ├── FlaskManager ← Add this
│   ├── Animator
│   ├── Rigidbody
│   └── Collider
├── RespawnPoint ← Create this
│   └── (Empty gameobject at room entrance)
├── ZombieAI
│   └── ZombieAcidAttack (already updated)
└── Canvas
    ├── StaminaPanel
    ├── HealthPanel ← Add this
    │   ├── HealthSlider
    │   ├── HealthBackgroundSlider
    │   └── FlaskCountText
    └── FlaskButton
```

## Keyboard Controls

**Health & Flask System:**
- **E** = Use Flask (heal 40 HP)
- **A** = Attack (existing)
- **R** = Roll (existing)
- **Space** = Jump (existing)

## Canvas Button Setup

**Flask Button Setup:**
1. Create Button UI
2. Text: "Flask E"
3. Add to FlaskManager's Flask Button field
4. Button automatically calls FlaskManager.UseFlask()

## Integration with Other Systems

### With Weapon System
- Weapons deal damage to enemies ✅
- Enemies don't heal (souls-like) ✅
- Only player can heal ✅

### With Checkpoint/Safe Zones
When player reaches a safe zone, call:
```csharp
FlaskManager flaskManager = player.GetComponent<FlaskManager>();
flaskManager.RefillFlasks(); // Restores flasks to max
```

### With Death System
- Death triggers at 0 HP ✅
- Respawn at RespawnPoint ✅
- Health resets to 100 ✅
- Flasks reset to 5 ✅
- No "souls" system yet (you specified 0 souls) ✅

## Performance Notes

**Health system is optimized:**
- No per-frame calculations (only on damage)
- UI updates only when values change
- Smooth animation handled by coroutine (like stamina)
- No garbage collection spikes

## Troubleshooting

**Problem**: Health bar doesn't update
- **Solution**: Make sure HealthUI is assigned to PlayerHealth in inspector

**Problem**: Flask doesn't work
- **Solution**: Check FlaskManager is assigned, respawn point exists

**Problem**: Player doesn't respawn
- **Solution**: Make sure RespawnPoint transform is assigned to PlayerHealth

**Problem**: Zombie doesn't deal damage
- **Solution**: Check PlayerHealth component exists on Patch, ZombieAcidAttack has been updated

## Next Steps

1. **Test the system thoroughly** - Try different damage amounts
2. **Adjust balance** - Tweak zombie damage, flask healing for difficulty
3. **Add more damage sources** - Other enemies can use `playerHealth.TakeDamage()`
4. **Implement safe zones** - Create checkpoints where flasks refill
5. **Add visual effects** - Screen shake on damage, flask glow on use

---

**The system is ready to use!** Just follow the setup steps above and test.
