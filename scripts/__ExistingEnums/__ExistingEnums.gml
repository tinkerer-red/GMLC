function __ExistingEnums() {
	static __struct = {
		"AudioEffectType": {
			"Bitcrusher": AudioEffectType.Bitcrusher,
			"Delay": AudioEffectType.Delay,
			"Gain": AudioEffectType.Gain,
			"HPF2": AudioEffectType.HPF2,
			"LPF2": AudioEffectType.LPF2,
			"Reverb1": AudioEffectType.Reverb1,
			"Tremolo": AudioEffectType.Tremolo,
			"PeakEQ": AudioEffectType.PeakEQ,
			"HiShelf": AudioEffectType.HiShelf,
			"LoShelf": AudioEffectType.LoShelf,
			"EQ": AudioEffectType.EQ,
			"Compressor": AudioEffectType.Compressor,
		},
		"AudioLFOType": {
			"InvSawtooth": AudioLFOType.InvSawtooth,
			"Sawtooth": AudioLFOType.Sawtooth,
			"Sine": AudioLFOType.Sine,
			"Square": AudioLFOType.Square,
			"Triangle": AudioLFOType.Triangle,
		}
	}
	return __struct;
}

