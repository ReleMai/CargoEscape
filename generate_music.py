#!/usr/bin/env python3
"""
Music Generator for Cargo Escape
Generates procedural background music tracks.
"""

import wave
import struct
import math
import os
import random

AUDIO_PATH = os.path.join(os.path.dirname(os.path.abspath(__file__)), "assets", "audio")
SAMPLE_RATE = 44100


def generate_note(frequency, duration, volume=0.3, attack=0.05, release=0.1):
    """Generate a musical note with envelope."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    attack_samples = int(SAMPLE_RATE * attack)
    release_samples = int(SAMPLE_RATE * release)
    
    for i in range(num_samples):
        # ADSR envelope (simplified)
        if i < attack_samples:
            envelope = i / attack_samples
        elif i > num_samples - release_samples:
            envelope = (num_samples - i) / release_samples
        else:
            envelope = 1.0
        
        # Combine sine with harmonics for richer tone
        sample = volume * envelope * (
            0.6 * math.sin(2 * math.pi * frequency * i / SAMPLE_RATE) +
            0.25 * math.sin(2 * math.pi * frequency * 2 * i / SAMPLE_RATE) +
            0.15 * math.sin(2 * math.pi * frequency * 3 * i / SAMPLE_RATE)
        )
        samples.append(sample)
    
    return samples


def generate_pad(frequency, duration, volume=0.2):
    """Generate ambient pad sound."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    
    for i in range(num_samples):
        t = i / SAMPLE_RATE
        # Slow LFO for movement
        lfo = 1 + 0.02 * math.sin(t * 0.5)
        
        sample = volume * (
            0.4 * math.sin(2 * math.pi * frequency * lfo * t) +
            0.3 * math.sin(2 * math.pi * frequency * 0.5 * t) +
            0.2 * math.sin(2 * math.pi * frequency * 1.5 * t) +
            0.1 * math.sin(2 * math.pi * frequency * 2 * t)
        )
        samples.append(sample)
    
    return samples


def generate_bass(frequency, duration, volume=0.35):
    """Generate bass sound."""
    samples = []
    num_samples = int(SAMPLE_RATE * duration)
    
    for i in range(num_samples):
        t = i / num_samples
        # Quick attack, sustained
        envelope = min(1.0, i / (SAMPLE_RATE * 0.02)) * (1 - t * 0.2)
        
        sample = volume * envelope * (
            0.7 * math.sin(2 * math.pi * frequency * i / SAMPLE_RATE) +
            0.3 * math.sin(2 * math.pi * frequency * 2 * i / SAMPLE_RATE)
        )
        samples.append(sample)
    
    return samples


def generate_arp(notes, note_duration, volume=0.25):
    """Generate arpeggio pattern."""
    samples = []
    for freq in notes:
        samples.extend(generate_note(freq, note_duration, volume, 0.01, 0.05))
    return samples


def mix_tracks(*tracks):
    """Mix multiple tracks together."""
    max_len = max(len(t) for t in tracks)
    result = [0.0] * max_len
    
    for track in tracks:
        for i, sample in enumerate(track):
            result[i] += sample
    
    # Normalize
    peak = max(abs(s) for s in result) if result else 1.0
    if peak > 0.9:
        result = [s / peak * 0.85 for s in result]
    
    return result


def loop_to_duration(samples, duration):
    """Loop samples to fill duration."""
    target_samples = int(SAMPLE_RATE * duration)
    result = []
    while len(result) < target_samples:
        result.extend(samples)
    return result[:target_samples]


def save_wav(filename, samples):
    """Save samples to WAV file."""
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    
    with wave.open(filename, 'w') as wav_file:
        wav_file.setnchannels(1)
        wav_file.setsampwidth(2)
        wav_file.setframerate(SAMPLE_RATE)
        
        for sample in samples:
            sample = max(-1.0, min(1.0, sample))
            packed = struct.pack('<h', int(sample * 32767))
            wav_file.writeframes(packed)
    
    print(f"Created: {filename}")


# Note frequencies (Hz)
NOTES = {
    'C3': 130.81, 'D3': 146.83, 'E3': 164.81, 'F3': 174.61, 'G3': 196.00, 'A3': 220.00, 'B3': 246.94,
    'C4': 261.63, 'D4': 293.66, 'E4': 329.63, 'F4': 349.23, 'G4': 392.00, 'A4': 440.00, 'B4': 493.88,
    'C5': 523.25, 'D5': 587.33, 'E5': 659.25, 'F5': 698.46, 'G5': 783.99, 'A5': 880.00,
}


def generate_main_menu_music(duration=60):
    """Mysterious, ambient main menu music."""
    # Slow pad progression (Am - F - C - G)
    pad_sequence = []
    chord_duration = 4.0
    chords = [
        [NOTES['A3'], NOTES['C4'], NOTES['E4']],  # Am
        [NOTES['F3'], NOTES['A3'], NOTES['C4']],  # F
        [NOTES['C3'], NOTES['E3'], NOTES['G3']],  # C
        [NOTES['G3'], NOTES['B3'], NOTES['D4']],  # G
    ]
    
    for chord in chords:
        chord_samples = [0.0] * int(SAMPLE_RATE * chord_duration)
        for note in chord:
            pad = generate_pad(note, chord_duration, 0.15)
            for i, s in enumerate(pad):
                chord_samples[i] += s
        pad_sequence.extend(chord_samples)
    
    # Loop to duration
    pad_track = loop_to_duration(pad_sequence, duration)
    
    # Add subtle high arpeggios
    arp_notes = [NOTES['E5'], NOTES['A4'], NOTES['C5'], NOTES['E4']]
    arp_pattern = generate_arp(arp_notes, 0.5, 0.1)
    arp_track = loop_to_duration(arp_pattern, duration)
    
    # Add low drone
    drone = generate_pad(NOTES['A3'] / 2, duration, 0.12)
    
    return mix_tracks(pad_track, arp_track, drone)


def generate_space_exploration_music(duration=90):
    """Expansive, wonder-filled space exploration music."""
    # Ethereal pads
    pad_sequence = []
    chord_duration = 6.0
    chords = [
        [NOTES['C4'], NOTES['G4'], NOTES['C5']],
        [NOTES['A3'], NOTES['E4'], NOTES['A4']],
        [NOTES['F3'], NOTES['C4'], NOTES['F4']],
        [NOTES['G3'], NOTES['D4'], NOTES['G4']],
    ]
    
    for chord in chords:
        chord_samples = [0.0] * int(SAMPLE_RATE * chord_duration)
        for note in chord:
            pad = generate_pad(note, chord_duration, 0.12)
            for i, s in enumerate(pad):
                chord_samples[i] += s
        pad_sequence.extend(chord_samples)
    
    pad_track = loop_to_duration(pad_sequence, duration)
    
    # Gentle bass
    bass_notes = [NOTES['C3'], NOTES['A3'] / 2, NOTES['F3'] / 2, NOTES['G3'] / 2]
    bass_sequence = []
    for note in bass_notes:
        bass_sequence.extend(generate_bass(note, 6.0, 0.2))
    bass_track = loop_to_duration(bass_sequence, duration)
    
    # Sparkle arpeggios
    arp_notes = [NOTES['G5'], NOTES['E5'], NOTES['C5'], NOTES['G4'], NOTES['E5'], NOTES['C5']]
    arp = generate_arp(arp_notes, 0.4, 0.08)
    arp_track = loop_to_duration(arp, duration)
    
    return mix_tracks(pad_track, bass_track, arp_track)


def generate_combat_music(duration=60, intense=False):
    """Tense combat music."""
    tempo_mult = 1.5 if intense else 1.0
    volume_mult = 1.2 if intense else 1.0
    
    # Pulsing bass
    bass_freq = NOTES['E3'] / 2 if intense else NOTES['A3'] / 2
    bass_sequence = []
    for _ in range(8):
        bass_sequence.extend(generate_bass(bass_freq, 0.25 / tempo_mult, 0.3 * volume_mult))
        bass_sequence.extend([0.0] * int(SAMPLE_RATE * 0.25 / tempo_mult))
    bass_track = loop_to_duration(bass_sequence, duration)
    
    # Tension pads
    if intense:
        pad_notes = [NOTES['E3'], NOTES['G3'], NOTES['B3']]  # Em
    else:
        pad_notes = [NOTES['A3'], NOTES['C4'], NOTES['E4']]  # Am
    
    pad_samples = [0.0] * int(SAMPLE_RATE * 8)
    for note in pad_notes:
        pad = generate_pad(note, 8.0, 0.15 * volume_mult)
        for i, s in enumerate(pad):
            pad_samples[i] += s
    pad_track = loop_to_duration(pad_samples, duration)
    
    # Rhythmic hits
    hit_pattern = []
    for i in range(16):
        if i % 4 == 0 or (intense and i % 2 == 0):
            hit_pattern.extend(generate_note(NOTES['C4'] if i % 8 == 0 else NOTES['G3'], 
                                            0.15, 0.2 * volume_mult, 0.01, 0.1))
        else:
            hit_pattern.extend([0.0] * int(SAMPLE_RATE * 0.15))
    hit_track = loop_to_duration(hit_pattern, duration)
    
    return mix_tracks(bass_track, pad_track, hit_track)


def generate_boarding_music(duration=60, escape=False):
    """Tense boarding/infiltration music."""
    # Low menacing drone
    drone = generate_pad(NOTES['C3'] / 2, duration, 0.15)
    
    # Unsettling pads (minor 2nd intervals)
    pad1 = generate_pad(NOTES['C4'], duration, 0.1)
    pad2 = generate_pad(NOTES['C4'] * 1.059, duration, 0.08)  # Minor 2nd up
    
    # Heartbeat-like pulse
    pulse_sequence = []
    pulse_interval = 0.8 if not escape else 0.5
    for _ in range(int(duration / pulse_interval)):
        pulse_sequence.extend(generate_bass(NOTES['C3'] / 2, 0.1, 0.25))
        pulse_sequence.extend([0.0] * int(SAMPLE_RATE * 0.05))
        pulse_sequence.extend(generate_bass(NOTES['C3'] / 2, 0.08, 0.15))
        pulse_sequence.extend([0.0] * int(SAMPLE_RATE * (pulse_interval - 0.23)))
    pulse_track = pulse_sequence[:int(SAMPLE_RATE * duration)]
    
    if escape:
        # Add urgency with higher arpeggios
        arp_notes = [NOTES['C5'], NOTES['E5'], NOTES['G5'], NOTES['C5']]
        arp = generate_arp(arp_notes, 0.15, 0.12)
        arp_track = loop_to_duration(arp, duration)
        return mix_tracks(drone, pad1, pad2, pulse_track, arp_track)
    
    return mix_tracks(drone, pad1, pad2, pulse_track)


def generate_victory_music(duration=15):
    """Triumphant victory fanfare."""
    # Major chord progression
    fanfare = []
    
    # Opening chord (C major)
    for note in [NOTES['C4'], NOTES['E4'], NOTES['G4'], NOTES['C5']]:
        fanfare.extend(generate_note(note, 0.5, 0.3, 0.02, 0.2))
    
    # Rising arpeggio
    rising = [NOTES['C4'], NOTES['E4'], NOTES['G4'], NOTES['C5'], NOTES['E5'], NOTES['G5']]
    for i, note in enumerate(rising):
        fanfare.extend(generate_note(note, 0.2, 0.25 + i * 0.02, 0.01, 0.05))
    
    # Final sustained chord
    final_chord = []
    for note in [NOTES['C4'], NOTES['E4'], NOTES['G4'], NOTES['C5']]:
        final_chord.extend(generate_pad(note, 3.0, 0.2))
    
    # Combine
    result = fanfare + final_chord
    
    # Loop to duration
    return loop_to_duration(result, duration)


def generate_defeat_music(duration=10):
    """Somber defeat music."""
    # Descending minor progression
    descent = []
    notes = [NOTES['A4'], NOTES['G4'], NOTES['F4'], NOTES['E4'], NOTES['D4'], NOTES['C4']]
    
    for note in notes:
        descent.extend(generate_note(note, 0.8, 0.25, 0.1, 0.4))
    
    # Low sustained minor chord
    minor_chord = []
    for note in [NOTES['A3'] / 2, NOTES['C3'], NOTES['E3']]:
        minor_chord.extend(generate_pad(note, 4.0, 0.15))
    
    result = descent + minor_chord
    return loop_to_duration(result, duration)


def main():
    """Generate all music tracks."""
    print("Generating music tracks for Cargo Escape...")
    
    music_path = os.path.join(AUDIO_PATH, "music")
    
    # Menu music
    save_wav(os.path.join(music_path, "menu", "main_theme.wav"), 
             generate_main_menu_music(60))
    save_wav(os.path.join(music_path, "menu", "pause_ambient.wav"), 
             generate_main_menu_music(30))
    
    # Gameplay music
    save_wav(os.path.join(music_path, "gameplay", "space_exploration.wav"), 
             generate_space_exploration_music(90))
    save_wav(os.path.join(music_path, "gameplay", "combat_light.wav"), 
             generate_combat_music(60, False))
    save_wav(os.path.join(music_path, "gameplay", "combat_intense.wav"), 
             generate_combat_music(60, True))
    save_wav(os.path.join(music_path, "gameplay", "boarding_tension.wav"), 
             generate_boarding_music(60, False))
    save_wav(os.path.join(music_path, "gameplay", "boarding_escape.wav"), 
             generate_boarding_music(45, True))
    
    # Cutscene music
    save_wav(os.path.join(music_path, "cutscenes", "intro_cinematic.wav"), 
             generate_space_exploration_music(30))
    save_wav(os.path.join(music_path, "cutscenes", "victory.wav"), 
             generate_victory_music(15))
    save_wav(os.path.join(music_path, "cutscenes", "defeat.wav"), 
             generate_defeat_music(10))
    
    # Ambient music (can overlap with ambient sounds)
    save_wav(os.path.join(music_path, "ambient", "station_ambient.wav"), 
             generate_main_menu_music(60))
    save_wav(os.path.join(music_path, "ambient", "ship_interior.wav"), 
             generate_boarding_music(60, False))
    
    print("\n=== Music generation complete! ===")
    print("Note: These are WAV files. For production, convert to OGG for smaller size.")
    print("Update AudioManager MUSIC_TRACKS to use .wav instead of .ogg if needed.")


if __name__ == "__main__":
    main()
