function assert_demo_helper_paths(projectRoot, helpers)
%ASSERT_DEMO_HELPER_PATHS Detect mixed srFRCm releases before plotting.
% This is a path check only and does not change the numerical workflow.
expectedDir=fullfile(projectRoot,'src','Utils');
for k=1:numel(helpers)
    helper=helpers{k};
    expected=fullfile(expectedDir,[helper '.m']);
    actual=which(helper);
    if ~strcmpi(actual,expected)
        error('srFRC:DemoHelperShadowing', ...
            ['The demo is resolving an incompatible plotting/export helper: %s.\n' ...
             'Expected: %s\nResolved: %s\n' ...
             'Remove old srFRCm folders from the MATLAB path, then run ' ...
             'clear functions and rehash before rerunning the demo.'], ...
            helper, expected, actual);
    end
end
end
