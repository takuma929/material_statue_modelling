function files = list_eye_movement_files(cfg)
% LIST_EYE_MOVEMENT_FILES  The eye-movement files named in config.json.
%
%   files = list_eye_movement_files(cfg) returns the files to process as a
%   cell array of full paths, sorted by name and without repeats. Each
%   entry of eye_movement_files in config.json is a file name or a pattern
%   with * (every file that matches), relative to the folder of the
%   repository or absolute; a bare file name is also looked for in
%   data/trajectories/. An entry that matches no file stops with a message.

files = {};
for i = 1:numel(cfg.run.eye_movement_files)
    entry = cfg.run.eye_movement_files{i};
    tries = {entry, fullfile(cfg.root, entry), fullfile(cfg.paths.trajectories, entry)};
    found = {};
    for k = 1:numel(tries)
        d = dir(tries{k});
        d = d(~[d.isdir]);
        if ~isempty(d)
            found = arrayfun(@(x) fullfile(x.folder, x.name), d, 'UniformOutput', false)';
            break
        end
    end
    assert(~isempty(found), 'list_eye_movement_files:none', ...
        'No file matches "%s" (eye_movement_files in config.json).', entry);
    files = [files, found]; %#ok<AGROW>
end
files = unique(files);
end
