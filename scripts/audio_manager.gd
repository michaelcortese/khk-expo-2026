extends Node
# Procedurally synthesised audio — no external files, no licensing concerns.
# All sounds are generated as AudioStreamWAV objects at startup.
# Access via: get_tree().get_first_node_in_group("audio_manager")

const RATE := 22050   # Hz — half of CD quality, still sounds fine for SFX

var _sfx:    Dictionary = {}          # name → AudioStreamWAV
var _pool:   Array[AudioStreamPlayer] = []
var _pool_i: int = 0
var _music:  AudioStreamPlayer

func _ready() -> void:
	add_to_group("audio_manager")
	_build_sfx()
	_build_pool()
	_start_music()

# ── Public API ────────────────────────────────────────────────────────────────

func play(name: String, vol_db: float = 0.0) -> void:
	if not _sfx.has(name):
		return
	var p := _pool[_pool_i % _pool.size()]
	_pool_i += 1
	p.stream    = _sfx[name]
	p.volume_db = vol_db
	p.play()

func stop_music() -> void:
	if _music:
		var tw := create_tween()
		tw.tween_property(_music, "volume_db", -80.0, 1.5)
		tw.tween_callback(_music.stop)

# ── SFX construction ──────────────────────────────────────────────────────────

func _build_sfx() -> void:
	_sfx["deploy"]        = _make_deploy()
	_sfx["hit"]           = _make_hit()
	_sfx["arrow"]         = _make_arrow()
	_sfx["tower_hit"]     = _make_tower_hit()
	_sfx["tower_destroy"] = _make_tower_destroy()
	_sfx["crown"]         = _make_crown()
	_sfx["victory"]       = _make_victory()

func _build_pool() -> void:
	for _i in range(10):
		var p := AudioStreamPlayer.new()
		p.bus        = "Master"
		p.volume_db  = -4.0
		add_child(p)
		_pool.append(p)

func _start_music() -> void:
	_music           = AudioStreamPlayer.new()
	_music.bus       = "Master"
	_music.volume_db = -14.0
	add_child(_music)
	_music.stream = _make_music()
	_music.play()

# ── WAV encoding ──────────────────────────────────────────────────────────────

func _to_wav(buf: PackedFloat32Array, loop: bool = false) -> AudioStreamWAV:
	var wav        := AudioStreamWAV.new()
	wav.format      = 1   # FORMAT_16_BIT
	wav.stereo      = false
	wav.mix_rate    = RATE
	if loop:
		wav.loop_mode  = 1   # LOOP_FORWARD
		wav.loop_begin = 0
		wav.loop_end   = buf.size()
	var bytes := PackedByteArray()
	bytes.resize(buf.size() * 2)
	for i in range(buf.size()):
		var v := int(clampf(buf[i], -1.0, 1.0) * 32767.0)
		bytes[i * 2]     = v & 0xFF
		bytes[i * 2 + 1] = (v >> 8) & 0xFF
	wav.data = bytes
	return wav

# ── Oscillators ───────────────────────────────────────────────────────────────

func _sin(f: float, t: float) -> float:
	return sin(TAU * f * t)

func _sqr(f: float, t: float) -> float:
	return 1.0 if fmod(f * t, 1.0) < 0.5 else -1.0

func _saw(f: float, t: float) -> float:
	return fmod(f * t, 1.0) * 2.0 - 1.0

# ADSR — returns amplitude 0..1 given elapsed time t and total duration dur
func _adsr(t: float, dur: float, a: float, d: float, s: float, r: float) -> float:
	if t < 0.0:                 return 0.0
	if t < a:                   return t / a
	t -= a
	if t < d:                   return lerp(1.0, s, t / d)
	t -= d
	var hold := maxf(0.0, dur - a - d - r)
	if t < hold:                return s
	t -= hold
	if t < r:                   return lerp(s, 0.0, t / r)
	return 0.0

# ── Individual sound generators ───────────────────────────────────────────────

func _make_deploy() -> AudioStreamWAV:
	# Card-play: downward pitch sweep + bass thud
	var dur := 0.28
	var n   := int(dur * RATE)
	var buf := PackedFloat32Array(); buf.resize(n)
	for i in range(n):
		var t   := float(i) / RATE
		var env := _adsr(t, dur, 0.005, 0.06, 0.0, 0.20)
		var f: float = lerp(520.0, 160.0, t / dur)      # pitch glide down
		var v   := _sin(f, t) * 0.55 + _sin(f * 1.5, t) * 0.18
		var thud_env := _adsr(t, dur, 0.003, 0.10, 0.0, 0.12)
		v += _sin(75.0, t) * thud_env * 0.65
		buf[i] = v * env * 0.75
	return _to_wav(buf)

func _make_hit() -> AudioStreamWAV:
	# Melee sword clash — metallic crack + tone
	var dur := 0.18
	var n   := int(dur * RATE)
	var buf := PackedFloat32Array(); buf.resize(n)
	var rng := RandomNumberGenerator.new(); rng.seed = 3141
	for i in range(n):
		var t   := float(i) / RATE
		var env := _adsr(t, dur, 0.001, 0.012, 0.0, 0.14)
		var v   := _sin(1150.0, t) * 0.35 + _sin(2300.0, t) * 0.18 + _sin(3800.0, t) * 0.08
		v += (rng.randf() * 2.0 - 1.0) * exp(-t * 55.0) * 0.55  # noise crack
		buf[i] = v * env * 0.85
	return _to_wav(buf)

func _make_arrow() -> AudioStreamWAV:
	# Ranged shot — quick whoosh
	var dur := 0.18
	var n   := int(dur * RATE)
	var buf := PackedFloat32Array(); buf.resize(n)
	var rng := RandomNumberGenerator.new(); rng.seed = 2718
	for i in range(n):
		var t   := float(i) / RATE
		var env := _adsr(t, dur, 0.005, 0.04, 0.20, 0.08)
		var f: float = lerp(700.0, 280.0, t / dur)
		var v   := _sin(f, t) * 0.30 + (rng.randf() * 2.0 - 1.0) * 0.35
		buf[i] = v * env * 0.60
	return _to_wav(buf)

func _make_tower_hit() -> AudioStreamWAV:
	# Stone/wood impact when tower takes damage
	var dur := 0.24
	var n   := int(dur * RATE)
	var buf := PackedFloat32Array(); buf.resize(n)
	var rng := RandomNumberGenerator.new(); rng.seed = 9999
	for i in range(n):
		var t   := float(i) / RATE
		var env := _adsr(t, dur, 0.002, 0.06, 0.08, 0.14)
		var v   := _sin(110.0, t) * 0.50 + _sin(75.0, t) * 0.30
		v += (rng.randf() * 2.0 - 1.0) * exp(-t * 22.0) * 0.45
		buf[i] = v * env * 0.80
	return _to_wav(buf)

func _make_tower_destroy() -> AudioStreamWAV:
	# Big explosion-like boom
	var dur := 0.85
	var n   := int(dur * RATE)
	var buf := PackedFloat32Array(); buf.resize(n)
	var rng := RandomNumberGenerator.new(); rng.seed = 1234
	for i in range(n):
		var t   := float(i) / RATE
		var crack := (rng.randf() * 2.0 - 1.0) * exp(-t * 28.0) * 0.70
		var rumble := _sin(55.0, t) * exp(-t * 3.8) * 0.80
		rumble    += _sin(85.0, t) * exp(-t * 5.0)  * 0.45
		rumble    += _sin(120.0, t) * exp(-t * 6.5) * 0.25
		var noise := (rng.randf() * 2.0 - 1.0) * exp(-t * 5.5) * 0.45
		buf[i] = clampf(crack + rumble + noise, -1.0, 1.0) * 0.95
	return _to_wav(buf)

func _make_crown() -> AudioStreamWAV:
	# Ascending chime arpeggio: C5 → E5 → G5 → C6
	var dur    := 0.75
	var n      := int(dur * RATE)
	var buf    := PackedFloat32Array(); buf.resize(n)
	var notes  := [523.0, 659.0, 784.0, 1047.0]
	var delays := [0.00,  0.12,  0.24,  0.38 ]
	for i in range(n):
		var t := float(i) / RATE
		var v := 0.0
		for ni in range(notes.size()):
			var nt: float = t - float(delays[ni])
			if nt < 0.0:
				continue
			var note_dur: float = dur - float(delays[ni])
			var e: float = _adsr(nt, note_dur, 0.004, 0.04, 0.35, 0.35) * maxf(0.0, 1.0 - nt / note_dur)
			v += (_sin(float(notes[ni]), nt) * 0.45 + _sin(float(notes[ni]) * 2.0, nt) * 0.18) * e
		buf[i] = clampf(v, -1.0, 1.0) * 0.72
	return _to_wav(buf)

func _make_victory() -> AudioStreamWAV:
	# Short ascending fanfare (C major arpeggio)
	var dur     := 1.6
	var n       := int(dur * RATE)
	var buf     := PackedFloat32Array(); buf.resize(n)
	var mel     := [262.0, 330.0, 392.0, 523.0, 523.0]
	var timings := [0.00,  0.16,  0.32,  0.48,  0.68 ]
	var lengths := [0.14,  0.14,  0.14,  0.20,  0.80 ]
	for i in range(n):
		var t := float(i) / RATE
		var v := 0.0
		for ni in range(mel.size()):
			var nt: float = t - float(timings[ni])
			if nt < 0.0 or nt > float(lengths[ni]) + 0.4:
				continue
			var e: float = _adsr(nt, float(lengths[ni]) + 0.4, 0.006, 0.05, 0.5, 0.30)
			v += (_sin(float(mel[ni]), nt) * 0.5 + _sqr(float(mel[ni]), nt) * 0.18) * e * 0.42
		buf[i] = clampf(v, -1.0, 1.0)
	return _to_wav(buf)

# ── Background music (pre-synthesised 8-bar loop) ────────────────────────────
#
# A minor feel: Am - F - C - G (2 bars each = 8 bars total at 118 BPM)
# Layers: bass, pad, sparse pentatonic lead, kick/snare/hi-hat

func _make_music() -> AudioStreamWAV:
	var bpm    := 118.0
	var beat   := 60.0 / bpm
	var bar    := beat * 4.0
	var bars   := 8
	var dur    := bar * float(bars)
	var n      := int(dur * RATE)
	var buf    := PackedFloat32Array(); buf.resize(n)
	var rng    := RandomNumberGenerator.new(); rng.seed = 7777

	# Chord table (2 bars each): Am F C G Am F C G
	# Root, third, fifth in Hz (mid-register)
	var chord_roots  := [220.0, 174.6, 261.6, 196.0,  220.0, 174.6, 261.6, 196.0]
	var chord_thirds := [261.6, 220.0, 329.6, 246.9,  261.6, 220.0, 329.6, 246.9]
	var chord_fifths := [329.6, 261.6, 392.0, 293.7,  329.6, 261.6, 392.0, 293.7]

	# A-minor pentatonic melody notes
	var penta := [440.0, 523.3, 587.3, 659.3, 784.0, 880.0, 1046.5]
	# Sparse melody pattern (which 16th-note positions play): 16 slots per bar
	var mel_pat := [true, false, false, false,  true, false, true, false,
					false, false, true, false,  false, true, false, false]

	for i in range(n):
		var t        := float(i) / RATE
		var bar_idx  := int(t / bar) % bars
		var beat_in  := fmod(t / beat, 4.0)         # 0..4 within bar
		var sixteenth := int(beat_in * 4.0) % 16

		var root:  float = float(chord_roots[bar_idx])
		var third: float = float(chord_thirds[bar_idx])
		var fifth: float = float(chord_fifths[bar_idx])
		var v     := 0.0

		# ── Bass ─────────────────────────────────────────────────────────────
		# Plays root on beats 1&2, fifth on beats 3&4
		var bass_f  := root * 0.5 if beat_in < 2.0 else fifth * 0.5
		var note_t  := fmod(t, beat)
		var bass_e  := _adsr(note_t, beat, 0.010, 0.08, 0.60, 0.18)
		v += (_sin(bass_f, t) * 0.65 + _sin(bass_f * 2.0, t) * 0.22) * bass_e * 0.38

		# ── Pad (chord strum on beats 1 and 3) ───────────────────────────────
		var strum_t  := fmod(beat_in, 2.0) * beat   # time since last strum
		var pad_e    := exp(-strum_t * 0.9) * 0.38
		v += (_sin(root, t) * 0.28 + _sin(third, t) * 0.28 + _sin(fifth, t) * 0.28
			  + _sin(root * 2.0, t) * 0.16) * pad_e * 0.30

		# ── Melody (sparse, pentatonic) ───────────────────────────────────────
		if bool(mel_pat[sixteenth]):
			var mel_f: float = float(penta[(bar_idx * 3 + sixteenth) % penta.size()])
			var mel_t2 := fmod(t, beat * 0.25)
			var mel_e  := _adsr(mel_t2, beat * 0.25, 0.004, 0.04, 0.30, 0.12)
			v += _sin(mel_f, t) * mel_e * 0.18

		# ── Kick (beats 1 and 3) ─────────────────────────────────────────────
		var bi1 := beat_in
		var bi3 := beat_in - 2.0
		for bi: float in [bi1, bi3]:
			if bi >= 0.0 and bi < 0.06:
				var ke: float = exp(-bi * 60.0)
				var kf: float = 80.0 - bi * 500.0
				v += _sin(maxf(kf, 30.0), t) * ke * 0.58

		# ── Snare (beats 2 and 4) ─────────────────────────────────────────────
		var bi2 := beat_in - 1.0
		var bi4 := beat_in - 3.0
		for bi: float in [bi2, bi4]:
			if bi >= 0.0 and bi < 0.05:
				v += (rng.randf() * 2.0 - 1.0) * exp(-bi * 50.0) * 0.38
				v += _sin(220.0, t) * exp(-bi * 50.0) * 0.15

		# ── Hi-hat (every 16th note) ──────────────────────────────────────────
		var hat_t := fmod(t, beat * 0.25)
		if hat_t < 0.018:
			v += (rng.randf() * 2.0 - 1.0) * exp(-hat_t * 300.0) * 0.10

		buf[i] = clampf(v, -1.0, 1.0) * 0.85

	return _to_wav(buf, true)
