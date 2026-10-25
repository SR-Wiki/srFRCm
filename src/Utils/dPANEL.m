function varargout = dPANEL(image,varargin)
%DPANEL Compatibility entry for paired srFRC: adjacent stack frames are paired.
% Add src/Utils to the MATLAB path to use this legacy entry point.
[varargout{1:nargout}]=sPANEL(image,'enableSingleFrame',false,varargin{:});
end
