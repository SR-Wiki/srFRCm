function note = sfsc_z_sampling_note(singleFrame, enabled, axialResolution)
note='';
if singleFrame && ~enabled && isfinite(axialResolution)
    note='Z sampling is OFF and can be enabled manually. If the axial resolution appears overly optimistic (too small), enable Z sampling and repeat the analysis.';
end
end
