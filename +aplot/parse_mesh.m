function [mesh,data] = parse_mesh(mesh,i,data)
% Figure out whether we actually want to plot a glass brain mesh, or not

% if only one hemisphere plot
hemi      = i.hemi;
data.hemi = hemi;

% if affine supplied or flip flag
affine = i.affine;
flip   = i.flip;

% if inflate, pass flag
inflate = i.inflate;

% check orientation?
checkori = i.checkori;

% fill holes during hemisphere separation?
dofillholes = i.fillholes;

if     i.pmesh && ~isfield(i,'T')
       [mesh,data.sourcemodel.pos,h,p] = aplot.meshmesh(mesh,i.write,i.fname,i.fighnd,...
           .3,data.sourcemodel.pos,hemi,affine,flip,inflate,checkori,dofillholes);
elseif i.pmesh
       [mesh,data.sourcemodel.pos,h,p] = aplot.meshmesh(mesh,i.write,i.fname,i.fighnd,...
           .3,data.sourcemodel.pos,hemi,affine,flip,inflate,checkori,dofillholes);
else
    h = [];
    p = [];
end

mesh.h = h;
mesh.p = p;
end