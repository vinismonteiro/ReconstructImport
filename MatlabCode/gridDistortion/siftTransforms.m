function trArray = siftTransforms(files, tr, f, d)
% function trArray = siftTransforms(files, [tr])
% Collects sift-calculated transforms for matches between the files in the
% cell-array passed int
%
% If specified, the transform tr is applied to each image before sift
% analysis.

if isempty(which('vl_sift'))
    error('Please add vl_sift fo the path');
end

if nargin < 2
    tr = [];
end

rparam = ransacRegressionTransform;
rparam.n = 10;
rparam.maxError = 100;
rparam.minInliers = 12;
rparam.maxIter = 1000;


if nargin < 4
    
    f = cell(numel(files));
    d = f;
    
    parfor ii = 1:numel(files)
        fprintf('Reading %s\n', files{ii});
        im = getImage(files{ii}, tr);
        fprintf('Done reading, doing the SIFT on %s\n', files{ii});
        [f{ii} d{ii}] = vl_sift(im);
        fprintf('Done sifting %s\n', files{ii});
    end
    
    save -v7.3 siftcache f d
end

fcurr = f(2:end);
flast = f(1:(end - 1));
dcurr = d(2:end);
dlast = d(1:(end - 1));


% ii = 1;
% trArray(ii) = getSiftTrans(dcurr{ii}, dlast{ii}, fcurr{ii}, ...
%     flast{ii}, rparam, ii);
% 
% trArray = repmat(trArray, [numel(files) - 1, 1]);

trArray = cell(1, numel(files) - 1);

parfor ii = 1:(numel(files) - 1)
    trArray{ii} = getSiftTrans(dcurr{ii}, dlast{ii}, fcurr{ii}, ...
        flast{ii}, rparam, ii);
end



end

function trSift = getSiftTrans(dcurr, dlast, fcurr, flast, rparam, ii)
fprintf('Finding Matches\n');
matches = vl_ubcmatch(dcurr, dlast);
fprintf('Done.\n');

matchLocLast = flast(1:2, matches(2,:))';
matchLocCurr = fcurr(1:2, matches(1,:))';

matchDist = sqrt(sum((matchLocLast - matchLocCurr).^2, 2));

matchDistSort = sort(matchDist);
th = matchDistSort(round(end / 8)); %first octile distance

sel = matchDist < th;

ptsLast = matchLocLast(sel,:);
ptsCurr = matchLocCurr(sel,:);

[trSift trSiftSel] =...
    ransacRegressionTransform(rparam, ptsLast, ptsCurr, 1);

trSift.fromPts = ptsLast;
trSift.toPts = ptsCurr;
trSift.iFrom = ii - 1;
trSift.iTo = ii;
trSift.trSiftSel = trSiftSel;
end

function im = getImage(path, tr)
im = imread(path);
if size(im, 3) > 1
    im = rgb2gray(im);
end

im = im2single(im);

if ~isempty(tr)
    fprintf('Applying transform to %s\n', path);
    im = applyTransformImage(im, tr);
end

end