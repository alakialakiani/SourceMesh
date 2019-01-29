function varargout = SourceMeshGUI(varargin)
% Haven't written this help yet, but the gui should be pretty intuitive...
%
%
%
%
%
%
% AS


% Last Modified by GUIDE v2.5 14-Aug-2018 15:35:52

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @SourceMeshGUI_OpeningFcn, ...
                   'gui_OutputFcn',  @SourceMeshGUI_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before SourceMeshGUI is made visible.
function SourceMeshGUI_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to SourceMeshGUI (see VARARGIN)

% Choose default command line output for SourceMeshGUI
handles.output = hObject;

% make sure we have local subpaths added - this is mainly for accessing mat
% files within the package as well as ensuring we use my @gifti objects,
% not the fieldtrip ones
[fp,fn,fe] = fileparts(mfilename('fullpath'));
fp = fileparts(fp);
fprintf('Adding subpaths to ensure local function calls:\n(%s)\n',fp);
addpath(genpath(fp));

% set initial slider position
set(handles.slider1, 'min',-2);
set(handles.slider1, 'max', 8);
set(handles.slider1,'Value',1);

set(handles.slider2,'Value',1);
set(handles.slider3,'Value',1);

[handles.data,handles.i] = aplot.defaults();


% Update handles structure
guidata(hObject, handles);

% UIWAIT makes SourceMeshGUI wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = SourceMeshGUI_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;




% MESH FUNCTIONS
%--------------------------------------------------------------------------

% --- Executes on button press in pushbutton1.
function pushbutton1_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Default Mesh Button
%handles.mesh.g = read_nv;
G = read_nv;

data = handles.data;
i    = handles.i;

i.g = G;
data = aplot.sort_sourcemodel(data,i);
[mesh,data] = aplot.get_mesh(i,data);        % Get Surface

switch class(mesh)
    case 'gifti'
        new = struct;
        new.vertices = mesh.vertices;
        new.faces = mesh.faces;
        mesh = new;
end
    
handles.mesh = mesh;
handles.data = data;

% now plot the mesh
[handles.mesh.h,handles.mesh.vnorm] = meshmesh(handles,handles.mesh);



%[handles.mesh.h,handles.mesh.vnorm] = meshmesh(handles,handles.mesh.g);

% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbutton2.
function pushbutton2_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Patch gifti from workspace

list = evalin('base','whos');
opt  = menu('Select structure / patch / gifti:',{list.name});
list = {list.name};
var  = list{opt};
%handles.mesh.g = evalin('base',var);
G = evalin('base',var);

data = handles.data;
i    = handles.i;

i.g  = G;
data = aplot.sort_sourcemodel(data,i);
[mesh,data] = aplot.get_mesh(i,data);        % Get Surface

switch class(mesh)
    case 'gifti'
        new = struct;
        new.vertices = mesh.vertices;
        new.faces = mesh.faces;
        mesh = new;
end
    

handles.mesh = mesh;
handles.data = data;

% now plot the mesh
[h,handles.mesh.vnorm] = meshmesh(handles,handles.mesh);

handles.mesh.h = h;
%[handles.mesh.h,handles.mesh.vnorm] = meshmesh(handles,handles.mesh.g);

% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in pushbutton4.
function pushbutton4_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Load nifti/gifti file
[FileName,PathName,FilterIndex] = uigetfile({'*.nii;*.gii','G/Nifti'},'Select File');
G = [PathName FileName];
[pn,fn,e] = fileparts(G);

data = handles.data;
i    = handles.i;

i.g  = G;
data = aplot.sort_sourcemodel(data,i);
[mesh,data] = aplot.get_mesh(i,data);        % Get Surface

switch class(mesh)
    case 'gifti'
        new = struct;
        new.vertices = mesh.vertices;
        new.faces = mesh.faces;
        mesh = new;
end
    
handles.mesh = mesh;
handles.data = data;

% now plot the mesh
[handles.mesh.h,handles.mesh.vnorm] = meshmesh(handles,handles.mesh);


% Update handles structure
guidata(hObject, handles);



function [h,vnorm] = meshmesh(handles,g)

axes(handles.axes1);

cla; 

% only one hemisphere?
v = g.vertices;
f = g.faces;
c = spherefit(v);

v = v - repmat(c, [size(v,1),1]); % Centre first!

c = spherefit(v);

left  = find(v(:,1) < c(1));
right = find(v(:,1) > c(1));

lfaces = find(sum(ismember(f,left),2)==3);
rfaces = find(sum(ismember(f,right),2)==3);

% if gifti, change to struct before we change back
switch class(g)
    case 'gifti'
        new          = struct;
        new.vertices = g.vertices;
        new.faces    = g.faces;
        g            = new;
end

% return left/right indices
g.vleft            = v*NaN;
g.vleft(left,:)    = v(left,:);
g.vright           = v*NaN;
g.vright(right,:)  = v(right,:);
g.fleft            = f*NaN;
g.fleft(lfaces,:)  = f(lfaces,:);
g.fright           = f*NaN;
g.fright(rfaces,:) = f(rfaces,:);

hemisphere = 'both';

try
    hemisphere = handles.mesh.hemisphere;
end

switch hemisphere
    case {'left','L','l'}
        pg.vertices         = double(v*NaN);
        pg.vertices(left,:) = double(v(left,:));
        pg.faces            = double(f*NaN);
        pg.faces(lfaces,:)  = double(f(lfaces,:));
  
    case{'right','R','r'}
        pg.vertices          = double(v*NaN);
        pg.vertices(right,:) = double(v(right,:));
        pg.faces             = double(f*NaN);
        pg.faces(rfaces,:)   = double(f(rfaces,:));        
        
    otherwise
        pg = g;
end

%fighnd = handles.axes1;

% sanity check
if any( min(pg.faces(:)) == 0)
    bad = find(pg.faces == 0);
    pg.faces(bad) = nan;
end

if isnumeric(handles.axes1)
    % Old-type numeric axes handle
    h = plot(handles.axes1,gifti(pg));
elseif ishandle(handles.axes1)
    % new for matlab2017b etc
    % [note editted gifti plot function]
    h = plot(gifti(pg),'fighnd',handles.axes1);
end

C = [.5 .5 .5];

set(h,'FaceColor',[C]); box off;
grid off;  set(h,'EdgeColor','none');
alpha(.7); set(gca,'visible','off');

%h = get(gcf,'Children');
%set(h(end),'visible','off');
set(gca,'visible','off')

axis image
view(3);
set(handles.axes1,'view',[0   84.9160]);
rotate3d on;
drawnow; 

vnorm = spm_mesh_normals(struct('vertices',g.vertices,'faces',g.faces));

%vnorm = spm_mesh_normals(struct('vertices',pg.vertices,'faces',pg.faces));




% OVERLAY FUNCTIONS
%--------------------------------------------------------------------------

% --- Executes on button press in pushbutton5.
function pushbutton5_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% overlay sourcemodel matrix
list = evalin('base','whos');
opt  = menu('Select variable (nx3)',{list.name});
list = {list.name};
var  = list{opt};
handles.overlay.sourcemodel = evalin('base',var);

% Fit this grid inside the extremes of the mesh
v        = handles.overlay.sourcemodel;
B        = [min(handles.mesh.g.vertices); max(handles.mesh.g.vertices)];
V        = v - repmat(spherefit(v),[size(v,1),1]);
V(:,1)   = B(1,1) + ((B(2,1)-B(1,1))).*(V(:,1) - min(V(:,1)))./(max(V(:,1)) - min(V(:,1)));
V(:,2)   = B(1,2) + ((B(2,2)-B(1,2))).*(V(:,2) - min(V(:,2)))./(max(V(:,2)) - min(V(:,2)));
V(:,3)   = B(1,3) + ((B(2,3)-B(1,3))).*(V(:,3) - min(V(:,3)))./(max(V(:,3)) - min(V(:,3)));
handles.overlay.sourcemodel        = V;



% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbutton6.
function pushbutton6_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton6 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% overlay data for sourcemodel matrix
list = evalin('base','whos');
opt  = menu('Select variable (nx1)',{list.name});
list = {list.name};
var  = list{opt};
handles.overlay.data = evalin('base',var);

% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in pushbutton8.
function pushbutton8_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton8 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% load functional nifti/gifti button
[FileName,PathName,FilterIndex] = uigetfile({'*.nii;*.gii','G/Nifti'},'Select File');
G = [PathName FileName];
[pn,fn,e] = fileparts(G);

handles.data.overlay = [];
handles.data.mesh    = handles.mesh;
[y,data] = aplot.parse_overlay(G,handles.data);

handles.overlay.data = y;
handles.data = data;


% switch e
%     case '.gii'
%         olay = gifti(G);
%         y    = double(olay.cdata);
%         
%         % check it's the same length as the structural mesh
%         if length(y) ~= length(handles.mesh.g.vertices);
%             error('This should be the same length as the structural mesh vertices!');
%         else
%             handles.overlay.data = y;
%             handles.overlay.sourcemodel = handles.mesh.g.vertices;
%         end
% 
%     case '.nii'
%         
%         % load nifti volume file
%         fprintf('Reading Nifti volume: wait for ''finished''\n');
%         ni    = load_nii(G);
%         vol   = ni.img;
%         
%         % retain header info?
%         handles.volume.fname     = G;
%         handles.volume.hdr       = ni.hdr;
%         
%         % bounds:
%         S = size(vol);
% 
%         % check if it's a 'full' volume!
%         if length(find(vol)) == prod(S)
%             vol = vol - mode(vol(:));
%         end
% 
%         % a little smoothing
%         vol = smooth3(vol,'gaussian');
% 
%         % New --- 
%         pixdim = ni.hdr.dime.pixdim(2:4);
% 
%         x = 1:size(vol,1);
%         y = 1:size(vol,2);
%         z = 1:size(vol,3);
% 
%         % find indiced of tissue in old grid
%         [nix,niy,niz] = ind2sub(size(vol),find(vol));
%         [~,~,C]       = find(vol);
% 
%         % compile a new vertex list
%         fprintf('Compiling new vertex list (%d verts)\n',length(nix));
%         v = [x(nix); y(niy); z(niz)]';
%         v = double(v);
%         v = v*diag(pixdim);
% 
% %         % apply affine if req.
% %         if isfield(handles.overlay,'affine')
% %             affine = data.overlay.affine;
% %             if length(affine) == 4
% %                 fprintf('Applying affine transform\n');
% %                 va = [v ones(length(v),1)]*affine;
% %                 v  = va(:,1:3);
% %             end
% %         end
% 
%         % Fit this gridded-volume inside the extremes of the mesh
%         B        = [min(handles.mesh.g.vertices); max(handles.mesh.g.vertices)];
%         V        = v - repmat(spherefit(v),[size(v,1),1]);
%         V(:,1)   = B(1,1) + ((B(2,1)-B(1,1))).*(V(:,1) - min(V(:,1)))./(max(V(:,1)) - min(V(:,1)));
%         V(:,2)   = B(1,2) + ((B(2,2)-B(1,2))).*(V(:,2) - min(V(:,2)))./(max(V(:,2)) - min(V(:,2)));
%         V(:,3)   = B(1,3) + ((B(2,3)-B(1,3))).*(V(:,3) - min(V(:,3)))./(max(V(:,3)) - min(V(:,3)));
%         v        = V;
% 
%         % reduce patch
%         fprintf('Reducing patch density\n');
% 
%         nv  = length(v);
%         tri = delaunay(v(:,1),v(:,2),v(:,3));
%         fv  = struct('faces',tri,'vertices',v);
%         count  = 0;
% 
%         % smooth overlay at triangulated points first
%         Cbound = [min(C) max(C)];
%         C      = spm_mesh_smooth(fv,double(C),4);
%         C      = Cbound(1) + (Cbound(2)-Cbound(1)).*(C - min(C))./(max(C) - min(C));
% 
%         while nv > 10000
%            fv  = reducepatch(fv, 0.5);
%            nv  = length(fv.vertices);
%            count = count + 1;
%         end
% 
%         % print
%         fprintf('Patch reduction finished\n');
%         fprintf('Using nifti volume as sourcemodel and overlay!\n');
%         fprintf('New sourcemodel has %d vertices\n',nv);
% 
%         % find the indices of the retained vertexes only
%         fprintf('Retrieving vertex colours\n');
%         Ci = compute_reduced_indices(v, fv.vertices);
% 
%         fprintf('Finished\n');
%         
%         % Store sourcemodel and ovelray data
%         v                           = fv.vertices;
%         handles.overlay.sourcemodel = v;
%         handles.overlay.data        = C(Ci);
%    
% end

% Update handles structure
guidata(hObject, handles);




function indices = compute_reduced_indices(before, after)

indices = zeros(length(after), 1);
for i = 1:length(after)
    dotprods = (before * after(i, :)') ./ sqrt(sum(before.^2, 2));
    [~, indices(i)] = max(dotprods);
end



% --- Executes on selection change in listbox2.
function listbox2_Callback(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns listbox2 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from listbox2

% OVERLAY PROJECT METHOD
contents = cellstr(get(hObject,'String'));
option = contents{get(hObject,'Value')};

handles.overlay.method = option;

% Update handles structure
guidata(hObject, handles);



% --- Executes during object creation, after setting all properties.
function listbox2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to listbox2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end



% --- Executes on button press in pushbutton12.
function pushbutton12_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton12 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Make overlay button

% Initial checks
hasmesh   = isfield(handles,'mesh');
hasoverlay = isfield(handles,'overlay');
hassource = isfield(handles.data,'sourcemodel');

handles.data.overlay.method = handles.overlay.method;

if hasmesh && hassource && hasoverlay
   
    %handles = overlay(handles);
    handles.data.overlay.method = handles.overlay.method;
    handles.data.overlay.peaks   = 0;
    
    data = aplot.overlay(handles.data,handles.overlay.data,handles.i.write,handles.i.write,handles.i.colbar);
    % Functional overlay plotter
    %
    % mesh is the gifti / patch
    % L is the overlay (90,1)
    % write is boolean flag
    % fname is filename is write = 1;
    %
    
end


% Update handles structure
guidata(hObject, handles);


% main overlay machinery
function handles = overlay(handles)

data.mesh        = handles.mesh;
data.sourcemodel = handles.overlay.sourcemodel;
data.overlay     = handles.overlay;
L                = handles.overlay.data;

colbar = 1;
fname  = [];
write  = 0;

%
% mesh is the gifti / patch
% L is the overlay (90,1)
% write is boolean flag
% fname is filename is write = 1;
%

% method for searching between the 3D coordinate
%-------------------------------------------------------------
if ~isfield(data.overlay,'method')
    data.overlay.method = 'Raycast';
end
if ismember(data.overlay.method,{'Euclidean','Inflated spheres','precomputed (AAL)','Raycast'})
     method = data.overlay.method;
else,method = 'Raycast';  
end

% Add this special case, where using default 81k mesh and 90-node AAL
% overlay, we'll use pre-computed weights for speed
%--------------------------------------------------------------------------
if isnumeric(L) && ndims(L)==2 && length(L)==90 && length(handles.mesh.g.vertices)== 81924 && ...
        strcmp(handles.overlay.method,'Euclidean')
    
     fprintf('Using default AAL90 weights for this mesh\n');
     load('AAL90DefaultWeights','M','NumComp','indz','w');
     
     % incorporate overlay into precomputed weights matrix
     for k = 1:length(L)
         M(k,indz(k,:)) = L(k) * M(k,indz(k,:));
     end
     
     % normalise by number of overlapping points at this vertex
     for i = 1:size(M,2)
         y(i) = sum( M(:,i) ) / length(find(M(:,i))) ;
     end   
     
     % rescale y by L limits
     S  = [min(L(:)),max(L(:))];   
     y  = S(1) + ((S(2)-S(1))).*(y - min(y))./(max(y) - min(y));
     y(isnan(y)) = 0;
     L  = y;
     data.method = 'precomputed (AAL)';
end




data.overlay.orig = L;

% interp shading between nodes or just use mean value?
%--------------------------------------------------------------------------
interpl = 1; 
pos     = data.sourcemodel;
mesh    = data.mesh;
mesh.vertices = mesh.g.vertices;
mesh.faces    = mesh.g.faces;



% if overlay,L, is same length as mesh verts, just plot!
%--------------------------------------------------------------------------
if length(L) == length(mesh.vertices)
    fprintf('Overlay already fits mesh! Plotting...\n');
    
    % spm mesh smoothing
    fprintf('Smoothing overlay...\n');
    y = spm_mesh_smooth(mesh, double(L(:)), 4);
    percNaN = length(find(isnan(L)))/length(L)*100;
    newpNaN = length(find(isnan(y)))/length(y)*100;
    
    % when using a NaN-masked overlay, smoothing can result in all(nan) or
    % an increase in the number of nans: enforce a 5% tolerance on this, which
    % forces reverting to the uns-smoothed version if reached
    if all(isnan(y)) || newpNaN > (percNaN*1.05)
        fprintf('Reverting to non-smoothed overlay due to too many NaNs\n');
        y = L(:);
    end
    
    set(handles.mesh.h,'FaceVertexCData',y(:),'FaceColor','interp');
    
    drawnow;
    shading interp
    % force symmetric caxis bounds
    s = max(abs(y(:))); caxis([-s s]);
    colormap('jet');
    alpha 1;
    
    if colbar
        %colorbar('peer',a1,'South');
        handles.overlay.cb = InteractiveColorbar;
    end
    handles.overlay.limits = s;
    
else

% otherwise find closest points (assume both in mm)
%--------------------------------------------------------------------------

% Overlay
v  = pos;                       % sourcemodel vertices
x  = v(:,1);                    % AAL x verts
mv = mesh.vertices;             % brain mesh vertices
nv = length(mv);                % number of brain vertices
S  = [min(L(:)),max(L(:))];     % min max values

switch method
    case{'Raycast'}
    otherwise
    if write == 2
        r = (nv/length(pos))*5;
        w  = linspace(.1,1,r);          % 
        w  = fliplr(w);                 % 
    elseif write == 3
        r = (nv/length(pos))*3;
        w  = linspace(.1,1,r);          % 
        w  = fliplr(w);                 % 
    end
end

% Get centre point of cortical mesh so we know left/right
cnt = spherefit(mv);
Lft = mv(:,1) < cnt(1);
Rht = mv(:,1) > cnt(1);
Lft = find(Lft);
Rht = find(Rht);

fprintf('Determining closest points between sourcemodel & template vertices\n');
mr = mean(mean(abs(mv)-repmat(spherefit(mv),[size(mv,1),1])));


% Switch which projection method to use:
%--------------------------------------------------------------------------
switch method
    
    case 'Raycast'
        % This is an attempt at employing the ray casting method
        % implemented in mri3dX. It grids the functional data and searches
        % along each face's normal from -1.5 to 1.5 in 0.05 mm steps.
        %
        % The functional overlay vector returned in the overlay substructure 
        % has one value per FACE of the mesh
        
        
        % Ray cast from FACES or from VERTICES: SET 'face' / 'vertex'
        UseFaceVertex = 'face'; 
        RND = 1;
        
        % Grid resolution
        nmesh.vertices = mesh.vertices * .5;
        dv             = v * .5;
                
        % make new mesh and overlay points, decimated / rounded to integers (mm)
        nmesh.vertices = double(round(nmesh.vertices*RND)/RND);
        nmesh.faces    = double(mesh.faces);
        dv             = round(dv*RND)/RND;
           
        % volume the data so vertices are (offset) indices
        fprintf('Gridding data for ray cast\n');
        vol = zeros( (max(dv) - min(dv))+1 );
        ndv = min(dv)-1;
        
        for i = 1:length(dv)
            if L(i) ~= 0
                a(1)  = L(i);
                a(2)  = vol(dv(i,1)-ndv(1),dv(i,2)-ndv(2),dv(i,3)-ndv(3));
                [~,I] = max(abs(a));
                vol(dv(i,1)-ndv(1),dv(i,2)-ndv(2),dv(i,3)-ndv(3)) = a(I);                
            end
        end
                
        % Smooth volume
        fprintf('Volume Smoothing & Rescaling  ');tic        
        vol  = smooth3(vol,'box',3);        
        V    = spm_vec(vol);
        V    = S(1) + (S(2)-S(1)).*(V(:,1) - min(V(:,1)))./(max(V(:,1)) - min(V(:,1)));
        vol  = spm_unvec(V, vol); 
        fprintf('-- done (%d seconds)\n',round(toc)); 
        
        switch UseFaceVertex
            
            case 'face'
                
                % Load or compute FACE normals and centroids
                %----------------------------------------------------------
                if length(mv) == 81924
                    % use precomputed for deault mesh
                    load('DefaultMeshCentroidsNormals','FaceCent','FaceNorm')
                    fprintf('Using precomputed centroids & normals for default mesh\n');
                    f = nmesh.faces;
                else
                    
                    % Compute face normals
                    %------------------------------------------------------
                    fprintf('Computing FACE Normals & Centroids  '); tic;
                    tr = triangulation(nmesh.faces,nmesh.vertices(:,1),...
                                        nmesh.vertices(:,2),nmesh.vertices(:,3));
                    FaceNorm = tr.faceNormal;

                    % Compute triangle centroids
                    %------------------------------------------------------
                    f        = nmesh.faces;
                    for If   = 1:length(f)
                        pnts = [nmesh.vertices(f(If,1),:); nmesh.vertices(f(If,2),:);...
                                        nmesh.vertices(f(If,3),:)];
                        % Triangle centroid
                        FaceCent(If,:) = mean(pnts,1);
                    end
                    
                    fprintf('-- done (%d seconds)\n',round(toc));
                end
                
                step   = -1.5:0.05:1.5;
                fprintf('Using depths: %d to %d mm in increments %d\n',...
                    step(1), step(end), round((step(2)-step(1))*1000)/1000 );
                fcol   = zeros(length(step),length(f));
                
                
            case 'vertex'
                
                % Compute VERTEX normals
                fprintf('Computing VERTEX normals\n');
                FaceNorm = spm_mesh_normals(nmesh,1);
                
                % In this case, centroids are the vertices themselves
                FaceCent = nmesh.vertices;
                
                step    = -1.5:0.05:1.5;
                fcol    = zeros(length(step),length(mv));
        end
    
        % Now search outwards along normal line
        %-----------------------------------------------------------------
        nhits  = 0; tic    ;
        perc   = round(linspace(1,length(step),10));
        for i  = 1:length(step)
            
            % keep count of num hits
            hits{i} = 0;
            
            % print progress
            if ismember(i,perc)
                fprintf('Ray casting: %d%% done\n',(10*find(i==perc)));
            end
            
            % the new points
            these = FaceCent + (step(i)*FaceNorm);
            
            % convert these points to indices of the volume
            these(:,1) = these(:,1) - ndv(1);
            these(:,2) = these(:,2) - ndv(2);
            these(:,3) = these(:,3) - ndv(3);
            these      = round(these*RND)/RND;
            
            % values at volume indices
            for j = 1:length(these)
                try
                    fcol(i,j) = vol(these(j,1),these(j,2),these(j,3));
                    hits{i}   = hits{i} + 1;
                end
            end
        end

        fprintf('Finished in %d sec\n',round(toc));
        
        % Retain largest absolute value for each face (from each depth)
        [~,I] = max(abs(fcol));
        for i = 1:length(I)
            nfcol(i) = fcol(I(i),i);
        end
        fcol = nfcol;
        
        % add the values - either 1 per face or 1 per vertex - to the mesh
        %------------------------------------------------------------------
        switch UseFaceVertex
            case 'face'
                % Set face colour data on mesh, requires setting FaceColor= 'flat'
                
                %set(mesh.h,'FaceVertexCData',fcol(:));
                %mesh.h.FaceColor = 'flat';
                
                % Or calculate vertex maxima from faces and use interp'd
                % vertex colouring
                f  = nmesh.faces;
                ev = mv*0;
                
                % these are the vals at the three corners of each triangle
                ev(f(:,1),1) = fcol;
                ev(f(:,2),2) = fcol;
                ev(f(:,3),3) = fcol;
                y            = max(ev')';
                
                % vertex interpolated colour
                handles.mesh.h.FaceVertexCData = y;
                handles.mesh.h.FaceColor = 'interp';
                
                handles.overlay.vertexcdata = y;
                
            case 'vertex'
                % Set vertex color, using interpolated face colours
                fcol  = spm_mesh_smooth(mesh, fcol(:), 4);
                fcol(isnan(fcol)) = 0;
                fcol  = S(1) + ((S(2)-S(1))).*(fcol - min(fcol))./(max(fcol) - min(fcol));
                set(handles.mesh.h,'FaceVertexCData',fcol(:),'FaceColor','interp');
        end
        
        % Use symmetric colourbar and jet as defaults
        s = max(abs(fcol(:))); caxis([-s s]);
        colormap('jet');
        alpha 1;
        
        % Return the face colours
        handles.overlay.data  = fcol(:);       % the functional vector
        handles.overlay.steps = step;          % the depths at which searched
        handles.overlay.hits  = hits;          % num hits / intersects at each depth
        handles.overlay.cast  = UseFaceVertex; % whether computed for faces or vertices
        handles.overlay.limits = s;
    
    
    case 'Inflated spheres' % this would be better called 'box' in its current form
        
        % This method places a box (boundaries) around a sphere inflated around each
        % vertex point (a 'trap window') by a fixed radius. Mesh points
        % within these bounds are assigned to this vertex
        %
        % The functional overlay vector returned in the overlay
        % substructure contains 1 value per VERTEX and faces colours are
        % interpolated
        %
        
        debugplot = 0;
        
        r  = 7;
        OL = sparse(length(L),nv);      % this will be overlay matrix we average
        w  = linspace(.1,1,r);          % weights for closest points
        w  = fliplr(w);                 % 
        M  = zeros( length(x), nv);     % weights matrix: size(len(mesh),len(AAL))
        
        fprintf('Using inside-spheres search algorithm\n');
        tic
        for i = 1:length(x)
            if any(L(i))      
                newv = [];
                r   = 7;
                res = 20;
                th  = 0:pi/res:2*pi;
                r0  = [th(1:2:end-1) th(end) fliplr(th(1:2:end-1))];  
                
                % make [circle] radius change with z-direction (height)
                r0 = th.*fliplr(th);
                r0 = r0/max(r0);
                r0 = r0*r;
                r0 = r0 ;
                
                % the height at which each circle making the sphere will go
                z0 = linspace(v(i,3)-r,v(i,3)+r,(res*2)+1);

                % this generates the vertices of the sphere
                for zi = 1:length(z0)
                    xunit = r0(zi) * cos(th) + v(i,1);
                    yunit = r0(zi) * sin(th) + v(i,2);
                    zunit = repmat(z0(zi),[1,length(xunit)]);
                    newv  = [newv; [xunit' yunit' zunit']];
                end

                if debugplot
                    hold on;
                    s1 = scatter3(v(i,1),v(i,2),v(i,3),200,'r','filled');
                    s2 = scatter3(newv(:,1),newv(:,2),newv(:,3),150,'b');
                    s2.MarkerEdgeAlpha = 0.1;
                    drawnow;
                end

                % Determine whether this point if left or right hemisphere
                LR     = v(i,1);
                IsLeft = (LR-cnt(1)) < 0;
                
                if IsLeft; lri = Lft;
                else;      lri = Rht;
                end
                
                % Bounding box
                bx = [min(newv); max(newv)];
                inside = ...
                    [mv(lri,1) > bx(1,1) & mv(lri,1) < bx(2,1) &...
                     mv(lri,2) > bx(1,2) & mv(lri,2) < bx(2,2) &...
                     mv(lri,3) > bx(1,3) & mv(lri,3) < bx(2,3) ];
                
                ind = lri(find(inside));
                OL(i,ind) = L(i);
                M (i,ind) = 1;
                indz{i}   = ind;
                w         = 1;
            end
        end
        stime = toc;
        fprintf('Routine took %d seconds\n',stime);

    case 'Euclidean'
        
        % Computes (vectorised) euclidean distance from each vertex to
        % every mesh point. Selects closest n to represent vertex values and 
        % weights by distabnce. n is defined by nmeshpoints / nvertex *1.3
        %
        % The functional overlay vector returned in the overlay
        % substructure contains 1 value per VERTEX and face colours are
        % interpolated
        %
        
        debugplot = 0;
        
        OL = sparse(length(L),nv);      % this will be overlay matrix we average
        r  = (nv/length(pos))*1.3;      % radius - number of closest points on mesh
        r  = max(r,1);                  % catch when the overlay is over specified!
        w  = linspace(.1,1,r);          % weights for closest points
        w  = fliplr(w);                 % 
        M  = zeros( length(x), nv);     % weights matrix: size(len(mesh),len(AAL))

        fprintf('Using euclidean search algorithm\n');
        tic
        for i = 1:length(x)
            
            % Print progress
            if i > 1; fprintf(repmat('\b',[size(str)])); end
            str = sprintf('%d/%d',i,(length(x)));
            fprintf(str);

            % Restrict search to this hemisphere
            LR     = v(i,1);
            IsLeft = (LR-cnt(1)) < 0;
            
            if IsLeft; lri = Lft;
            else;      lri = Rht;
            end

            % Compute euclidean distances
            dist       = cdist(mv(lri,:),v(i,:));
            [junk,ind] = maxpoints(dist,max(r,1),'min');
            ind        = lri(ind);
            OL(i,ind)  = w*L(i);
            M (i,ind)  = w;
            indz(i,:)  = ind;

            if debugplot
                hold on;
                s1 = scatter3(v(i,1),v(i,2),v(i,3),200,'r','filled');
                s2 = scatter3(mv(ind,1),mv(ind,2),mv(ind,3),150,'b','filled');
                drawnow;
            end

        end
        stime = toc;
        fprintf('Routine took %d seconds\n',stime);
end


switch method
    case 'Raycast' 
        % Don't do anything        
    otherwise
        
        fprintf('\n'); clear L;
        if ~interpl
             % mean value of a given vertex
            OL = mean((OL),1);
        else
            for i = 1:size(OL,2)
                % average overlapping voxels
                L(i) = sum( OL(:,i) ) / length(find(OL(:,i))) ;
                NumComp(i) =  length(find(OL(:,i)));
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
        y  = spm_mesh_smooth(mesh, y(:), 4);
        y(isnan(y)) = 0;
        y  = S(1) + ((S(2)-S(1))).*(OL - min(OL))./(max(OL) - min(OL));
        y(isnan(y)) = 0;

        set(handles.mesh.h,'FaceVertexCData',y(:),'FaceColor','interp');
        drawnow;
        shading interp
        % force symmetric caxis bounds
        s = max(abs(y(:))); caxis([-s s]);
        colormap('jet');
        alpha 1;
end

handles.overlay.limits = s;

if colbar
    handles.overlay.cb = InteractiveColorbar;
end
    
end
drawnow;




% --- Executes on button press in pushbutton13.
function pushbutton13_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton13 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Transform ovelray to AAL button

% Select atlas
%------------------------------------------
list = {'aal90' 'aal78' 'aal58'};
opt  = menu('Select atlas:',list);
modl = list{opt};

% Retreive atlas ROI positions
%------------------------------------------
atlas = dotemplate(modl);
rois  = get_roi_centres(atlas.template_sourcemodel.pos,atlas.all_roi_tissueindex);

atlas.template_sourcemodel.pos = rois;
atlas = rmfield(atlas,'all_roi_tissueindex');

% now register the real source model positions to the atlas ROIs
sm.pos = handles.overlay.sourcemodel;
reg    = interp_template(sm,rois);
atlas.M    = reg.M;
NM         = atlas.M;

% rescale so not change amplitudes
m  = max(NM(:));
NM = NM/m;

% apply to overlay
L = handles.overlay.data;

S  = [min(L(:)) max(L(:))];
NL = L(:)'*NM;
L  = S(1) + ((S(2)-S(1))).*(NL - min(NL))./(max(NL) - min(NL));
L(isnan(L))=0;

handles.overlay.data = L;

% Over-write sourcemodel
handles.overlay.sourcemodel = rois;


% Update handles structure
guidata(hObject, handles);


% ATLAS REGISTRATION FUNCTIUONS
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

function [C,verts] = get_roi_centres(pos,all_roi_tissueindex)
% Find centre points of rois
%
%
v   = pos;
roi = all_roi_tissueindex;

i   = unique(roi);
i(find(i==0))=[];

fprintf('Finding centre points of ROIs for labels...');
for j         = 1:length(i)
    vox       = find(roi==i(j));
    verts{j}  = v(vox,:);
    C(j,:)    = spherefit(verts{j});
end
fprintf('  ... done! \n');




% NETWORK FUNCTIONS
%--------------------------------------------------------------------------




% --- Executes on button press in pushbutton15.
function pushbutton15_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton15 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Network sourcemodel matrix
list = evalin('base','whos');
opt  = menu('Select variable (nx3)',{list.name});
list = {list.name};
var  = list{opt};
pos  = evalin('base',var);

% rescale network positions inside boundaries of mesh
% (i thought meshmesh had already done this?)
bounds = [min(handles.mesh.g.vertices); max(handles.mesh.g.vertices)];
offset = 0.99;
for ip = 1:3
    pos(:,ip) = bounds(1,ip) + ((bounds(2,ip)-bounds(1,ip))) .* ...
                (pos(:,ip) - min(pos(:,ip)))./(max(pos(:,ip)) - min(pos(:,ip)));
    pos(:,ip) = pos(:,ip)*offset;
end

% redirect to clseast mesh point (vertex?)
for ip = 1:length(pos)
    [~,this]  = min(cdist(pos(ip,:),handles.mesh.g.vertices));
    pos(ip,:) = handles.mesh.g.vertices(this,:);
end

handles.network.sourcemodel = pos;


% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbutton16.
function pushbutton16_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton16 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Network adjacency matrix
list = evalin('base','whos');
opt  = menu('Select variable (nxn)',{list.name});
list = {list.name};
var  = list{opt};
mat  = evalin('base',var);

if size(mat,1) ~= size(mat,2)
    error('Matrix should be of size n x n');
else
    handles.network.net = mat;
end


% Update handles structure
guidata(hObject, handles);


% --- Executes on button press in pushbutton17.
function pushbutton17_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton17 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Load .edge file
[FileName,PathName,FilterIndex] = uigetfile({'*.edge'},'Select edge or node file');
[edge,node] = rw_edgenode([PathName '/' FileName]);

handles.network.net         = edge;
handles.network.sourcemodel = node(:,1:3);

% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in pushbutton18.
function pushbutton18_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton18 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Transform network to AAL

% Select atlas
%------------------------------------------
list = {'aal90' 'aal78' 'aal58'};
opt  = menu('Select atlas:',list);
modl = list{opt};

% Retreive atlas ROI positions
%------------------------------------------
atlas = dotemplate(modl);
rois  = get_roi_centres(atlas.template_sourcemodel.pos,atlas.all_roi_tissueindex);

atlas.template_sourcemodel.pos = rois;
atlas = rmfield(atlas,'all_roi_tissueindex');

% now register the real source model positions to the atlas ROIs
sm.pos = handles.network.sourcemodel;
reg    = interp_template(sm,rois);
atlas.M    = reg.M;
NM         = atlas.M;

% rescale so not change amplitudes
m  = max(NM(:));
NM = NM/m;

% apply to overlay
A  = handles.network.net;
S  = [min(A(:)) max(A(:))];
NL = NM'*A*NM;
A  = S(1) + ((S(2)-S(1))).*(NL - min(NL(:)))./(max(NL(:)) - min(NL(:)));
A(isnan(A)) = 0;

handles.network.net = A;

% Over-write sourcemodel
handles.network.sourcemodel = rois;


% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in pushbutton19.
function pushbutton19_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton19 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Make network button
hasmesh = isfield(handles,'mesh');
hasnet  = isfield(handles,'network');
netcmap = jet;                            % CHANGE COLORMAP

axes(handles.axes1); hold on;

if hasmesh && hasnet
   
    A   = handles.network.net;
    pos = handles.network.sourcemodel; 
    
    % render network as series of lines
    [node1,node2,strng] = matrix2nodes(A,pos);

    % place both signed absmax value in overlay so that colorbar is symmetrical
    strng2 = [strng; -max(abs(strng)); max(abs(strng))];
    RGB    = makecolbar(strng2,netcmap);
    handles.network.limits = max(abs(strng));
    
    % LineWidth (scaled) for strength
    if any(strng)
        R = [-max(abs(strng)),max(abs(strng))];
        S = ( abs(strng) - R(1) ) + 1e-3;

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

    if ~any(isnan( (S - min(S)) ./ (max(S) - min(S)) ))
        S = 0.1 + (3 - 0) .* (S - min(S)) ./ (max(S) - min(S));
    end

    % Paint edges
    %--------------------------------------------------------------------------
    for i = 1:size(node1,1)
        l0(i)=line([node1(i,1),node2(i,1)],...
            [node1(i,2),node2(i,2)],...
            [node1(i,3),node2(i,3)],...
            'LineWidth',S(i),'Color',[RGB(i,:)]);
    end
    
    handles.network.lines = l0;

    % Set colorbar only if there are valid edges
    %--------------------------------------------------------------------------
    if any(i)
        set(gcf,'DefaultAxesColorOrder',RGB)
        set(gcf,'Colormap',RGB)
            %colormap(jet)
            %colorbar
            drawnow; pause(.5);
            a1  = handles.axes1;
            axb = axes('position', get(a1, 'position'));
            set(axb,'visible','off')
            axes(axb);
            %set(a1,'DefaultAxesColorOrder',RGB)
            set(gcf,'Colormap',RGB)

            if any(any(netcmap ~= 0)); 
                        colormap(netcmap);
            else;       colormap(jet);
            end

            handles.network.cb = colorbar('peer',a1,'South');
    end
    if LimC 
        axes(a1);
        caxis(R);
    end

    handles.mesh.h.FaceAlpha = 0.4;
    drawnow;
    
end


% Update handles structure
guidata(hObject, handles);


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

function RGB = makecolbar(I,netcmap)
% Register colorbar values to our overlay /  T-vector
%

if any(any(netcmap ~= 0))
    Colors = colormap(netcmap);
else
    Colors   = jet;
end

NoColors = length(Colors);

Ireduced = (I-min(I))/(max(I)-min(I))*(NoColors-1)+1;
RGB      = interp1(1:NoColors,Colors,Ireduced);


% OTHER FUNCTIONS
%--------------------------------------------------------------------------



% --- Executes on button press in pushbutton20.
function pushbutton20_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton20 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Clear overlay

try
     handles.mesh.h.FaceColor = [.5 .5 .5];
     handles.mesh.h.FaceAlpha = 0.7;
end


try; handles = rmfield(handles,'overlay'); end


    
% Update handles structure
guidata(hObject, handles);




% --- Executes on button press in pushbutton21.
function pushbutton21_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton21 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Clear NEtwork
try
    delete(handles.network.lines);
end

try
    delete(handles.network.cb);
end

try; handles = rmfield(handles,'network'); end


% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in pushbutton22.
function pushbutton22_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton22 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Save Image
[FileName,PathName,FilterIndex] = uiputfile({'*.png'},'Filename');

%print(handles.axes1,[PathName FileName],'-dpng','-r600');

ax_old = handles.axes1;
f_new  = figure;
ax_new = copyobj(ax_old,f_new);
set(ax_new,'Position','default');
print(f_new,[PathName FileName],'-dpng','-r600');

% Update handles structure
guidata(hObject, handles);



% --- Executes on selection change in popupmenu1.
function popupmenu1_Callback(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns popupmenu1 contents as cell array
%        contents{get(hObject,'Value')} returns selected item from popupmenu1

% HEMISPHERE popup
contents = cellstr(get(hObject,'String'));
option   = contents{get(hObject,'Value')};

handles.mesh.hemisphere = option;


% Update handles structure
guidata(hObject, handles);




% --- Executes during object creation, after setting all properties.
function popupmenu1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to popupmenu1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pushbutton23.
function pushbutton23_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton23 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Quick load: AAL90 overlay

list = evalin('base','whos');
opt  = menu('Select variable (90x1)',{list.name});
list = {list.name};
var  = list{opt};
handles.overlay.data = evalin('base',var);

load('AAL_SOURCEMOD');
handles.overlay.sourcemodel = template_sourcemodel.pos;

if ~isfield(handles.overlay,'method')
    handles.overlay.method = 'Euclidean';
end
    
if isfield(handles,'mesh')
    handles = overlay(handles);
else
    handles.mesh.g = read_nv;
    handles.mesh.h = meshmesh(handles,handles.mesh.g);
    handles        = overlay(handles);
end


% Update handles structure
guidata(hObject, handles);



% --- Executes on button press in pushbutton24.
function pushbutton24_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton24 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% AAL90 Network

list = evalin('base','whos');
opt  = menu('Select variable (90x90)',{list.name});
list = {list.name};
var  = list{opt};
handles.network.net = evalin('base',var);

load('AAL_SOURCEMOD');
handles.network.sourcemodel = template_sourcemodel.pos;

if isfield(handles,'mesh')
    pushbutton19_Callback(hObject, eventdata, handles)
    handles = guidata(hObject);
else
    handles.mesh.g = read_nv;
    handles.mesh.h = meshmesh(handles,handles.mesh.g);
    pushbutton19_Callback(hObject, eventdata, handles)
    handles = guidata(hObject);
end

% Update handles structure
guidata(hObject, handles);


% --- Executes on slider movement.
function slider1_Callback(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% inflate / vertex normals slider
%B = [ get(hObject,'Min') get(hObject,'Max')];
V = get(hObject,'Value');
%V = V/(B(2)-B(1));

vnorm = handles.mesh.vnorm; % precomputed vertex normals
%dpth  = -1.5:0.5:8;
dpth  = -2:.5:8;

i     = dpth(findthenearest( V, dpth ));
this  = handles.mesh.g.vertices + (i*vnorm);
    
set(handles.mesh.h,'Vertices',this);drawnow;

% Update handles structure
guidata(hObject, handles);






% --- Executes during object creation, after setting all properties.
function slider1_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider2_Callback(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% OVERLAY: NEG CBAR
V0   = get(hObject,'Value');

curr = get(handles.overlay.cb,'CLim');

vals = [ -handles.overlay.limits * V0, curr(2)];

set(handles.overlay.cb,'CLim',vals);




% --- Executes during object creation, after setting all properties.
function slider2_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider2 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider3_Callback(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% OVERLAY: POS CBAR
V0 = get(hObject,'Value');

curr = get(handles.overlay.cb,'CLim');

vals = [ curr(1), handles.overlay.limits * V0];

set(handles.overlay.cb,'CLim',vals);


% --- Executes during object creation, after setting all properties.
function slider3_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider3 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider4_Callback(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% NETWORK: NEG BAR
V0   = get(hObject,'Value');

curr = get(handles.network.cb,'Limits');

vals = [ -handles.network.limits * V0, curr(2)];

set(handles.network.cb,'Limits',vals);




% --- Executes during object creation, after setting all properties.
function slider4_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider4 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on slider movement.
function slider5_Callback(hObject, eventdata, handles)
% hObject    handle to slider5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

% NETWORK: POS BAR
V0   = get(hObject,'Value');

curr = get(handles.network.cb,'Limits');

vals = [ curr(1), handles.network.limits * V0];

set(handles.network.cb,'Limits',vals);


% --- Executes during object creation, after setting all properties.
function slider5_CreateFcn(hObject, eventdata, handles)
% hObject    handle to slider5 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end


% --- Executes on button press in pushbutton25.
function pushbutton25_Callback(hObject, eventdata, handles)
% hObject    handle to pushbutton25 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% dump data to workspace!
try Data.mesh    = handles.mesh;    end
try Data.overlay = handles.overlay; end
try Data.network = handles.network; end

assignin('base','Data',Data);





