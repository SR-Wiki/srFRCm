function colors = sjet
% Return the original 256-entry shifted-jet palette without writing LUT files.
colors=zeros(256,3,'uint8');
roll=42;
colors(1:roll,3)=linspace(0,255,roll);
colors(roll+1:2*roll,3)=255;
colors(roll+1:2*roll,1)=linspace(0,255,roll);
colors(2*roll+1:3*roll,1)=255;
colors(2*roll+1:3*roll,3)=linspace(255,0,roll);
colors(3*roll+1:4*roll,1)=255;
colors(3*roll+1:4*roll,2)=linspace(0,255,roll);
colors(4*roll+1:5*roll,2)=255;
colors(4*roll+1:5*roll,1)=linspace(255,0,roll);
colors(5*roll+1:6*roll,2)=255;
colors(5*roll+1:6*roll,1)=linspace(0,255,roll);
colors(5*roll+1:6*roll,3)=linspace(0,255,roll);
colors(6*roll+1:256,:)=255;
colors=double(colors)/255;
end
