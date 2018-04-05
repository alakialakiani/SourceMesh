function data = atemplate(varargin)
% Add networks and overlays to a smoothed brain mesh or gifti object.
%
% NOTE: Unknown BUG when using with Matlab 2015a on Linux.
% Tested working with Matlab 2014a & 2017a on Mac & Matlab 2012a on Linux.
%
% If you get error using the mex files, delete them. 
% 
%
%
% MESHES:
%--------------------------------------------------------------------------
%
%  % Plot the default template mesh:
%  atemplate()         
%
%  % Plot a supplied (gifti) mesh:
%  atemplate('gifti',mesh)   
%
%  % Plot mesh & write out gifti:
%  atemplate('gifti',mesh, 'write',name);  
%  
%  % Plot mesh from nifti volume:
%  atemplate('mesh','mymri.nii')
%
%
% OVERLAYS:
%--------------------------------------------------------------------------
%
%  % Plot template mesh with overlay from AAL90. L is [90x1]
%  atemplate('overlay',L);   
%
%  % Plot template with overlay values L at sourcemodel values sormod, interpolated on surface.
%  % Sormod is n-by-3, L is n-by-1.
%  atemplate('sourcemodel',sormod,'overlay',L)  
%
%  % Plot the supplied gifti mesh with overlay values L at sourcemodel locations 
%  % sormod interpolated on surface. 
%  % Sormod is n-by-3, L is n-by-1.
%  atemplate('gifti',mesh,'sourcemodel',sormod,'overlay',L)  
%
%  %  - Plot as above but write out TWO gifti files:
%  %  1. MYGifti.gii is the gifti mesh 
%  %  2. MYGiftiOverlay.gii is the corresponding overlay data
%  atemplate('gifti',mesh,'sourcemodel',sormod,'overlay',L,'write','MYGifti')  
%
%
%  % Plot overlay from nifti volume
%  atemplate('overlay','overlay_volume.nii')
%
%  *Note on sourcemodel option: Some fieldtrip sourcemodels have x & y
%  swapped (?), undo by doing sm = [sm(:,2),sm(:,1),sm(:,3)];
%
%  % Co-register the surfaces of the nii volumes in mesh and overlay,
%  % put in aal90 space and add labels:
%  atemplate('mesh',t1.nii,'overlay',functional.nii,'template','aal90','labels')
%
%
%  % Put overlay in AAL space and use interactive 'peaks' (clickable)
%  atemplate('sourcemodel',sormod,'overlay',randi([0 9],1000,1),'template','aal90','peaks')
%
% VIDEO OVERLAY:
%--------------------------------------------------------------------------
%
%  % Plot a video overlay and write it out:
%  atemplate('gifti',g,'sourcemodel',sormod,'video',m,'name',times); 
%
%  % Where:
%  - g      = the gifti surface to plot
%  - sormod = sourcemodel vertices
%  - m      = overlay values [vertices * ntimes] 
%  - name   = video savename
%  - times  = vector of titles (time values?)
%
%
% NETWORKS:
%--------------------------------------------------------------------------
%
%  % Plot template mesh with 90x90 AAL network, A:
%  atemplate('network',A); 
%
%  % Plot network A  at sourcemodel locations in 'sormod'. 
%  % Sormod is n-by-3, network is n-by-n.
%  atemplate('sourcemodel',sormod,'network',A);  
%
%  % As above but writes out .node and .edge files for the network, and the gifti mesh file.
%  atemplate('sourcemodel',sormod,'network',A,'write','savename'); 
%  
%  % Plot network defined by .edge and .node files*:
%  atemplate('network','edgefile.edge');
%  % Note, this option sets the 'sourcemodel' coordinates to the vertices
%  defined in the .node file, unless flag to register to atlas space
%
%
% Project to ATLAS
%--------------------------------------------------------------------------
%
%  % Put overlay into atlas space: [choose aal90, aal78 or aal58]
%  atemplate('sourcemodel',sormod,'overlay',o,'template','aal58')
%
%  % Put network into atlas space: 
%  atemplate('sourcemodel',sormod,'network',N,'template','aal78')
%
%  % Put video into atlas space: 
%  atemplate('sourcemodel',sormod,'video',m,'name',times,'template','aal78')
%
%
% OTHER:
%--------------------------------------------------------------------------
%
%  % Export 3D images (overlays, meshes, networks) as VRML & .stl:
%  atemplate( ... ,'writestl','filename.stl');
%  atemplate( ... ,'writevrml','filename.wrl');
%
%
%  % Plot default AAL90 node labels on default mesh:
%  atemplate('labels');         
%
%  % Plot specified labels at centre of roi's specified by all_roi_tissueindex:
%  atemplate('labels', all_roi_tissueindex, labels); 
%
%  % Where:
%  % all_roi_tissue = a 1-by-num-vertices vector containing indices of the
% roi this vertex belongs to
%  % 'labels' = the labels for each roi. 
%  % The text labels are added at the centre of the ROI.
%  
%  Labels notes:
%     - If plotting a network, only edge-connected nodes are labelled.
%     - If plotting a set of nodes (below), only those are labelled.
%     - Otherwise, all ROIs/node labels are added!
%
%  % Plot dots at node==1, i.e. N=[90,1]:
%  atemplate('nodes', N);             
%
%  % Plot tracks loaded with trk_read, from along-tract-stats toolbox.
%  % This function requires some work...
%  atemplate('tracks',tracks,header); 
%
%  Any combination of the inputs should be possible.
%  See scripts in 'Examples' folder for more help.
%
%
%
% AN EXAMPLE NETWORK [1]: from 5061 vertex sourcemodel with AAL90 labels
%--------------------------------------------------------------------------
% load New_AALROI_6mm.mat          % load ft source model, labels and roi_inds
% net  = randi([0 1],5061,5061);   % generate a network for this sourmod
% pos  = template_sourcemodel.pos; % get sourcemodel vertices
% labs = AAL_Labels;               % roi labels
% rois = all_roi_tissueindex;      % roi vertex indices
%
% atemplate('sourcemodel',pos,'network',net,'labels',rois,labs);
%
%
% AN EXAMPLE NETWORK [2]: from volume and node/edge files, put in aal58 space:
%--------------------------------------------------------------------------
% atemplate('mesh',t1.nii,'network','test_sourcemod.edge','template','aal58')
%
%
%
%  See also: slice3() slice2() 
%
% AS17


% Parse inputs
%--------------------------------------------------------------------------
in.all_roi_tissueindex = [];
data        = struct;
in.pmesh     = 1;
in.labels    = 0;
in.write     = 0;
in.fname     = [];
in.fighnd    = [];
in.colbar    = 1;
in.template  = 0;
in.orthog    = 0;
in.inflate   = 0;
in.peaks     = 0;
in.partialvol = 0;
in.thelabels  = [];
for i  = 1:length(varargin)
    if strcmp(varargin{i},'overlay');     in.L   = varargin{i+1}; end
    if strcmp(varargin{i},'peaks');       in.peaks = 1;           end
    if strcmp(varargin{i},'partialvol');  in.partialvol = 1;      end
    if strcmp(varargin{i},'sourcemodel'); in.pos = varargin{i+1}; end
    if strcmp(varargin{i},'network');     in.A   = varargin{i+1}; end
    if strcmp(varargin{i},'tracks');      in.T   = varargin{i+1}; in.H = varargin{i+2}; end
    if strcmp(varargin{i},'nosurf');      in.pmesh  = 0;            end
    if strcmp(varargin{i},'nodes');       in.N = varargin{i+1};     end
    if strcmp(varargin{i},'gifti');       in.g = varargin{i+1};     end
    if strcmp(varargin{i},'mesh');        in.g = varargin{i+1};     end
    if strcmp(varargin{i},'inflate');     in.inflate = 1;           end
    if strcmp(varargin{i},'orthog');      in.orthog = varargin{i+1};end
    if strcmp(varargin{i},'write');       in.write  = 1; in.fname = varargin{i+1}; end
    if strcmp(varargin{i},'writestl');    in.write  = 2; in.fname = varargin{i+1}; end
    if strcmp(varargin{i},'writevrml');   in.write  = 3; in.fname = varargin{i+1}; end
    if strcmp(varargin{i},'fighnd');      in.fighnd = varargin{i+1}; end
    if strcmp(varargin{i},'nocolbar');    in.colbar = 0;             end
    if strcmp(varargin{i},'video');       in.V     = varargin{i+1}; 
                                          in.fpath = varargin{i+2}; 
                                          in.times = varargin{i+3}; end
    if strcmp(varargin{i},'othermesh');   in.M = varargin{i+1}; in.O = varargin{i+2};   end  
    if strcmp(varargin{i},'labels');      in.labels = 1;
        try in.all_roi_tissueindex = varargin{i+1};
            in.thelabels = varargin{i+2};
        end
    end
    if strcmp(varargin{i},'template')
        in.template = 1;
        in.model    = varargin{i+1};
    end  
    
    % Allow passing of existing atemplate-returned structure 
    if isstruct(varargin{i}) && isfield(varargin{i},'in')
        fprintf('User specified plot structure\n');
        data = varargin{i};
        mesh = parse_mesh(data.mesh,data.in,data);
        data = parse_plots(data,data.in);
        return
    end
end


% Sourcemodel vertices
%--------------------------------------------------------------------------
data = sort_sourcemodel(data,in);

% Get Surface
%--------------------------------------------------------------------------
[mesh,data] = get_mesh(in,data);

% Template space? (currently aal90, aal78 or aal58)
%--------------------------------------------------------------------------
[data,in] = sort_template(data,in);

% Plot the glass brain we'll put everything else onto
%--------------------------------------------------------------------------
mesh = parse_mesh(mesh,in,data);
data.mesh = mesh;

% Do the plots: overlays, networks, tracts, nodes, videos etc.
%--------------------------------------------------------------------------
data = parse_plots(data,in);

% Return the input options for re-run
%--------------------------------------------------------------------------
data.in = in;

end




% FUNCTIONS
%--------------------------------------------------------------------------
%--------------------------------------------------------------------------
function data = parse_plots(data,i)

% unpack triggers
inputs = i;

% overlays
if isfield(inputs,'L')
    data.peaks      = i.peaks;
    data.partialvol = i.partialvol;
    data            = overlay(data, (i.L),i.write,i.fname,i.colbar);
end 

isover = exist('L','var') || exist('V','var');
if  isover && exist('A','var') 
    colbar = 0;
    alpha(.2);
end

% networks
if isfield(inputs,'A')
    data = connections(data,i.A,i.colbar,i.write,i.fname); 
end 

% tracts
if isfield(inputs,'T')
    data = drawtracks(data,i.T,i.H);                  
end 

% nodes
if isfield(inputs,'N')
    data = drawnodes(data, i.N);                 
end 

% labels
data = parse_labels(i,data);

% video
if isfield(inputs,'V')
    tv = 1:size(i.V,2);
    try tv = i.times; end
    data = video(data,i.V,1,i.fpath,tv); 
end


end

function data = parse_labels(i,data)
% decide which labels to include depending on what we're plotting
if i.labels 
    if     isfield(i,'A')
                if isnumeric(i.A)
                    data = addlabels(data,i.A,i.all_roi_tissueindex,i.thelabels);
                elseif ischar(i.A)
                    E = data.network.edge;
                    data = addlabels(data,E,i.all_roi_tissueindex,i.thelabels);
                end
           
    elseif isfield(i,'N')
        if sum(ismember(size(i.N),[1 90])) == 2
            data = addlabels(data, diag(i.N),i.all_roi_tissueindex,i.thelabels);
        elseif sum(ismember(size(i.N),[1 90])) == 1
            data = addlabels(data, diag(sum(i.N,2)),i.all_roi_tissueindex,i.thelabels);
        end
        
    else;  n    = length(data.sourcemodel.pos);
           data = addlabels(data, ones(n,n),i.all_roi_tissueindex,i.thelabels);
    end
end
end

function data = sort_sourcemodel(data,i)
% Sort out what source model vertices we're going to use

if      isfield(i,'pos')
        fprintf('Using supplied sourcemodel vertices\n');
        pos = i.pos;
        
elseif  isfield(i,'A') && ischar(i.A)
        fprintf('Using coords in node-file as sourcemodel\n');
        
        [~,pos] = rw_edgenode(i.A); 
        pos = pos(:,1:3);
        
%  elseif  isfield(i,'L') && ischar(i.L)
%          %IF USING A NIFTI OVERLAY AS SOURCEMODEL, NEED THIS *before* TRYING TO DO
%          %TEMPLATE SPACE CONVERSION!
%          
%          [mesh,data] = get_mesh(i,data);
%          data.mesh = mesh;
%          [~,data]  = parse_overlay(i.L,data);
%          pos       = data.sourcemodel.pos;
         
else
        fprintf('Assuming AAL90 source vertices by default\n');
        load('AAL_SOURCEMOD');
        pos  = template_sourcemodel.pos;
end

% Centre sourcemodel
pos = pos - repmat(spherefit(pos),[size(pos,1),1]);
data.sourcemodel.pos = pos;

end

function mesh = parse_mesh(mesh,i,data)
% Figure out whether we actually want to plot a glass brain mesh, or not


if     i.pmesh && ~isfield(i,'T')
       mesh = meshmesh(mesh,i.write,i.fname,i.fighnd,.3,data.sourcemodel.pos);
elseif i.pmesh
       mesh = meshmesh(mesh,i.write,i.fname,i.fighnd,.3,data.sourcemodel.pos);
end

end

function [mesh, data] = convert_mesh(mesh,data)

if ischar(mesh)
    [fp,fn,fe] = fileparts(mesh);
    
    switch fe
        case{'.nii'}
            % load nifti volume file
            fprintf('Reading Nifti volume\n');
            ni    = load_nii(mesh);
            vol   = ni.img;
            
            % bounds:
            fprintf('Extracting ISO surface\n');
            B   = [min(data.sourcemodel.pos); max(data.sourcemodel.pos)];
            fv  = isosurface(vol,0.5);
            
            % swap x y
            v  = fv.vertices;
            v  = [v(:,2) v(:,1) v(:,3)];
            fv.vertices = v;
             
            % reduce vertex density
            fprintf('Reducing patch density\n');
            nv  = length(fv.vertices);
            count  = 0;
            while nv > 60000
                fv    = reducepatch(fv, 0.5);
                nv    = length(fv.vertices);
                count = count + 1;
            end
            
            %if count > 0
            %    fprintf('Smoothing surface\n');
            %    fv.vertices = sms(fv.vertices,fv.faces,1,2);
            %end

            % print
            fprintf('Patch reduction finished after %d iterations\n',count);
            fprintf('Rescaling mesh to sourcemodel\n');
            
            v = fv.vertices;
            for i = 1:3
                v(:,i) = rescale(v(:,i),B(:,i));
            end
            
            % return scaled mesh
            mesh            = [];
            mesh.nifti      = [fn fe];
            mesh.faces      = fv.faces;
            mesh.vertices   = v;
            data.mesh       = mesh;
    end
    
elseif isnumeric(mesh) && ndims(mesh)==3
           
            % bounds:
            fprintf('Extracting ISO surface\n');
            B   = [min(data.sourcemodel.pos); max(data.sourcemodel.pos)];
            fv  = isosurface(mesh,0.5);
            
            % swap x y
            v  = fv.vertices;
            v  = [v(:,2) v(:,1) v(:,3)];
            fv.vertices = v;
             
            % reduce vertex density
            fprintf('Reducing patch density\n');
            nv  = length(fv.vertices);
            count  = 0;
            while nv > 60000
                fv    = reducepatch(fv, 0.5);
                nv    = length(fv.vertices);
                count = count + 1;
            end

            % print
            fprintf('Patch reduction finished after %d iterations\n',count);
            fprintf('Rescaling mesh to sourcemodel\n');
            
            v = fv.vertices;
            for i = 1:3
                v(:,i) = rescale(v(:,i),B(:,i));
            end
            
            % return scaled mesh
            mesh            = [];
            mesh.faces      = fv.faces;
            mesh.vertices   = v;
            data.mesh       = mesh;    
        
end

end

function [data,i] = sort_template(data,i)
% if specified a template model, put data into it and return splined dta as
% well as weights

if ~isfield(i,'pos')
    i.pos = data.sourcemodel.pos;
end
try
    data.template.model  = i.model;
    data.template.labels = i.labels;
end
if i.template
    atlas = dotemplate(i.model);
    rois  = get_roi_centres(atlas.template_sourcemodel.pos,atlas.all_roi_tissueindex);
    
    atlas.template_sourcemodel.pos = rois;
    atlas = rmfield(atlas,'all_roi_tissueindex');
    
    reg = interp_template(data.sourcemodel,rois);
    atlas.M    = reg.M;
    data.atlas = atlas;
    NM         = atlas.M;
    
    % rescale so not change amplitudes
    m  = max(NM(:));
    NM = NM/m; 
    
    % update sourcemodel and labels
    data.sourcemodel = atlas.template_sourcemodel;
    if i.labels; i.thelabels = atlas.AAL_Labels; end
    
    % overlay data
    if isfield(i,'L')
        if isnumeric(i.L) && ndims(i.L) ~= 3
            S  = [min(i.L(:)) max(i.L(:))];
            NL = i.L(:)'*NM;
            L  = S(1) + ((S(2)-S(1))).*(NL - min(NL))./(max(NL) - min(NL));
            L(isnan(L))=0;
            i.L = L;
        end
    end
    
    % network
    if isfield(i,'A')
        if isnumeric(i.A)
            S  = [min(i.A(:)) max(i.A(:))];
            NL = NM'*i.A*NM;
            A  = S(1) + ((S(2)-S(1))).*(NL - min(NL))./(max(NL) - min(NL));
            A(isnan(A)) = 0;
            i.A = A;
        end
    end
    
    % video data
    if isfield(i,'V')
        S  = [min(i.V(:)) max(i.V(:))];
        for j = 1:size(i.V,2) % over time points
            NL(:,j) = i.V(:,j)'*NM;
        end
        V  = S(1) + ((S(2)-S(1))).*(NL - min(NL))./(max(NL) - min(NL));
        V(isnan(V))=0;
        if orthog
            % dont use this
            V = symm_orthog(V);
        end
        V(isnan(V))=0;
        i.V = V;
    end
        
end

end

function [mesh,data] = get_mesh(i,data)
% decide what brain we're actually using, return it

try   mesh = i.g;
      fprintf('Using user provided mesh\n');
      
      if ischar(mesh) || isnumeric(mesh)
          [mesh,data] = convert_mesh(mesh,data);
      end
      
catch mesh = read_nv();
      fprintf('(Using template brain mesh)\n');
end

if i.inflate
    try fprintf('Trying to inflate mesh\n');
        dmesh.vertices = mesh.vertices;
        dmesh.faces    = mesh.faces;
        dmesh = spm_mesh_inflate(dmesh,100);
        mesh.vertices = dmesh.vertices;
        mesh.faces    = dmesh.faces;
    catch
        fprintf('Couldnt find spm_mesh_inflate: is SPM installed?\n');
    end
end


end

function atlas = dotemplate(model)
% Put dense sourcemodel into an atlas space using ICP and linear
% interpolation
%
%
%

switch model
    case lower({'aal','aal90'});   load New_AALROI_6mm.mat
    case lower('aal58');           load New_58cortical_AALROI_6mm
    case lower('aal78');           load New_AALROI_Cortical78_6mm
    otherwise
        fprintf('Model not found.\n');
        return;
end

atlas.AAL_Labels = AAL_Labels;
atlas.all_roi_tissueindex = all_roi_tissueindex;
atlas.template_sourcemodel = template_sourcemodel;

end

function atlas = interp_template(atlas,pos)

if length(atlas.pos) == length(pos)
    fprintf('Overlay and atlas Vectors already match!\n');
    atlas.M = eye(length(pos));
    return;
end

fprintf('Scanning points:\n');
M = zeros( length(atlas.pos), length(pos) );
r = 1;
w = 1;

dist  = cdist(pos,atlas.pos);    
for i = 1:length(atlas.pos)
    if i > 1; fprintf(repmat('\b',[size(str)])); end
    str = sprintf('%d/%d',i,(length(atlas.pos)));
    fprintf(str);

    [junk,ind] = maxpoints(dist(:,i),r,'min');
    M (i,ind)  = w;
end
fprintf('\n');
atlas.M = M;

end

function y = symm_orthog(x)
% Efficient orthogonalisation method for matrices, using:
%
% y = x * real(inv(x' * x)^(1/2));
%
% AS

fprintf('\nOrthogonalising\n');
y = [x] * real(inv([x]' * [x])^(1/2));
y = (max(x(:)) - min(x(:))) * ( (y - min(y(:))) / (max(y(:)) - min(y(:))) );

end

function data = connections(data,A,colbar,write,fname)
% Network (Node & Edges) plotter.
%
%
pos = data.sourcemodel.pos;

% Read edge/node files if string
%--------------------------------------------------------------------------
if ischar(A)
    [fp,fn,fe]  = fileparts(A);
    [edge,node] = rw_edgenode(fn);
    A           = edge;
    
    if isfield(data,'template')
        if isfield(data.template,'model')
           fprintf('Doing atlas registration\n');
           i.template = 1;
           i.model    = data.template.model;
           i.labels   = data.template.labels;
           i.A        = A;
           data.sourcemodel.pos = node(:,1:3);
           [data,i]   = sort_template(data,i);
           A          = i.A;
        end
    end
end

A(isnan(A)) = 0;
A(isinf(A)) = 0;

% Edges
%--------------------------------------------------------------------------
[node1,node2,strng] = matrix2nodes(A,pos);
RGB = makecolbar(strng);

% LineWidth (scaled) for strength
if any(strng)
    R = [min(strng),max(strng)];
    S = ( strng - R(1) ) + 1e-3;
    
    % If all edges same value, make thicker
    if  max(S(:)) == 1e-3; 
        S = 3*ones(size(S)); 
    end
else
    S = [0 0];
end

% If too few strengths, just use red edges
%--------------------------------------------------------------------------
LimC = 1;
if all(all(isnan(RGB)))
    RGB  = repmat([1 0 0],[size(RGB,1) 1]);
    LimC = 0;
end

data.network.edge = A;
data.network.node = pos;
data.network.RGB  = RGB;
data.network.tofrom.node1 = node1;
data.network.tofrom.node2 = node2;


% Paint edges
%--------------------------------------------------------------------------
for i = 1:size(node1,1)
    line([node1(i,1),node2(i,1)],...
        [node1(i,2),node2(i,2)],...
        [node1(i,3),node2(i,3)],...
        'LineWidth',S(i),'Color',[RGB(i,:)]);
end

% Set colorbar only if there are valid edges
%--------------------------------------------------------------------------
if any(i) && colbar
    set(gcf,'DefaultAxesColorOrder',RGB)
    if colbar
        colormap(jet)
        colorbar
    end
end
if LimC && colbar
    caxis(R);
end

drawnow;


% Nodes (of edges only)
%--------------------------------------------------------------------------
hold on;
for i = 1:size(node1,1)
    scatter3(node1(i,1),node1(i,2),node1(i,3),'filled','k');
    scatter3(node2(i,1),node2(i,2),node2(i,3),'filled','k');
end

drawnow;

if write;
   fprintf('Writing network: .edge & .node files\n');
   conmat2nodes(A,fname,'sourcemodel',pos);
end


end

function [node1,node2,strng] = matrix2nodes(A,pos)
% Write node & edge files for the AAL90 atlas
% Also returns node-to-node coordinates for the matrix specified.
%
% Input is the n-by-n connectivity matrix
% Input 2 is the sourcemodel vertices, n-by-3
%
% AS2017



node1 = []; node2 = []; strng = [];
for i = 1:length(A)
    [ix,iy,iv] = find(A(i,:));
    
    if ~isempty(ix)
        conns = max(length(ix),length(iy));
        for nc = 1:conns
            node1 = [node1; pos(i(1),:)];
            node2 = [node2; pos(iy(nc),:)];
            strng = [strng; iv(nc)];
        end
    end
end

end

function data = drawnodes(data, N)
% Node plotter. N = (90,1) with 1s for nodes to plot and 0s to ignore.
%
% 
hold on;
pos = data.sourcemodel.pos;
v   = pos*0.9;


if size(N,1) > 1 && size(N,2) > 1
    cols = {'r' 'm','y','g','c','b'};
    if size(size(N,2)) == 90
        N = N';
    end
    
    for j = 1:size(N,2)
        ForPlot = v(find(N(:,j)),:) + (1e-2 * (2*j) ) ;
        s       = find(N);
        col     = cols{j};
        for i   = 1:length(ForPlot)
            scatter3(ForPlot(i,1),ForPlot(i,2),ForPlot(i,3),70,col,'filled',...
                'MarkerFaceAlpha',.6,'MarkerEdgeAlpha',.6);        hold on;
        end
    end
    
else
    ForPlot = v(find(N),:);
    s       = find(N);
    for i   = 1:length(ForPlot)
        col = 'r';
        scatter3(ForPlot(i,1),ForPlot(i,2),ForPlot(i,3),s(i),'r','filled');
    end
end
%RGB = makecolbar(ForPlot);
%set(gcf,'DefaultAxesColorOrder',RGB); jet;
colorbar

data.drawnodes.data = ForPlot;

end

function RGB = makecolbar(I)
% Register colorbar values to our overlay /  T-vector
%

Colors   = jet;
NoColors = length(Colors);

Ireduced = (I-min(I))/(max(I)-min(I))*(NoColors-1)+1;
RGB      = interp1(1:NoColors,Colors,Ireduced);

end

function data = drawtracks(data,tracks,header)
% IN PROGRESS - BAD CODE - DONT USE
%
% - Use trk_read from 'along-tract-stats' toolbox
%
mesh = data.mesh;

hold on; clc;
All = [];

% put all tracks into a single matrix so we can fit a sphere
for iTrk = 1:length(tracks)
    if iTrk > 1; fprintf(repmat('\b',size(str))); end
    str = sprintf('Building volume for sphere fit (%d of %d)\n',iTrk,length(tracks));
    fprintf(str);
    
    matrix = tracks(iTrk).matrix;
    matrix(any(isnan(matrix(:,1:3)),2),:) = [];
    All = [All ; matrix];
end

% centre on 0 by subtracting sphere centre
iAll      = All;
iAll(:,1) = All(:,1)*-1;
iAll(:,2) = All(:,2)*-1;
Centre = spherefit(iAll);
maxpts = max(arrayfun(@(x) size(x.matrix, 1), tracks));

% Use minmax template vertices as bounds
MM(1,:) = min(mesh.vertices);
MM(2,:) = max(mesh.vertices);
MT(1,:) = min(iAll-repmat(Centre,[size(iAll,1),1]));
MT(2,:) = max(iAll-repmat(Centre,[size(iAll,1),1]));

pullback = min(MM(:,2)) - min(MT(:,2));
pullup   = max(MM(:,3)) - max(MT(:,3));

D = mean((MM)./MT);

% this time draw the tracks
for iTrk = 1:length(tracks)
    matrix = tracks(iTrk).matrix;
    matrix(any(isnan(matrix(:,1:3)),2),:) = [];
    
    matrix(:,1) = matrix(:,1)*-1; % flip L-R
    matrix(:,2) = matrix(:,2)*-1; % flip F-B
    M           = matrix - repmat(Centre,[size(matrix,1),1]); % centre
    M           = M.*repmat(D,[size(M,1),1]);
    M(:,2)      = M(:,2) + (pullback*1.1);                          % pullback
    M(:,3)      = M(:,3) + (pullup*1.1);                            % pull up

    h = patch([M(:,1)' nan], [M(:,2)' nan], [M(:,3)' nan], 0);
    cdata = [(0:(size(matrix, 1)-1))/(maxpts) nan];
    set(h,'cdata', cdata, 'edgecolor','interp','facecolor','none');
end

h = get(gcf,'Children');
set(h,'visible','off');

end

function [y,data] = parse_overlay(x,data)

if ischar(x)
    [fp,fn,fe] = fileparts(x);
    
    switch fe
        case{'.nii'}
            
            % load nifti volume file
            fprintf('Reading Nifti volume\n');
            ni    = load_nii(x);
            vol   = ni.img;
            [y,data] = vol2surf(vol,data);

            
        case{'.gii'}
            % load gifti functional
            gi = gifti(x);
            y  = double(gi.cdata);
            if length(Y) ~= length(data.sourcemodel.pos)
                fprintf('Gifti overlay does not match sourcemodel!\n');
            end
    end
end

if isnumeric(x) && ndims(x)==3
    % this is a pre-loaded nifti volume
    fprintf('This is a pre-loaded 3D nifti volume: extracting...\n');
    [y,data] = vol2surf(x,data);
    
end

end

function y = sym_pad_vector(x,n)

if length(x) ~= n
    k = n - length(x);
    k = floor(k/2);
    y = [zeros(1,k) x zeros(1,k)];
    
else y = x;
end

end

function [y,data] = vol2surf(vol,data)
% FUNCTIONAL volume to surface


% bounds:
S = size(vol);

% check if it's a 'full' volume!
if length(find(vol)) == prod(S)
    vol = vol - mode(vol);
end

B = [min(data.mesh.vertices); max(data.mesh.vertices)];

% new grid
fprintf('Generating grid for volume data\n');
x = linspace(B(1,1),B(2,1),S(1));
y = linspace(B(1,2),B(2,2),S(2));
z = linspace(B(1,3),B(2,3),S(3));

% find indiced of tissue in old grid
[nix,niy,niz] = ind2sub(size(vol),find(vol));
[~,~,C]       = find(vol);

% compile a new vertex list
fprintf('Compiling new vertex list (%d verts)\n',length(nix));
v = [x(nix); y(niy); z(niz)]';
v = double(v);

% reduce patch
fprintf('Reducing patch density\n');

nv  = length(v);
tri = delaunay(v(:,1),v(:,2),v(:,3));
fv  = struct('faces',tri,'vertices',v);
count  = 0;
while nv > 8000
    fv  = reducepatch(fv, 0.5);
    nv  = length(fv.vertices);
    count = count + 1;
end

% print
fprintf('Patch reduction finished after %d iterations\n',count);
fprintf('Using nifti volume as sourcemodel and overlay!\n');
fprintf('New sourcemodel has %d vertices\n',nv);

% find the indices of the retained vertexes only
fprintf('Retrieving vertex colours\n');
Ci = compute_reduced_indices(v, fv.vertices);

% Update sourcemodel and ovelray data
v                    = fv.vertices;
data.sourcemodel.pos = v;
y                    = C(Ci);

end


function indices = compute_reduced_indices(before, after)

indices = zeros(length(after), 1);
for i = 1:length(after)
    dotprods = (before * after(i, :)') ./ sqrt(sum(before.^2, 2));
    [~, indices(i)] = max(dotprods);
end
end

function y = rescale(x,S)

y = S(1) + (S(2)-S(1)) .* (x - min(x) ) / ...
    ( max(x) - min(x) );

end

function data = overlay(data,L,write,fname,colbar)
% Functional overlay plotter
%
% mesh is the gifti / patch
% L is the overlay (90,1)
% write is boolean flag
% fname is filename is write = 1;
%

if ~isnumeric(L) || (isnumeric(L) && ndims(L)==3)
    % is this is filename of a nifti or gifti file
   [L,data] = parse_overlay(L,data);
   
   if isempty(L)
        fprintf('Overlay does not match sourcemodel!\n');
        return;
   end
   if isfield(data,'template')
       if isfield(data.template,'model')
           fprintf('Doing atlas registration\n');
           i.template = 1;
           i.model    = data.template.model;
           i.labels   = data.template.labels;
           i.L        = L;
           [data,i]   = sort_template(data,i);
           L          = i.L;
       end
   end
end

data.overlay.orig = L;
if data.peaks
    n     = mean(L)+(2*std(L));
    [V,I] = find(abs(L) > n);

    if isfield(data,'atlas')
        Lab = data.atlas.AAL_Labels;
        data.Peaks.Labels = Lab(I);
        data.Peaks.Values = L(I);
    end
    
end

% interp shading between nodes or just use mean value?
%--------------------------------------------------------------------------
interpl = 1; 
pos     = data.sourcemodel.pos;
mesh    = data.mesh;

% Overlay
v  = pos;                       % sourcemodel vertices
x  = v(:,1);                    % AAL x verts
mv = mesh.vertices;             % brain mesh vertices
nv = length(mv);                % number of brain vertices
OL = sparse(length(L),nv);      % this will be overlay matrix we average
r = (nv/length(pos))*1.3;       % radius - number of closest points on mesh
w  = linspace(.1,1,r);          % weights for closest points
w  = fliplr(w);                 % 
M  = zeros( length(x), nv);     % weights matrix: size(len(mesh),len(AAL))
S  = [min(L(:)),max(L(:))];     % min max values

if write == 2
    r = (nv/length(pos))*5;
    w  = linspace(.1,1,r);          % 
    w  = fliplr(w);                 % 
elseif write == 3
    r = (nv/length(pos))*3;
    w  = linspace(.1,1,r);          % 
    w  = fliplr(w);                 % 
end

% if overlay,L, is same length as mesh verts, just plot!
%--------------------------------------------------------------------------
if length(L) == length(mesh.vertices)
    fprintf('Overlay already fits mesh! Plotting...\n');
    
    % spm mesh smoothing
    fprintf('Smoothing overlay...\n');
    y = spm_mesh_smooth(mesh, double(L(:)), 4);
    hh = get(gca,'children');
    set(hh(end),'FaceVertexCData',y(:),'FaceColor','interp');
    drawnow;
    shading interp
    colormap('jet');
    
    if colbar
        drawnow; pause(.5);
        colorbar('peer',gca,'South');
    end
    
    if write == 1
        fprintf('Writing overlay gifti file: %s\n',[fname 'Overlay.gii']);
        g       = gifti;
        g.cdata = double(y);
        g.private.metadata(1).name  = 'SurfaceID';
        g.private.metadata(1).value = [fname 'Overlay.gii'];
        save(g, [fname  'Overlay.gii']);
    elseif write == 2
            fprintf('Writing mesh and overlay as STL object\n');
        % write STL
        m.vertices = double(mesh.vertices);
        m.faces    = double(mesh.faces);
        y          = double(y);
        cdata      = mean(y(m.faces),2);

        % Write binary STL with coloured faces
        cLims = [min(cdata) max(cdata)];      % Transform height values
        nCols = 255;  cMap = jet(nCols);    % onto an 8-bit colour map
        fColsDbl = interp1(linspace(cLims(1),cLims(2),nCols),cMap,cdata);

        fCols8bit = fColsDbl*255; % Pass cols in 8bit (0-255) RGB triplets
        stlwrite([fname '.stl'],m,'FaceColor',fCols8bit)
        elseif write == 3 
        % write vrml
        fprintf('Writing vrml (.wrl) 3D object\n');
        vrml(gcf,[fname]);
    end
    return
end




% otherwise find closest points (assume both in mm)
%--------------------------------------------------------------------------
fprintf('Determining closest points between sourcemodel & template vertices\n');

for i = 1:length(x)
    if i > 1; fprintf(repmat('\b',[size(str)])); end
    str = sprintf('%d/%d',i,(length(x)));
    fprintf(str);

    dist       = cdist(mv,v(i,:));
    [junk,ind] = maxpoints(dist,r,'min');
    OL(i,ind)  = w*L(i);
    M (i,ind)  = w;
end

fprintf('\n');
clear L

if ~interpl
     % mean value of a given vertex
    OL = mean((OL),1);
else
    for i = 1:size(OL,2)
        % average overlapping voxels
        L(i) = sum( OL(:,i) ) / length(find(OL(:,i))) ;
    end
    OL = L;
end


% normalise and rescale
OL = double(full(OL));
y  = S(1) + ((S(2)-S(1))).*(OL - min(OL))./(max(OL) - min(OL));

y(isnan(y)) = 0;
y  = full(y);
y  = double(y);

% spm mesh smoothing
%--------------------------------------------------------------------------
fprintf('Smoothing overlay...\n');
y = spm_mesh_smooth(mesh, y(:), 4);
hh = get(gca,'children');
set(hh(end),'FaceVertexCData',y(:),'FaceColor','interp');
drawnow;
shading interp
colormap('jet');

data.overlay.data = y;
data.overlay.smooth_weights = M;


if colbar
    drawnow; pause(.5);
    colorbar('peer',gca,'South');    
end
    
if write == 1;
    fprintf('Writing overlay gifti file: %s\n',[fname 'Overlay.gii']);
    g       = gifti;
    g.cdata = double(y);
    g.private.metadata(1).name  = 'SurfaceID';
    g.private.metadata(1).value = [fname 'Overlay.gii'];
    save(g, [fname  'Overlay.gii']);
elseif write == 2 
        % write STL
        fprintf('Writing mesh and overlay as STL object\n');
        m.vertices = double(mesh.vertices);
        m.faces    = double(mesh.faces);
        y = spm_mesh_smooth(mesh, y(:), 8); % hard smoothing
        y          = double(y);
        cdata      = mean(y(m.faces),2);
        
        I = cdata;
        Colors   = jet;
        NoColors = length(Colors);

        Ireduced = (I-min(I))/(max(I)-min(I))*(NoColors-1)+1;
        RGB      = interp1(1:NoColors,Colors,Ireduced);
        
        fCols8bit= RGB*255;
        stlwrite([fname '.stl'],m,'FaceColor',fCols8bit)
elseif write == 3 
       % write vrml
       fprintf('Writing vrml (.wrl) 3D object\n');
       vrml(gcf,[fname]);
end

drawnow;

if isfield(data,'Peaks')
    if isfield(data.Peaks,'Labels')
        f0 = get(gca,'parent');
        f = figure('position',[1531         560         560         420]);
        t = uitable(f);
        for i = 1:length(data.Peaks.Labels)
            d{i,1} = data.Peaks.Labels{i};
            d{i,2} = data.Peaks.Values(i);
            d{i,3} = false;
        end
        d{i+1,1} = 'All';
        d{i+1,2} = '--';
        d{i+1,3} = false;
        
        t.Data = d;
        t.ColumnName = {'Position','Val','Spotlight'};
        t.ColumnEditable = true;
        
        %waitfor(f) % while the peaks box is open
        fprintf('Waiting: Click in peaks table to view peaks!\n');
        while isvalid(f)
            
            waitfor(t,'Data')
            i = find(cell2mat(t.Data(:,3)));
            if any(i)
                if i < length(d)
                    this = t.Data(i,:);
                    % work backwards to project only this component
                    thislab = find(strcmp(this{1},data.atlas.AAL_Labels));
                    dM      = M;
                    n       = 1:size(dM,1);
                    dM(find(~ismember(n,thislab)),:) = 0;
                    dM = dM'*data.overlay.orig(:);
                    dM = full(double(dM));
                    Y = spm_mesh_smooth(mesh, dM(:), 4);
                    
                    thefig = get(f0,'children');
                    hh = get(thefig(end),'children');
                    set(hh(end),'FaceVertexCData',Y(:),'FaceColor','interp');
                    drawnow;
                    shading interp
                else
                    % otherwise just plot the whole lot
                    thefig = get(f0,'children');
                    hh = get(thefig(end),'children');
                    set(hh(end),'FaceVertexCData',y(:),'FaceColor','interp');
                    drawnow;
                    shading interp
                end
            end
        
        end
        
    end
end

end





function x = killinterhems(x);

S  = size(x);
xb = (S(1)/2)+1:S(1);
yb = (S(2)/2)+1:S(2);
xa = 1:S(1)/2;
ya = 1:S(2)/2;

x(xa,yb) = 0;
x(xb,ya) = 0;

end




function newpos = fixmesh(g,pos)
% plot as transparent grey gifti surface
%
% AS

v = g.vertices;
v = v - repmat(spherefit(v),[size(v,1),1]); % Centre on ~0
g.vertices=v;

% Centre on ~0
pos = pos - repmat(spherefit(pos),[size(pos,1),1]);

for i = 1:length(pos)
    this  = pos(i,:);
    [t,I] = maxpoints(cdist(v,this),1,'max');
    newpos(i,:) = v(I,:);
end

end

function g = meshmesh(g,write,fname,fighnd,a,pos);

if isempty(a);
    a = .6;
end

% centre and scale mesh
v = g.vertices;
V = v - repmat(spherefit(v),[size(v,1),1]);

m = min(pos) *1.1;
M = max(pos) *1.1;

V(:,1)   = m(1) + ((M(1)-m(1))).*(V(:,1) - min(V(:,1)))./(max(V(:,1)) - min(V(:,1)));
V(:,2)   = m(2) + ((M(2)-m(2))).*(V(:,2) - min(V(:,2)))./(max(V(:,2)) - min(V(:,2)));
V(:,3)   = m(3) + ((M(3)-m(3))).*(V(:,3) - min(V(:,3)))./(max(V(:,3)) - min(V(:,3)));

g.vertices = V;

% plot
if ~isempty(fighnd)
    if isnumeric(fighnd)
        % Old-type numeric axes handle
        h = plot(fighnd,gifti(g));
    elseif ishandle(fighnd)
        % new for matlab2017b etc
        % [note editted gifti plot function]
        h = plot(gifti(g),'fighnd',fighnd);
    end
else
    h = plot(gifti(g));
end
C = [.5 .5 .5];

set(h,'FaceColor',[C]); box off;
grid off;  set(h,'EdgeColor','none');
alpha(a); set(gca,'visible','off');

h = get(gcf,'Children');
set(h(end),'visible','off');
drawnow;

if write;
    fprintf('Writing mesh gifti file: %s\n',[fname '.gii']);
    g = gifti(g);
    save(g,fname);
end


end

function data = addlabels(data,V,all_roi_tissueindex,thelabels)
% Add labels to the plot.
%
% If using AAL90 sourcemodle, these are automatic.
%
% If using another sourcemodel:
% - provide the all_roi_tissueindex from fieldtirp. This is a
% 1xnum_vertices vector containing indices of rois (i,e. which verts belong
% to which rois).
% Also provide labels!
%
pos = data.sourcemodel.pos;

if ( ~isempty(thelabels) && ~isempty(all_roi_tissueindex) ) &&...
   ( length(pos) == length(all_roi_tissueindex) ) &&...
   ( length(thelabels) == length(unique(all_roi_tissueindex(all_roi_tissueindex~=0))) )
    
    labels = strrep(thelabels,'_',' ');
    v      = get_roi_centres(pos,all_roi_tissueindex);
    roi    = all_roi_tissueindex;
    
elseif length(V) == 90
    
    load('AAL_labels');
    labels = strrep(labels,'_',' ');
    v      = pos*0.95;
    roi    = 1:90;
elseif (length(V) == length(thelabels)) &&...
       (length(V) == length(pos))
    
   labels = strrep(thelabels,'_',' ');
    v = pos*0.95;
    roi = 1:length(V);
else
    fprintf('Labels info not right!\n');
    return
end

data.labels.roi     = roi;
data.labels.labels  = labels;
data.labels.centres = v;

% compile list of in-use node indices
%--------------------------------------------------------------------------
to = []; from = []; 
for i  = 1:size(V,1)
    ni = find(logical(V(i,:)));
    if any(ni)
        to   = [to   roi(ni)];
        from = [from roi(repmat(i,[1,length(ni)])) ];
    end
end

AN  = unique([to,from]);
AN  = AN(AN~=0);
off = 1.5;
data.labels.in_use = AN;

% add these to plot with offset
%--------------------------------------------------------------------------
for i = 1:length(AN)
    L = labels{AN(i)};
    switch L(end)
        case 'L';
            t(i) = text(v(AN(i),1)-(off*5),v(AN(i),2)-(off*5),v(AN(i),3)+off,L);
        case 'R';
            t(i) = text(v(AN(i),1)+(off*2),+v(AN(i),2)+(off*2),v(AN(i),3)+off,L);
        otherwise
            t(i) = text(v(AN(i),1),v(AN(i),2),v(AN(i),3),L);
    end
end
set(t,'Fontsize',14)

end

function [C,verts] = get_roi_centres(pos,all_roi_tissueindex)
% Find centre points of rois
%
%
v   = pos;
roi = all_roi_tissueindex;

i   = unique(roi);
i(find(i==0))=[];

fprintf('Finding centre points of ROIs for labels...');
for j = 1:length(i)
    vox    = find(roi==i(j));
    verts{j}  = v(vox,:);
    C(j,:) = spherefit(verts{j});
end
fprintf('  ... done! \n');
% % Plot the first roi, mark centre and label:
% scatter3(v(:,1),v(:,2),v(:,3),'k'); hold on
% scatter3(verts(:,1),verts(:,2),verts(:,3),'r')
% scatter3(C(:,1),C(:,2),C(:,3),'b*')

end

function Centre = spherefit(X)
% Fit sphere to centre of vertices, return centre points
%
%

A =  [mean(X(:,1).*(X(:,1)-mean(X(:,1)))), ...
    2*mean(X(:,1).*(X(:,2)-mean(X(:,2)))), ...
    2*mean(X(:,1).*(X(:,3)-mean(X(:,3)))); ...
    0, ...
    mean(X(:,2).*(X(:,2)-mean(X(:,2)))), ...
    2*mean(X(:,2).*(X(:,3)-mean(X(:,3)))); ...
    0, ...
    0, ...
    mean(X(:,3).*(X(:,3)-mean(X(:,3))))];
A = A+A.';
B = [mean((X(:,1).^2+X(:,2).^2+X(:,3).^2).*(X(:,1)-mean(X(:,1))));...
     mean((X(:,1).^2+X(:,2).^2+X(:,3).^2).*(X(:,2)-mean(X(:,2))));...
     mean((X(:,1).^2+X(:,2).^2+X(:,3).^2).*(X(:,3)-mean(X(:,3))))];
Centre=(A\B).';
end


function data = video(data,L,colbar,fpath,tv)
%

% OPTIONS
%--------------------------------------------------------------------------
num         = 1;   % number of brains, 1 or 2
interpl     = 1;   % interpolate
brainview   = 'T'; % [T]op, [L]eft or [R]ight
videolength = 10;  % length in seconds
extendvideo = 0;   % smooth/extend video by factor of

pos  = data.sourcemodel.pos;
mesh = data.mesh; 

data.video.opt.num         = num;
data.video.opt.interpl     = interpl;
data.video.opt.brainview   = brainview;
data.video.opt.videolength = videolength;
data.video.opt.extendvideo = extendvideo;

% Extend and temporally smooth video by linear interp between points
%--------------------------------------------------------------------------
if extendvideo > 0
    fprintf('Extending and smoothing video sequence by linear interpolation\n');
    time  = tv;
    for i = 1:size(L,1)
        dL(i,:) = interp(L(i,:),4);
    end
    L  = dL;
    tv = linspace(time(1),time(end),size(L,2));
end

data.video.t = tv;
%data.video.data = L;

% Overlay
%--------------------------------------------------------------------------
v  = pos;
x  = v(:,1);                    % AAL x verts
mv = mesh.vertices;             % brain mesh vertices
nv = length(mv);                % number of brain vertices
ntime = size(L,2);
try
    OL = zeros(size(L,1),nv,ntime); % this will be overlay matrix we average
catch
    fprintf('------------------------ ERROR ------------------------\n');
    fprintf('_______________________________________________________\n');
    fprintf('Projection matrix too big: M(Sources*MeshVertices*Time)\n');
    fprintf('M = size( %d , %d, %d )\n',size(L,1),nv,ntime);
    fprintf('Try: (1). Reducing source by using AAL template flag: ''template'',''aal'' \n');
    fprintf('     (2). Subsample time\n');
    return;
end
r  = 1200;                      % radius - number of closest points on mesh
r  = (nv/length(pos))*1.3;
w  = linspace(.1,1,r);          % weights for closest points
w  = fliplr(w);                 % 
M  = zeros( length(x), nv);     % weights matrix: size(len(mesh),len(AAL))
S  = [min(L)',max(L)'];

% find closest points (assume both in mm)
%--------------------------------------------------------------------------
fprintf('Determining closest points between sourcemodel & template vertices\n');
for i = 1:length(x)

    % reporting
    if i > 1; fprintf(repmat('\b',[size(str)])); end
    str = sprintf('%d/%d',i,(length(x)));
    fprintf(str);    

    % find closest point[s] in cortical mesh
    dist       = cdist(mv,v(i,:));
    [junk,ind] = maxpoints(dist,r,'min');
    OL(i,ind,:)= w'*L(i,:);
    M (i,ind)  = w;  
    
end
fprintf('\n');


if ~interpl
    OL = mean((OL),1); % mean value of a given vertex
else
    fprintf('Averaging local & overlapping vertices (wait...)');
    for i = 1:size(OL,2)
        for j = 1:size(OL,3)
            % average overlapping voxels 
            L(i,j) = sum( OL(:,i,j) ) / length(find(OL(:,i,j))) ;
        end
    end
    fprintf(' ...Done\n');
    OL = L;
end

% normalise and rescale
for i = 1:size(OL,2)
    this    = OL(:,i);
    y(:,i)  = S(i,1) + ((S(i,2)-S(i,1))).*(this - min(this))./(max(this) - min(this));
end

y(isnan(y)) = 0;
y  = full(y);

% spm mesh smoothing
fprintf('Smoothing overlay...\n');
for i = 1:ntime
    y(:,i) = spm_mesh_smooth(mesh, double(y(:,i)), 4);
end

data.video.data = y;
data.video.weights = M;

% close image so can reopen with subplots
if num == 2;
    close
    f  = figure;
    set(f, 'Position', [100, 100, 2000, 1000])
    h1 = subplot(121);
    h2 = subplot(122);
else
    switch brainview
        case 'T'; bigimg;view(0,90);
        case 'R'; bigimg;view(90,0);  
        case 'L'; bigimg;view(270,0); 
    end
    f = gcf;
end

% MAKE THE GRAPH / VIDEO
%--------------------------------------------------------------------------
try    vidObj   = VideoWriter(fpath,'MPEG-4');          % CHANGE PROFILE
catch  vidObj   = VideoWriter(fpath,'Motion JPEG AVI');
end

set(vidObj,'Quality',100);
set(vidObj,'FrameRate',size(y,2)/(videolength));
open(vidObj);

for i = 1:ntime
    
    if i > 1; fprintf(repmat('\b',[1 length(str)])); end
    str = sprintf('building: %d of %d\n',i,ntime);
    fprintf(str);
    
    switch num
        case 2
            plot(h1,gifti(mesh));
            hh       = get(h1,'children');
            set(hh(end),'FaceVertexCData',y(:,i), 'FaceColor','interp');    
            shading interp
            view(270,0);
            caxis([min(S(:,1)) max(S(:,2))]);
            material dull
            camlight left 

            plot(h2,gifti(mesh));
            hh       = get(h2,'children');
            set(hh(3),'FaceVertexCData',y(:,i), 'FaceColor','interp');    
            shading interp
            view(90,0);
            caxis([min(S(:,1)) max(S(:,2))]);
            material dull
            camlight right 
        
        case 1
            hh = get(gca,'children');
            set(hh(end),'FaceVertexCData',y(:,i), 'FaceColor','interp');
            caxis([min(S(:,1)) max(S(:,2))]);
            shading interp
    end
    
    try
        tt = title(num2str(tv(i)),'fontsize',20);
        P = get(tt,'Position') ;
        P = P/max(P(:));
        set(tt,'Position',[P(1) P(2)+70 P(3)]) ;
    end
    
    set(findall(gca, 'type', 'text'), 'visible', 'on');
    
    if colbar
        colorbar
    end
    drawnow;
            
              

    currFrame = getframe(f);
    writeVideo(vidObj,currFrame);
end
close(vidObj);


    
end
















% Notes / Workings
%---------------------------------------------------
    %rotations - because x is orientated backward?
%     t  = 90;
%     Rx = [ 1       0       0      ;
%            0       cos(t) -sin(t) ;
%            0       sin(t)  cos(t) ];
%     Ry = [ cos(t)  0      sin(t)  ;
%            0       1      0       ;
%           -sin(t)  0      cos(t)  ];
%     Rz = [ cos(t) -sin(t) 0       ;
%            sin(t)  cos(t) 0       ;
%            0       0      1       ];
   %M = (Rx*(M'))';
   %M = (Ry*(M'))';
   %M = (Rz*(M'))';

   
