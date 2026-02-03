#!/usr/bin/env python3
"""
Audio Generator for Cargo Escape
Generates placeholder WAV audio files using synthesized sounds.
Run this script to create all required audio assets.
"""

import wave
import struct
import math
import os
import random

# Base path for audio files
AUDIO_BASE = os.path.dirname(os.path.abspath(__file__))
AUDIO_PATH = os.path.join(AUDIO_BASE, "assets", "audio")

# Sample rate
SAMPLE_RATE = 44100


def generate_sine_wave(frequency, duration, volume=0.5, fade_in=0.01, fade_out=0.05):
    """Generate a sine wave."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    fade_in_samples = int(SAMPLE_RATE * fade_in)
    fade_out_samples = int(SAMPLE_RATE * fade_out)
    
    for i in range(num_samples):
        # Calculate envelope
        if i < fade_in_samples:
            envelope = i / fade_in_samples
        elif i > num_samples - fade_out_samples:
            envelope = (num_samples - i) / fade_out_samples
        else:
            envelope = 1.0
        
        sample = volume * envelope * math.sin(2 * math.pi * frequency * i / SAMPLE_RATE)
        samples.append(sample)
    
    return samples


def generate_noise(duration, volume=0.3, fade_out=0.1):
    """Generate white noise."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    fade_out_samples = int(SAMPLE_RATE * fade_out)
    
    for i in range(num_samples):
        envelope = 1.0
        if i > num_samples - fade_out_samples:
            envelope = (num_samples - i) / fade_out_samples
        
        sample = volume * envelope * (random.random() * 2 - 1)
        samples.append(sample)
    
    return samples


def generate_sweep(start_freq, end_freq, duration, volume=0.5):
    """Generate a frequency sweep."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    
    for i in range(num_samples):
        t = i / num_samples
        freq = start_freq + (end_freq - start_freq) * t
        envelope = 1.0 - (t * 0.5)  # Fade out
        sample = volume * envelope * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)
        samples.append(sample)
    
    return samples


def generate_beep(frequency, duration, volume=0.4):
    """Generate a simple beep."""
    return generate_sine_wave(frequency, duration, volume, 0.005, 0.02)


def generate_explosion(duration, volume=0.7):
    """Generate explosion-like sound."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    
    for i in range(num_samples):
        t = i / num_samples
        # Decaying envelope
        envelope = math.exp(-t * 5) * volume
        # Low frequency rumble + noise
        low_freq = 50 + 30 * math.sin(t * 10)
        sample = envelope * (
            0.5 * math.sin(2 * math.pi * low_freq * i / SAMPLE_RATE) +
            0.5 * (random.random() * 2 - 1)
        )
        samples.append(sample)
    
    return samples


def generate_laser(duration=0.15, volume=0.5):
    """Generate laser/pew sound."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    
    for i in range(num_samples):
        t = i / num_samples
        # Descending frequency
        freq = 2000 - 1500 * t
        envelope = (1 - t) * volume
        sample = envelope * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)
        samples.append(sample)
    
    return samples


def generate_door(opening=True, duration=0.4):
    """Generate door open/close sound."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    
    for i in range(num_samples):
        t = i / num_samples
        if opening:
            freq = 100 + 200 * t
        else:
            freq = 300 - 200 * t
        
        envelope = 0.4 * (1 - abs(t - 0.5) * 2)
        # Add some mechanical noise
        noise = 0.1 * (random.random() * 2 - 1)
        sample = envelope * (math.sin(2 * math.pi * freq * i / SAMPLE_RATE) + noise)
        samples.append(sample)
    
    return samples


def generate_ui_click(duration=0.05, volume=0.3):
    """Generate UI click sound."""
    return generate_sine_wave(800, duration, volume, 0.001, 0.02)


def generate_loot_pickup(rarity=0, duration=0.3):
    """Generate loot pickup sound based on rarity."""
    base_freq = 400 + rarity * 100
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    
    for i in range(num_samples):
        t = i / num_samples
        # Rising tone
        freq = base_freq + 200 * t
        volume = 0.4 * (1 - t * 0.5)
        
        # Add harmonics for higher rarities
        sample = volume * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)
        if rarity >= 2:
            sample += 0.2 * volume * math.sin(2 * math.pi * freq * 1.5 * i / SAMPLE_RATE)
        if rarity >= 4:
            sample += 0.15 * volume * math.sin(2 * math.pi * freq * 2 * i / SAMPLE_RATE)
        
        samples.append(sample)
    
    return samples


def generate_alert(urgent=False, duration=0.5):
    """Generate alert sound."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    freq = 880 if urgent else 440
    
    for i in range(num_samples):
        t = i / num_samples
        # Pulsing
        pulse = 0.5 + 0.5 * math.sin(t * 20)
        volume = 0.5 * pulse * (1 - t * 0.3)
        sample = volume * math.sin(2 * math.pi * freq * i / SAMPLE_RATE)
        samples.append(sample)
    
    return samples


def generate_ambient_loop(duration=5.0, base_freq=60):
    """Generate ambient drone loop."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Multiple low frequencies for depth
        sample = 0.15 * (
            math.sin(2 * math.pi * base_freq * t) +
            0.5 * math.sin(2 * math.pi * (base_freq * 1.5) * t) +
            0.3 * math.sin(2 * math.pi * (base_freq * 0.5) * t + math.sin(t * 0.5))
        )
        # Slight movement
        sample += 0.05 * math.sin(2 * math.pi * 100 * t + math.sin(t * 2) * 10)
        samples.append(sample)
    
    return samples


def save_wav(filename, samples):
    """Save samples to WAV file."""
    # Ensure directory exists
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        
        for sample in samples:
            # Clamp and convert to 16-bit
            sample = max(-1.0, min(1.0, sample))
            packed = struct.pack('<h', int(sample * 32767))
            wav_file.writeframes(packed)
    
    print(f"Created: {filename}")


def main():
    """Generate all audio files."""
    print("Generating audio files for Cargo Escape...")
    print(f"Output directory: {AUDIO_PATH}")
    
    # === BOARDING SOUNDS ===
    boarding_path = os.path.join(AUDIO_PATH, "sfx", "boarding")
    
    # Door sounds (reusing existing or creating new)
    save_wav(os.path.join(boarding_path, "door_open.wav"), generate_door(True, 0.3))
    save_wav(os.path.join(boarding_path, "door_close.wav"), generate_door(False, 0.3))
    
    # === LOOT SOUNDS ===
    loot_path = os.path.join(AUDIO_PATH, "sfx", "loot")
    save_wav(os.path.join(loot_path, "loot_common.wav"), generate_loot_pickup(0, 0.2))
    save_wav(os.path.join(loot_path, "loot_uncommon.wav"), generate_loot_pickup(1, 0.25))
    save_wav(os.path.join(loot_path, "loot_rare.wav"), generate_loot_pickup(2, 0.35))
    save_wav(os.path.join(loot_path, "loot_epic.wav"), generate_loot_pickup(3, 0.45))
    save_wav(os.path.join(loot_path, "loot_legendary.wav"), generate_loot_pickup(4, 0.6))
    
    # === UI SOUNDS ===
    ui_path = os.path.join(AUDIO_PATH, "sfx", "ui")
    save_wav(os.path.join(ui_path, "ui_click.wav"), generate_ui_click(0.05))
    save_wav(os.path.join(ui_path, "ui_hover.wav"), generate_sine_wave(600, 0.03, 0.15))
    save_wav(os.path.join(ui_path, "ui_confirm.wav"), generate_beep(880, 0.1, 0.4))
    save_wav(os.path.join(ui_path, "ui_cancel.wav"), generate_sweep(400, 200, 0.15, 0.4))
    save_wav(os.path.join(ui_path, "ui_deny.wav"), generate_sweep(300, 100, 0.2, 0.4))
    save_wav(os.path.join(ui_path, "ui_open.wav"), generate_sweep(300, 600, 0.15, 0.3))
    save_wav(os.path.join(ui_path, "ui_close.wav"), generate_sweep(600, 300, 0.15, 0.3))
    save_wav(os.path.join(ui_path, "ui_tab.wav"), generate_beep(700, 0.05, 0.25))
    save_wav(os.path.join(ui_path, "ui_scroll.wav"), generate_sine_wave(500, 0.02, 0.1))
    save_wav(os.path.join(ui_path, "ui_notification.wav"), 
             generate_beep(660, 0.1) + generate_beep(880, 0.15))
    
    # === SHIP SOUNDS ===
    ship_path = os.path.join(AUDIO_PATH, "sfx", "ship")
    save_wav(os.path.join(ship_path, "engine_idle.wav"), generate_ambient_loop(2.0, 80))
    save_wav(os.path.join(ship_path, "engine_thrust.wav"), 
             generate_noise(0.5, 0.4) + generate_ambient_loop(0.5, 120))
    save_wav(os.path.join(ship_path, "engine_boost.wav"), generate_sweep(100, 400, 0.4, 0.5))
    save_wav(os.path.join(ship_path, "ship_damage.wav"), generate_explosion(0.3, 0.6))
    save_wav(os.path.join(ship_path, "shield_hit.wav"), 
             generate_sweep(2000, 500, 0.1, 0.4))
    save_wav(os.path.join(ship_path, "shield_down.wav"), 
             generate_sweep(1000, 100, 0.4, 0.5))
    save_wav(os.path.join(ship_path, "shield_recharge.wav"), 
             generate_sweep(200, 800, 0.5, 0.3))
    
    # === WEAPON SOUNDS ===
    weapons_path = os.path.join(AUDIO_PATH, "sfx", "weapons")
    save_wav(os.path.join(weapons_path, "laser_fire.wav"), generate_laser(0.12, 0.5))
    save_wav(os.path.join(weapons_path, "laser_hit.wav"), generate_sweep(1500, 300, 0.08, 0.4))
    save_wav(os.path.join(weapons_path, "missile_launch.wav"), 
             generate_sweep(200, 800, 0.3, 0.5) + generate_noise(0.2, 0.3))
    save_wav(os.path.join(weapons_path, "missile_explode.wav"), generate_explosion(0.5, 0.7))
    save_wav(os.path.join(weapons_path, "railgun_charge.wav"), 
             generate_sweep(100, 2000, 0.8, 0.4))
    save_wav(os.path.join(weapons_path, "railgun_fire.wav"), 
             generate_noise(0.1, 0.7) + generate_sweep(3000, 500, 0.2, 0.6))
    
    # === EXPLOSION SOUNDS ===
    explosions_path = os.path.join(AUDIO_PATH, "sfx", "explosions")
    save_wav(os.path.join(explosions_path, "explosion_small.wav"), generate_explosion(0.3, 0.5))
    save_wav(os.path.join(explosions_path, "explosion_medium.wav"), generate_explosion(0.5, 0.6))
    save_wav(os.path.join(explosions_path, "explosion_large.wav"), generate_explosion(0.8, 0.7))
    save_wav(os.path.join(explosions_path, "ship_explode.wav"), generate_explosion(1.2, 0.8))
    
    # === DOCKING SOUNDS ===
    docking_path = os.path.join(AUDIO_PATH, "sfx", "docking")
    save_wav(os.path.join(docking_path, "dock_approach.wav"), 
             generate_ambient_loop(1.5, 50) + generate_beep(300, 0.2))
    save_wav(os.path.join(docking_path, "dock_clamp.wav"), 
             generate_noise(0.1, 0.5) + generate_sine_wave(150, 0.3, 0.4))
    save_wav(os.path.join(docking_path, "dock_seal.wav"), 
             generate_noise(0.2, 0.3) + generate_sweep(200, 100, 0.3, 0.3))
    save_wav(os.path.join(docking_path, "undock.wav"), 
             generate_sweep(100, 300, 0.3, 0.4) + generate_noise(0.3, 0.4))
    
    # === ALERT SOUNDS ===
    alerts_path = os.path.join(AUDIO_PATH, "sfx", "alerts")
    save_wav(os.path.join(alerts_path, "alert_warning.wav"), generate_alert(False, 0.5))
    save_wav(os.path.join(alerts_path, "alert_critical.wav"), generate_alert(True, 0.4))
    save_wav(os.path.join(alerts_path, "alert_timer.wav"), generate_beep(1000, 0.15, 0.4))
    save_wav(os.path.join(alerts_path, "countdown_beep.wav"), generate_beep(880, 0.1, 0.5))
    save_wav(os.path.join(alerts_path, "countdown_final.wav"), 
             generate_beep(1200, 0.3, 0.6))
    
    # === ACHIEVEMENT SOUNDS ===
    achievements_path = os.path.join(AUDIO_PATH, "sfx", "achievements")
    achievement_sound = (
        generate_beep(523, 0.1) +  # C
        generate_beep(659, 0.1) +  # E
        generate_beep(784, 0.1) +  # G
        generate_beep(1047, 0.3)   # High C
    )
    save_wav(os.path.join(achievements_path, "achievement_unlock.wav"), achievement_sound)
    
    level_up_sound = (
        generate_sweep(300, 600, 0.2, 0.4) +
        generate_sweep(600, 1200, 0.3, 0.5)
    )
    save_wav(os.path.join(achievements_path, "level_up.wav"), level_up_sound)
    save_wav(os.path.join(achievements_path, "money_gain.wav"), 
             generate_beep(1000, 0.05, 0.3) + generate_beep(1200, 0.08, 0.25))
    
    # === AMBIENT SOUNDS ===
    ambient_path = os.path.join(AUDIO_PATH, "ambient")
    save_wav(os.path.join(ambient_path, "space_hum.wav"), generate_ambient_loop(10.0, 40))
    save_wav(os.path.join(ambient_path, "ship_ambience.wav"), generate_ambient_loop(10.0, 60))
    save_wav(os.path.join(ambient_path, "station_bustle.wav"), 
             generate_ambient_loop(10.0, 80) + [0.1 * (random.random() - 0.5) for _ in range(int(SAMPLE_RATE * 10))])
    save_wav(os.path.join(ambient_path, "engine_rumble.wav"), generate_ambient_loop(10.0, 30))
    save_wav(os.path.join(ambient_path, "ventilation.wav"), generate_noise(10.0, 0.08))
    save_wav(os.path.join(ambient_path, "computer_hum.wav"), generate_ambient_loop(10.0, 120))
    save_wav(os.path.join(ambient_path, "radio_static.wav"), generate_noise(5.0, 0.1))
    
    print("\n=== Audio generation complete! ===")
    print(f"Total files created in {AUDIO_PATH}")
    print("\nNote: Music tracks (.ogg) need to be created separately or sourced from")
    print("royalty-free music libraries. The AudioManager expects these files:")
    print("  - music/menu/main_theme.ogg")
    print("  - music/gameplay/space_exploration.ogg")
    print("  - music/gameplay/combat_light.ogg")
    print("  - music/gameplay/boarding_tension.ogg")
    print("  - music/cutscenes/intro_cinematic.ogg")
    print("  etc.")


if __name__ == "__main__":
    main()
