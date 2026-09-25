# Camera System Setup Guide

## Overview
This new camera system supports three distinct modes:
1. **Fixed 2D** - Side-scrolling with locked perspective (like classic Little Nightmares)
2. **Rotatable 2D** - 2.5D with changeable camera angles between areas
3. **Full 3D** - Traditional third-person with zoom and full freedom

## Files Created

```
Assets/Resources/Scripts/Camera/
├── CameraMode.cs              # Interface and data structures
├── CameraMode_Fixed2D.cs      # Side-scrolling implementation
├── CameraMode_Rotatable2D.cs  # 2.5D rotating implementation
├── CameraMode_Full3D.cs       # Full 3D third-person implementation
├── CameraManager.cs           # Main orchestrator (Singleton)
└── RoomManager.cs             # Per-room camera configuration
```

---

## Setup Instructions

### Step 1: Create Empty GameObject for CameraManager

1. In your scene, create an **empty GameObject** named `CameraManager`
2. Add the `CameraManager` script to it
3. In the Inspector, assign:
   - **Main Camera** → Your main camera object
   - **Player Transform** → Your Patch player object

### Step 2: Configure Each Room

For each room/area in your level:

1. **Add a Collider** to the room:
   - Create an empty child GameObject under your room
   - Add a **BoxCollider** (make it large enough to encompass the room)
   - Make sure "**Is Trigger**" is checked ✓
   - Tag it or the player as "Player" (must match)

2. **Add RoomManager Script**:
   - Attach `RoomManager.cs` to the same GameObject
   - Configure in Inspector:

   ```
   Room Settings:
   - Room Name: "Attic Entry"
   - Room Bounds: (reference the BoxCollider)

   Camera Mode Settings:
   - Camera Mode Type: Fixed2D / Rotatable2D / Full3D
   - Camera Offset: Position relative to player (e.g., 0, 1.5, -10)
   - Camera Bounds Min: Minimum camera position (e.g., 0, 0, 0)
   - Camera Bounds Max: Maximum camera position (e.g., 50, 30, 20)
   - Camera FOV: Field of view (60 is good default)

   For Rotatable2D:
   - Camera Rotation Euler: Rotation angles (e.g., 0, 0, 0 for front view, 30, 0, 0 for angled)
   - Should Rotate On Entry: ✓ if you want auto-rotation on room entry
   - Rotation Transition Time: 0.5

   Full 3D Settings:
   - Min Zoom: 40 (closer, zoomed in)
   - Max Zoom: 90 (farther, zoomed out)
   ```

### Step 3: Make Player Have "Player" Tag

1. Select your Patch character
2. In Inspector, set **Tag** to "Player" (create if doesn't exist)

### Step 4: Test Scene Setup

Your scene hierarchy should look like:
```
Scene
├── CameraManager (with CameraManager script)
├── MainCamera (child of Main)
├── Patch (Player with "Player" tag)
├── Attic Room (with RoomManager script)
│   └── RoomTrigger (BoxCollider, Is Trigger enabled)
├── SecondRoom (with RoomManager script)
│   └── RoomTrigger (BoxCollider, Is Trigger enabled)
└── ... other rooms
```

---

## Camera Mode Details

### Fixed 2D Mode
**Best for:** Side-scrolling sequences, narrow corridors

Configuration:
```
Camera Offset: (0, 1.5, -10)  // X doesn't matter much, Z is locked
Player Movement: Can only move X and Y
Camera Movement: Follows player X and Y, Z is static
Rotation: Always looking straight
```

### Rotatable 2D Mode
**Best for:** Multiple perspective views that change, Little Nightmares style

Configuration:
```
Camera Offset: (0, 2, -8)
Player Movement: Can move X, Y, Z
Camera Movement: Follows all three axes but can rotate between angles
Rotation: Can be set to rotate to different angles (0°, 45°, -45°, etc.)
```

Example rotations:
- Front view: `(0, 0, 0)`
- Angled up: `(30, 0, 0)`
- Side view: `(0, 90, 0)`
- Isometric: `(30, 45, 0)`

### Full 3D Mode
**Best for:** Open areas, boss arenas, exploration zones

Configuration:
```
Camera Offset: (0, 2, -10)
Player Movement: Can move and rotate freely (X, Y, Z)
Camera Movement: Follows all axes with zoom support
Rotation: Free rotation + pinch zoom on mobile
```

---

## Switching Modes Programmatically

If you need to switch camera modes from code:

```csharp
CameraManager manager = CameraManager.Instance;

// Switch to Fixed 2D with 0.5s transition
manager.SwitchToMode(CameraModeType.Fixed2D, transitionDuration: 0.5f);

// Switch to Rotatable 2D
manager.SwitchToMode(CameraModeType.Rotatable2D);

// Configure settings before switching
manager.ConfigureFixed2D(
    offset: new Vector3(0, 1.5f, -10f),
    minBounds: Vector3.zero,
    maxBounds: new Vector3(50f, 30f, 20f),
    fov: 60f
);

// Rotate camera in Rotatable2D or Full3D
manager.RotateCamera(new Vector3(30, 0, 0), transitionTime: 0.5f);
```

---

## Getting Movement Constraints

In your PlayerController, you can get the current movement constraints:

```csharp
void Update()
{
    CameraManager manager = CameraManager.Instance;
    MovementConstraints constraints = manager.GetMovementConstraints();

    // Check if player can move on specific axes
    if (constraints.CanMoveX) { /* allow X movement */ }
    if (constraints.CanMoveY) { /* allow Y movement */ }
    if (constraints.CanMoveZ) { /* allow Z movement */ }
    if (constraints.CanRotate) { /* allow player rotation */ }
}
```

---

## Common Room Configurations

### Attic Entry (Side-scrolling intro)
```
Mode: Fixed2D
Offset: (0, 1.5, -10)
Bounds Min: (0, 0, 0)
Bounds Max: (30, 20, 0)
FOV: 60
```

### Hallway (Rotatable 2.5D)
```
Mode: Rotatable2D
Offset: (0, 2, -8)
Bounds Min: (0, 0, -10)
Bounds Max: (40, 25, 10)
FOV: 60
Rotation: (0, 0, 0) [front view]
```

### Boss Arena (Full 3D)
```
Mode: Full3D
Offset: (0, 2, -10)
Bounds Min: (-20, 0, -20)
Bounds Max: (20, 30, 20)
Min Zoom: 40
Max Zoom: 90
```

---

## Debugging

### Check Current Mode
```csharp
CameraModeType current = CameraManager.Instance.GetCurrentModeType();
Debug.Log($"Current camera mode: {current}");
```

### Check if Transitioning
```csharp
if (CameraManager.Instance.IsTransitioning())
{
    Debug.Log("Camera is transitioning between states");
}
```

### Draw Debug Bounds
Each RoomManager draws bounds as Gizmos in the Scene view:
- **Green wireframe** = Room bounds
- **Cyan wireframe** = Camera bounds
- **Yellow line** = Camera offset from room center

---

## Migration from Old CameraController

The old CameraController.cs is still there. You can either:

1. **Keep it and disable it** while testing the new system
2. **Safely delete it** once new system is working

The new CameraManager handles all functionality the old controller had, plus much more.

---

## Next Steps

1. Create RoomManager instances for each room in your level
2. Set up the collider triggers for each room
3. Test transitions between rooms
4. Fine-tune camera offsets and bounds for each room
5. Once working, update PlayerController to respect movement constraints

Good luck! The system is designed to be flexible and easy to configure per-room.
