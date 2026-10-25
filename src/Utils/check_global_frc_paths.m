function check_global_frc_paths(projectRoot,caller)
%CHECK_GLOBAL_FRC_PATHS Prevent silent use of incompatible FRC functions.
% Executed by sFRC/sFSC after installing their temporary dependency paths.
coreDir=fullfile(projectRoot,'src','fSNR');
core={'performFRC','get_resolution','findIntercept','radial_sum', ...
      'meanFilter','apply_correction','diagonal_resample','correlation_threshold'};
for k=1:numel(core)
    target=fullfile(coreDir,[core{k} '.m']);
    found=which(core{k});
    if ~strcmpi(found,target)
        error([caller ':DependencyShadowing'], ...
            ['An incompatible dependency is shadowing %s.\n', ...
             'Expected: %s\nResolved: %s\n', ...
             'Change the current folder/remove the old MATLAB path, ', ...
             'then run rehash and clear functions.'],core{k},target,found);
    end
end
% The required function must accept the five inputs supplied by sFRC/sFSC.
if nargin('performFRC')~=5
    error([caller ':InvalidPerformFRCSignature'], ...
        'The FRC implementation must accept five inputs.');
end
end
