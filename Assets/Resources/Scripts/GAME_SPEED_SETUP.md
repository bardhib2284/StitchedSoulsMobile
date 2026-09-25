# Game Speed Controller Setup - Quick Guide

## Purpose
Speed up the game during development to skip through slow intro sequences (cinematics, walking, etc).

**Speeds Available:**
- 1x (Normal)
- 2x (Double speed)
- 4x (4x speed)
- 8x (8x speed)
- Cycles back to 1x

---

## Setup in Unity Inspector

### Step 1: Create Speed Button on Canvas

1. Select your **Canvas** in Hierarchy
2. Create a new **Button UI** element
3. Name it `SpeedButton`
4. Set position (top-right corner recommended)
5. Change text to "1x" (will update dynamically)

### Step 2: Add GameSpeedController Script

1. Create an empty GameObject in your scene
2. Name it `GameSpeedController`
3. Add the **GameSpeedController** script to it
4. In Inspector, assign:
   ```
   Speed Button: Drag SpeedButton from Canvas
   Speed Display Text: Drag the Text element inside SpeedButton
   ```

### Step 3: Done!

Now when you click the button:
- Text updates to show current speed (1x, 2x, 4x, 8x)
- Game runs at that speed
- Each click cycles to next speed

---

## How to Use

**In Play Mode:**
1. Click the speed button or press button in UI
2. Game speed changes instantly
3. Text shows current speed
4. Perfect for skipping intro cinematic!

**Example:**
```
Click 1x button
↓
Text shows: 2x (game runs 2x speed)
↓
Click again
↓
Text shows: 4x (game runs 4x speed)
↓
Click again
↓
Text shows: 8x (game runs 8x speed - FAST!)
↓
Click again
↓
Text shows: 1x (back to normal)
```

---

## Important Notes

⚠️ **Warning for Production:**
- This is a **development tool only**
- Remove the speed button before building for release
- Only use for testing/debugging gameplay flow
- Do NOT ship with this feature enabled

---

## Keyboard Alternative (Optional)

If you want to add keyboard control, you can:

1. Open **GameSpeedController.cs**
2. Add in the `Update()` method:

```csharp
private void Update()
{
    // Press T to toggle speed
    if (Input.GetKeyDown(KeyCode.T))
    {
        CycleGameSpeed();
    }
}
```

Then you can press **T** instead of clicking the button!

---

## Example Scene Setup

```
Scene
├── CameraManager
├── Patch (Player)
├── Zombie
├── Canvas
│   ├── StaminaPanel
│   ├── HealthPanel
│   └── SpeedButton ← NEW
│       └── Text "1x"
└── GameSpeedController ← NEW
    (Script attached)
```

---

Done! Now you can skip those 2-3 minutes of intro! ⚡
