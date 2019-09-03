env = Environment();
env = env.StartCamera();
img = env.GetSnapshot();
imshow(img);

disp(env);