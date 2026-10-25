function row=rolling_row(first,second,y,w,spacing,threshold,params)
block=params.blocksize; skip=params.skip;
row=zeros(skip,w,'single');
    for x=1:skip:w
        a=first(y:y+block-1,x:x+block-1); b=second(y:y+block-1,x:x+block-1);
        centre=block/2:block/2+skip-1;
        if params.boundary && mean(a(centre,centre),'all')/2+mean(b(centre,centre),'all')/2<=threshold/255, continue; end
        if max(a(:))>0, a=a/max(a(:)); end
        if max(b(:))>0, b=b/max(b(:)); end
        factor=1;
        if params.singleFrame
            target=max(128,block); amount=(target-block)/2;
            a=padarray(a,[amount amount],'symmetric'); b=padarray(b,[amount amount],'symmetric');
            factor=sqrt(target/block);
        end
        window=Hanning(size(a,1),size(a,2));
        curve=performFRC(fftshift(fft2(a.*window)),fftshift(fft2(b.*window)),spacing,params.meanFilterWidth,params.threshold);
        if params.singleFrame, values=curve.smoothedFRCCorrected; else, values=curve.smoothedFRC; end
        if strcmp(params.threshold,'1/7')
            cutoff=curve.fixedThreshold;
        else
            cutoff=curve.threeSigma*factor; cutoff(cutoff>1)=1;
        end
        [~,resolution]=get_resolution(curve.frequence,values,cutoff);
        if ~isfinite(resolution) || resolution<=0
            cutoff=5./sqrt(curve.num_pixels/2)*factor; cutoff(cutoff>1)=1;
            [~,resolution]=get_resolution(curve.frequence,values,cutoff);
            resolution=0.6*resolution;
        end
        if ~isfinite(resolution) || resolution<=0
            cutoff=2./sqrt(curve.num_pixels/2)*factor; cutoff(cutoff>1)=1;
            [~,resolution]=get_resolution(curve.frequence,values,cutoff);
            resolution=1.5*resolution;
        end
        if isfinite(resolution) && resolution>0
            row(:,x:min(x+skip-1,w))=resolution;
        end
    end
end
