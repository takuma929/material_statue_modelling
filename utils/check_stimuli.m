function check_stimuli(cfg)
% CHECK_STIMULI  Stop with a clear message if the stimulus files are missing.
%
%   check_stimuli(cfg) verifies that the stimulus files of every condition
%   are where cfg.stimulus says they are. The stimuli are not distributed
%   with the code: the nine files BC.mat, BR.mat, BS.mat, HC.mat, HR.mat,
%   HS.mat, PC.mat, PR.mat and PS.mat go into data/MAT-images/.

missing = {};
for c = 1:numel(cfg.conditions)
    switch lower(cfg.stimulus.format)
        case 'mat'
            item = fullfile(cfg.stimulus.dir, sprintf(cfg.stimulus.mat_pattern, cfg.conditions{c}));
            found = exist(item, 'file') == 2;
        case 'png'
            item = fullfile(cfg.stimulus.dir, sprintf(cfg.stimulus.folder_pattern, cfg.conditions{c}));
            found = exist(item, 'dir') == 7;
        otherwise
            error('check_stimuli:format', 'cfg.stimulus.format must be ''mat'' or ''png''.');
    end
    if ~found, missing{end + 1} = item; end %#ok<AGROW>
end
if ~isempty(missing)
    error('check_stimuli:missing', ['Stimulus files not found:\n  %s\n' ...
        'Put the nine stimulus files (BC.mat, BR.mat, ..., PS.mat) in\n  %s\n(see README.md, "Put the stimuli in place").'], ...
        strjoin(missing, '\n  '), cfg.stimulus.dir);
end
end
