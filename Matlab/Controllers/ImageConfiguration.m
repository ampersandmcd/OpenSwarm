% initialize camera
imaqreset;
camera = videoinput('winvideo', 1);
triggerconfig(camera, 'manual');
start(camera);

% display current snapshot of field
raw = getsnapshot(camera);
img = flip(raw, 1);
imshow(img);
title("Click corners of test field in counterclockwise order, beginning from the bottom left");
hold on;
axis on;
axis xy;

% take user input on corners of image
ccwInput = zeros(4,2);
for i = 1:4
   [x, y] = ginput(1);
   scatter(x, y, 25, 'r');
   ccwInput(i, :) = [x, y];
end

% configure fixed points of transformation
bl = [0,0];
br = [size(img, 2), 0];
tr = [size(img, 2), size(img, 1)];
tl = [0, size(img, 1)];
ccwFixed = [bl; br; tr; tl];

% apply transformation
transformation = fitgeotrans(ccwInput, ccwFixed, 'projective');
flat_img = imwarp(img, transformation);

% take user input crop
hold off;
imshow(flat_img);
axis xy;
title("Click and drag rectangle to select field");
bounds = getrect;

% display resulting field image
final_img = imcrop(flat_img, bounds);
imshow(final_img);
axis xy;
title("Preview of Final Image");

