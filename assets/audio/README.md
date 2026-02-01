# Audio Assets

This directory contains all audio files for the CargoEscape game.

## Directory Structure

```
audio/
└── sfx/
    └── boarding/
        ├── airlock_open.wav      - Airlock door opening sound
        ├── airlock_close.wav     - Airlock door closing sound
        ├── footstep.wav          - Player footstep sound
        ├── container_open.wav    - Container opening sound
        ├── container_search.wav  - Container searching sound
        ├── loot_pickup.wav       - Item pickup sound
        └── escape.wav            - Escape/success sound
```

## Current Status

**⚠️ Placeholder Sounds**

The current sound files are programmatically generated placeholder tones:
- Simple sine wave audio with distinct frequencies
- Each sound has a unique pitch to make it recognizable
- Includes proper fade in/out envelopes
- Valid WAV format (44.1kHz, 16-bit)

These are **temporary** and should be replaced with professional game audio for production.

## Replacing Sounds

To replace a placeholder sound with a custom audio file:

1. Create or obtain your sound effect as a WAV file
2. Recommended format:
   - Sample Rate: 44100 Hz
   - Bit Depth: 16-bit
   - Channels: Mono or Stereo
3. Replace the corresponding `.wav` file in this directory
4. Keep the same filename
5. Godot will automatically detect and reimport the file

No code changes are required when replacing sound files.

## Sound Specifications

Recommended properties for each sound type:

| Sound | Duration | Volume | Notes |
|-------|----------|--------|-------|
| airlock_open | 0.5-0.8s | Medium | Mechanical, pressurization |
| airlock_close | 0.4-0.6s | Medium | Heavy seal, hiss |
| footstep | 0.08-0.1s | Quiet | Metal grating, short |
| container_open | 0.3-0.5s | Medium | Latch, creak |
| container_search | 0.2-0.4s | Quiet | Rustling, rummaging |
| loot_pickup | 0.1-0.2s | Medium | Satisfying pop/click |
| escape | 0.5-1.0s | Loud | Success, triumph |

## File Format

All audio files should be:
- **Format**: WAV (uncompressed)
- **Sample Rate**: 44100 Hz or 48000 Hz
- **Bit Depth**: 16-bit or 24-bit
- **Channels**: Mono or Stereo

Godot supports other formats (OGG, MP3) but WAV is recommended for sound effects due to:
- No compression latency
- Better for short sounds
- Easier to edit and replace

## Licensing

When adding custom sounds, ensure they are:
- Created by you, or
- Licensed for use in games (check license terms)
- Attributed if required by license

Popular sources for game audio:
- [Freesound.org](https://freesound.org/)
- [OpenGameArt.org](https://opengameart.org/)
- [Sonniss Game Audio GDC Bundles](https://sonniss.com/gameaudiogdc)

## Volume Guidelines

Sound effects are played at various volumes to create proper audio mix:
- Footsteps: -8 to -6 dB (quiet)
- Doors: -4 to -2 dB (medium)
- Container sounds: -5 to -3 dB (medium)
- Loot pickup: -2 dB (medium-loud)
- Escape: 0 dB (full volume)

These can be adjusted in the code or by normalizing the audio files themselves.

## Testing Sounds

To test a sound effect:
1. Load the boarding scene in Godot
2. Play the game
3. Trigger the corresponding action (walk, open door, loot, etc.)
4. Listen for the sound
5. Adjust volume or replace if needed

## Need Help?

See [SOUND_SYSTEM_DOCS.md](../../SOUND_SYSTEM_DOCS.md) for complete documentation on the sound system implementation.
