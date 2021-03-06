function c = leastSquaresFit(A, z, param)
% c = leastSquaresFit(A, z, <param>)
%   Finds the least squares solution for c in A*c = z
%
%   The optional argument param is a struct with the fields
%    gamma - the gamma matrix, as in Tikhonov regularization. This field
%       may optionally be passed as a vector, in which case, it is taken as
%       the diagonalization of that vector. If gamma is empty, it is
%       ignored.
%    weight - the weight matrix as in weighted least squares. If passed as
%       a vector, it is taken as the diagonalization. If weight is empty,
%       it is ignored.
% 
%    When the param argument is passed in, c is calculated as
%        c = inv(A' * W * A + G' * G) * (A' * W * z)
%

if nargin < 1
    c.gamma = [];
    c.weight = [];
    return;
end

if size(A, 1) < size(A, 2)
    warning('leastSquaresFit:toofew', ...
        ['leastSquaresFit: TOO FEW POINTS for least squares!\n'...
        'Have %d, need at least %d'], size(A,1), size(A,2));
% elseif size(A,1) < 1.5 * size(A,2)
%     warning('leastSquareFit:low', ...
%         'leastSquaresFit: Not many extra points. Results will be noisy');
end

if nargin > 2
    if isfield(param, 'gamma')
        gamma = param.gamma;
        if min(size(gamma)) == 1
            gamma = diag(gamma);
        end
    else
        gamma = [];
    end
    
    if isfield(param, 'weight')
        W = param.weight;
    else
        W = 1;
    end
    
    if min(size(W)) == 1
        W = diag(W);
    end    
    
    if isempty(W)
        W = 1;
    end
else
    gamma = [];
    W = 1;
end


%if isempty(W)
%     ATA = A' * A;
%else
ATA = A' * W * A;
%end


if ~isempty(gamma)
    ATA = ATA + gamma' * gamma;
end

[U S V] = svd(ATA);

invS = S;
invS(logical(eye(size(S)))) = 1./invS(logical(eye(size(S))));

ATAInv = U * invS * V';

eyemat = eye(size(ATAInv));
eyetest = ATAInv * ATA;

invErr = rms(eyemat(:) - eyetest(:));

s = warning('off', 'MATLAB:nearlySingularMatrix');
if invErr > 1e-3
    ATAInvTest = eyemat / ATA;
    eyetest = ATAInv * ATA;
    if rms(eyemat(:) - eyetest(:)) < invErr
        ATAInv = ATAInvTest;
    end
end
warning(s.state, 'MATLAB:nearlySingularMatrix');

% if isempty(W)
%     c = (ATAInv * A' * z);
% else   
c = (ATAInv * A' * W * z);
% end
