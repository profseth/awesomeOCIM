function [A,b,output] = revscav(A,b,do);
%REVSCAV scavenges your element downwards by reversible scavenging
%   This function adds reversible scavenging of your element. It is based
%   on the assumption that your element scavenges equally everywhere in the
%   oceans. That is to say, the equilibrium between particle-adsorbed and
%   free element is set by the same value of K everywhere in the oceans.
%   Mathematically, K can be any number, but conceptually it should be a
%   number between zero (no adsorbed element) and 1 (all of the element is
%   adsorbed. The sinking rate w and the equilibrium scavenging constant K
%   have an exact inverse impact on sinking rate; that is to say that
%   doubling K while halving w will result in the same overall sinking of
%   your element (because twice as much of the element is sinking half as
%   fast). Note that the adsorbed particulate concentration of your element
%   is implicit, but is not explicitly calculated by this function; meaning
%   that this function only concerns itself with the concentration of
%   dissolved species and the movement of dissolved species between grid
%   cells by scavenging, without ever creating an explicit tracer which
%   records the adsorbed concentration of your element. Sedremin determines
%   whether or not adsorbed element which sinks out of the bottom grid cell
%   is released from the sediments back into that grid cell.

fprintf('%s','revscav...')

% load the grid
load ([do.highestpath '/data/ao.mat'])

% unpack the scavenging equilibrium constant (fraction adsorbed from 0 to
% 1), the sinking rate (m/y), and the switch for sedimentary remin
K = do.revscav.K;
w = do.revscav.w;
sedremin = do.revscav.sedremin;

% the amount of element E which sinks out depends on the equilibrium
% scavenging constant, times the sinking rate, divided by the height of the
% grid cell
sinkout = K*w./ao.Height;

% find the equation position (positions in the A matrix) of the grid cells
% which lie below each cell
EQNPOSBELOW = cat(3,ao.EQNPOS(:,:,2:length(ao.depth)),zeros(length(ao.lat),length(ao.lon),1));

% define the equation positions that particles are sinking from, as well as
% the volumes and heights of those grid cells
frompos = ao.EQNPOS(EQNPOSBELOW~=0);
fromvol = ao.Vol(frompos);
fromheight = ao.Height(frompos);

% define the equation positions that particles are sinking to, as well as
% the volumes and heights of those grid cells
topos = EQNPOSBELOW(EQNPOSBELOW~=0);
tovol = ao.Vol(topos);

% create the sinkout A matrix, and fill in the diagonal with the magnitude
% of the sinking flux out
% `spdiags` makes a sparse diagonal
sinkoutA = spdiags(sinkout, 0, ao.nocn, ao.nocn);

% calculate the amount of element transferred into each grid cell by
% sinking with K, the sinking rate divided by the grid cell height from
% which sinking occurs, and a correction for volume
sinkin = sinkout(frompos).*(fromvol./tovol);

% create the A matrix for sinking in
sinkinA = sparse(topos,frompos,sinkin,ao.nocn,ao.nocn);

% find the equation positions of cells which lie on the bottom, and the
% amount of reminerlization there is equal to the amount which sinks out of
% that grid cell
btmeqnpos = ao.EQNPOS(ao.ibtm);
sedreminA = sparse(btmeqnpos,btmeqnpos,sinkout(btmeqnpos),ao.nocn,ao.nocn);

% add the A matrix with the sinking matrices
A = A - sinkoutA + sinkinA;

% add sedimentary remineralization if switched on
if sedremin
    A = A + sedreminA;
end

% package outputs
output.K=K;
output.w=w;
output.sinkoutA=sinkoutA;
output.sinkinA=sinkinA;
if sedremin
    output.sedreminA=sedreminA;
end
output.citations=cell(1,1);
