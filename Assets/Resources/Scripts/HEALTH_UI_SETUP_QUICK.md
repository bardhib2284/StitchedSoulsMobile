# Health UI Setup - Quick Inspector Guide

## Problem
Health slider doesn't change when player takes damage.

## Solution
Make these connections in the Unity Inspector:

---

## Step 1: Patch Player Object

Select **Patch** (your player character) in the Hierarchy.

In the Inspector, find **PlayerHealth** script and assign:

```
Health UI: Drag your HealthUI component from Canvas here
Respawn Point: Drag an empty GameObject from room start here
```

---

## Step 2: Canvas HealthUI Component

Select the **health panel/slider** in your Canvas hierarchy.

Add component: **HealthUI** (if not already there)

In the Inspector, assign:

```
Health Slider: Drag the MAIN health slider (red bar, front)
Background Slider: Drag the BACKGROUND slider (dark bar, behind)
Flask Count Text: Drag the text element that shows "5/5"
Flask Icon: Leave empty (optional)
```

---

## Step 3: FlaskManager Component

Select **Patch** (your player character) again.

Add component: **FlaskManager** (if not already there)

In the Inspector, assign:

```
Player Health: Patch (drag the Patch object)
Health UI: The HealthUI component from step 2
Flask Button: The Flask button from your Canvas
Flask Key: E (already set)
```

---

## That's It!

The health system should now work:

✅ Take damage → Health slider drops
✅ Smooth animation → Background bar follows
✅ Use flask (E key) → Health increases
✅ Flask counter updates → Shows "4/5" etc

---

## Troubleshooting

**Problem**: Slider still doesn't move
- **Check**: Is HealthUI assigned in PlayerHealth inspector?
- **Check**: Are the sliders assigned in HealthUI script?

**Problem**: Flask button doesn't work
- **Check**: Is FlaskManager assigned to Patch?
- **Check**: Is Flask button assigned in FlaskManager?

**Problem**: Flask count doesn't show
- **Check**: Is flaskCountText assigned in HealthUI?

---

Done! Health UI is now connected!
