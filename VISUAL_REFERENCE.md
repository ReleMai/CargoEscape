# Visual Feedback Features - Quick Reference

## Feature Overview

```
┌─────────────────────────────────────────────────────────────┐
│                   CONTAINER VISUAL STATES                    │
└─────────────────────────────────────────────────────────────┘

1. CLOSED STATE (Default)
   ┌──────────────────┐
   │  CARGO CONTAINER │  ← Normal color (dark gray/brown)
   │                  │
   │   [3 items]      │  ← Shows item count
   │                  │
   │   [OPEN BUTTON]  │  ← Click to open
   └──────────────────┘

2. HOVER STATE (Mouse Over)
   ┌──────────────────┐
   │ ✨CARGO CONTAINER│  ← Subtle white highlight overlay
   │ ✨               │  ← Pulsing glow effect
   │   [3 items]   ✨ │
   │              ✨  │
   │   [OPEN BUTTON]  │
   └──────────────────┘
   
3. SEARCHING STATE (Items Being Searched)
   ┌──────────────────┐
   │ 💠CARGO CONTAINER│  ← Blue pulsing overlay
   │ 💠  Searching... │  ← Label changes
   │ 💠            💠 │  ← Entire container pulses
   │              💠  │
   │                  │
   └──────────────────┘
   
4. OPEN STATE (Ready to Loot)
   ┌──────────────────┐
   │  CARGO CONTAINER │  ← Green-tinted color
   │                  │
   │   [2 items]      │  ← Shows remaining items
   │                  │
   │  [Item] [Item]   │  ← Revealed items visible
   └──────────────────┘
   
5. EMPTY STATE (All Items Taken)
   ┌──────────────────┐
   │  CARGO CONTAINER │  ← Dimmed/transparent
   │                  │
   │      Empty       │  ← Shows empty message
   │                  │
   │                  │
   └──────────────────┘
```

## Item Search Progress

```
HIDDEN ITEM (Before Search)
┌──────────┐
│    ?     │  ← Question mark silhouette
│          │
│          │
└──────────┘

SEARCHING ITEM (Click and Hold)
┌──────────┐
│    ?     │  ← Question mark still visible
│          │
│          │
│▓▓▓▓░░░░░░│  ← Progress bar fills (50% shown)
└──────────┘
         ↑
    Pulsing blue bar

REVEALED ITEM (Search Complete)
┌──────────┐
│  [ICON]  │  ← Item image/visual
│          │
│   $150   │  ← Value shown
└──────────┘
```

## Ship Container States (2D Boarding Scene)

```
CLOSED CONTAINER
    ╔═══╗
    ║   ║  ← Default color (brown)
    ╚═══╝
    "3 items"

HOVER CONTAINER
    ✨╔═══╗✨
    ✨║   ║✨  ← Yellow glow pulsing
    ✨╚═══╝✨
    "3 items"

SEARCHING CONTAINER
    ╔═══╗
    ║💠💠║  ← Color pulsing
    ╚═══╝
    "Searching..."
    [▓▓▓░░░░] ← Progress bar above

OPEN CONTAINER
    ╔═══╗
    ║   ║  ← Green-tinted
    ╚═══╝
    "2 items"

EMPTY CONTAINER
    ╔═══╗
    ║░░░║  ← Dimmed/transparent
    ╚═══╝
    "Empty"
```

## Animation Timing

- **Hover Fade In:** 0.15 seconds
- **Hover Fade Out:** 0.15 seconds
- **Pulse Speed:** ~5 cycles per second
- **Default Search Time:** 1.5 seconds per item
- **Progress Bar Update:** Every frame (smooth)

## Color Scheme

- **Hover Highlight:** White (0.08 alpha)
- **Search Overlay:** Blue (0.4, 0.6, 1.0)
- **Progress Bar:** Cyan (0.4, 0.8, 1.0)
- **Empty State:** Gray (reduced opacity)
- **Closed State:** Dark brown/gray
- **Open State:** Greenish tint
- **Searching State:** Purple/blue pulsing

## User Interactions

```
1. HOVER OVER CONTAINER
   Mouse Enter → Highlight fades in
   Mouse Exit  → Highlight fades out

2. SEARCH AN ITEM
   Click & Hold on hidden item → Progress bar appears
   Hold for 1.5s → Item revealed
   Release early → Search cancelled

3. OPEN CONTAINER
   Click [OPEN] button → State changes to OPEN
   Container color changes
   Items become visible

4. TAKE ITEMS
   Click revealed items → Move to inventory
   When all taken → Container becomes EMPTY
   Color dims, shows "Empty" message
```

## Visual Hierarchy

```
Priority 1: Search Progress (highest urgency)
  └─> Pulsing blue overlay on container
  └─> Progress bar on individual items

Priority 2: Hover Feedback (interaction hint)
  └─> Subtle white highlight
  └─> Pulsing glow effect

Priority 3: State Colors (status information)
  └─> Color-coded states
  └─> State labels (Searching, Empty, etc.)
```

## Expected Visual Flow

```
Player Approach:
Container (closed) 
    ↓
Hover over → [Highlight appears]
    ↓
Click OPEN → [State changes to OPEN]
    ↓
Click & Hold Item → [Progress bar appears, container pulses]
    ↓
Search Complete → [Item reveals, container stops pulsing]
    ↓
Take All Items → [Container becomes empty, dimmed]
```

## Key Visual Indicators

✅ **Good Visual Feedback:**
- Smooth transitions (0.15s fade)
- Consistent pulse timing
- Clear state colors
- Visible progress bars
- Intuitive hover effects

❌ **Avoid:**
- Jarring color changes
- Too fast animations (< 0.1s)
- Invisible progress indicators
- Confusing state colors
- Missing hover feedback

## Accessibility Notes

- High contrast between states
- Visual AND text indicators
- Smooth animations (not jarring)
- Clear progress feedback
- Multiple feedback layers (color + text + animation)
