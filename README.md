# MeshAAL
Plot AAL nodes and edges on template brain natively in matlab

```
templatemesh(A);
```

where A is a 90x90 connectivity matrix of the 90 AAL nodes.


![alt text](example.gif)


Also project a 1x90 vector of node values as a mesh overlay.

```
[M,S] = templateoverlay(L) % first call
templateoverlay(L'*M,S)    % second call
```

* L is a vector of length 90 corresponding to the AAL90 atlas
* L is mapped to the size of the template by finding the n-closest points and linearly interpreting to generate a smooth surface
* Returns matrix M of weights, so that it needn't be recomputed.
