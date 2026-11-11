function c = project_colors()
% PROJECT_COLORS  Colors of the families of statistics, shared by the video and the figures.
%
%   c = project_colors() returns
%     c.group_names   the six groups into which the families of statistics
%                     are gathered for display
%     c.group         6 x 3 color of each group (bars, symbols)
%     c.group_dark    6 x 3 darker version, for text in that color
%     c.group_of      function: family name -> index of its group
%     c.material      3 x 3 ramp for the three materials (C, R, S)
%     c.accent        color of the gaze window drawn on images
%     c.whole         color of the whole-statue reference (gray)

c.group_names = {'Luminance and contrast', 'Color', 'Highlights', 'Spatial structure', 'Motion', 'Geometry'};
c.group = [217 142  80;      % luminance and contrast: orange
           204 140 188;      % color: pink
           196 188 100;      % highlights: olive
            92 172 156;      % spatial structure: teal
           108 148 196;      % motion: blue
           160 160 160] / 255;   % geometry: gray
c.group_dark = [150  85  25;
                139  47 107;
                138 128  32;
                 12  84  68;
                 28  68 124;
                 85  85  85] / 255;
families = {'luminance', 'contrast', 'color', 'color_luminance', 'highlight', 'spatial', ...
            'temporal', 'flow', 'tracking', 'geometry'};
group_index = [1 1 2 2 3 4 5 5 5 6];
c.group_of = @(family) group_index(strcmp(families, family));
c.material = [124 204 188; 60 132 124; 4 52 52] / 255;     % light to dark teal
c.accent = [220 68 92] / 255;
c.whole  = [0.55 0.55 0.55];
end
