# Enemy AI Behavior Trees - Usage Guide

This document explains how to use the new behavior tree AI system for enemies in Cargo Escape.

## Overview

Enemies now support two modes of operation:
1. **PATTERN Mode**: Classic movement patterns (STRAIGHT, SINE_WAVE, HOMING, etc.)
2. **BEHAVIOR_TREE Mode**: Intelligent AI using behavior trees

## Switching to AI Mode

In the Godot editor:
1. Select an enemy node
2. In the Inspector, find "AI Mode" group
3. Set "Ai Mode" to "BEHAVIOR_TREE"
4. Choose a behavior preset: "Basic", "Aggressive", or "Defensive"
5. Optionally set patrol waypoints (relative to spawn position)

## Behavior Presets

### Basic
The default balanced AI:
- Patrols between waypoints when idle
- Chases player when spotted (500 pixel range)
- Attacks when in range (100 pixels)
- Alerts nearby enemies when player spotted
- Flees when health drops below 30%

### Aggressive
Hunter enemy that actively seeks the player:
- No patrol - always searching
- Large detection range (800 pixels)
- Faster chase speed (250 pixels/sec)
- More damage (15 vs 10)
- Faster attack rate (0.8 sec vs 1.0 sec)
- Only flees when health below 20%

### Defensive
Cautious enemy that prefers to patrol:
- Smaller detection range (250 pixels)
- Flees earlier (40% health)
- Shorter chase range (400 pixels)
- Mostly patrols assigned area

## Setting Patrol Waypoints

Waypoints are **relative** to the enemy's spawn position:

```gdscript
# Example: Create a square patrol pattern
enemy.patrol_waypoints = [
    Vector2(0, 0),      # Start position
    Vector2(-200, 0),   # 200 pixels left
    Vector2(-200, 200), # 200 pixels left and down
    Vector2(0, 200),    # Back to right, down
]
```

In the Godot editor:
1. Select enemy
2. In Inspector, expand "AI Mode"
3. Click on "Patrol Waypoints"
4. Add elements and set Vector2 values

## Creating Custom Behavior Trees in Code

For advanced users, you can create custom behavior trees:

```gdscript
extends Area2D

var behavior_tree: BehaviorTree = null

func _ready():
    # Create custom behavior tree
    behavior_tree = BehaviorTree.new()
    
    # Build the tree using BTBuilder
    var root = BTBuilder.selector([
        # Priority 1: Flee if very low health
        BTBuilder.sequence([
            BTBuilder.condition_is_low_health(0.2),
            BTBuilder.flee(300.0, 400.0)
        ]),
        
        # Priority 2: Attack if player nearby
        BTBuilder.sequence([
            BTBuilder.condition_can_see_player(300.0),
            BTBuilder.attack(100.0, 1.5, 20.0)
        ]),
        
        # Priority 3: Just move forward
        BTBuilder.patrol([
            global_position,
            global_position + Vector2(-500, 0)
        ])
    ])
    
    behavior_tree.set_root(root)
    behavior_tree.initialize(self, {})

func _process(delta):
    if behavior_tree:
        behavior_tree.tick(delta)
```

## Available Behavior Nodes

### Actions
- **BTPatrol**: Move between waypoints
- **BTChase**: Follow target
- **BTAttack**: Deal damage to target
- **BTFlee**: Run away from target
- **BTAlert**: Notify nearby enemies

### Conditions
- **BTConditionCanSeePlayer**: Check if player is visible
- **BTConditionIsLowHealth**: Check if health is below threshold
- **BTConditionIsInRange**: Check if target is close enough

### Composites
- **BTSequence**: Execute children in order (all must succeed)
- **BTSelector**: Try children until one succeeds

### Decorators
- **BTInverter**: Invert child result
- **BTRepeater**: Repeat child N times

## Behavior Tree Concepts

### Status Values
Each node returns one of:
- **SUCCESS**: Node completed successfully
- **FAILURE**: Node failed
- **RUNNING**: Node is still executing

### Sequence Node
Executes children in order. If any fails, the sequence fails.
Use for: "Do A AND B AND C"

Example: "See player" AND "Chase player" AND "Attack"

### Selector Node
Tries children in order. Returns success on first success.
Use for: "Try A OR B OR C"

Example: "Attack" OR "Chase" OR "Patrol"

### Blackboard
Shared data between nodes. Automatically stores:
- `target`: Current target (usually player)
- `alert_received`: Whether alerted by another enemy

## Tips

1. **Start Simple**: Use the presets first, then customize
2. **Test in Editor**: Use the play scene button to test AI
3. **Waypoints Matter**: Good patrol paths make interesting enemies
4. **Mix Modes**: Some enemies can use patterns, others use AI
5. **Performance**: Behavior trees are efficient, don't worry about performance

## Debugging

Enable debug output in the behavior tree:
```gdscript
# In enemy script
func _process(delta):
	if behavior_tree:
		var status = behavior_tree.tick(delta)
		if OS.is_debug_build():
			print("AI Status: ", status)
```

## Example Enemy Configurations

### Guard Enemy
```
AI Mode: BEHAVIOR_TREE
Preset: Defensive
Waypoints: Small area patrol
```

### Hunter Enemy
```
AI Mode: BEHAVIOR_TREE
Preset: Aggressive
Waypoints: (none needed)
```

### Scout Enemy
```
AI Mode: BEHAVIOR_TREE
Preset: Basic
Waypoints: Large patrol route
```

### Classic Enemy
```
AI Mode: PATTERN
Movement Pattern: HOMING
(Uses original movement system)
```
