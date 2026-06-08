%% =========================================================================
%  TRANSMISSION LINE FAULT DETECTION USING DIGITAL IMAGE PROCESSING
%  Canny Edge Detection + Hough Transform
%  500 Fault Images | Clean Output | One Figure Per Fault Type
%% =========================================================================

clc; clear; close all;

%% =========================================================================
%  FIGURE 1: TITLE SLIDE
%% =========================================================================
figure('Name','Title','Color','k','Position',[0 0 1400 700]);
annotation('textbox',[0 0.55 1 0.35],'String',...
    'TRANSMISSION LINE FAULT DETECTION',...
    'FontSize',36,'FontWeight','bold','Color','yellow',...
    'EdgeColor','none','HorizontalAlignment','center');
annotation('textbox',[0 0.38 1 0.20],'String',...
    'Using Digital Image Processing',...
    'FontSize',22,'Color','white','EdgeColor','none',...
    'HorizontalAlignment','center');
annotation('textbox',[0 0.22 1 0.18],'String',...
    'Canny Edge Detection  |  Hough Transform',...
    'FontSize',18,'Color',[1 0.6 0],'EdgeColor','none',...
    'HorizontalAlignment','center');
annotation('textbox',[0 0.08 1 0.15],'String',...
    '500 Synthetic Fault Images  |  LG | LL | LLG | LLL | LLLG',...
    'FontSize',14,'Color',[0.6 1 0.6],'EdgeColor','none',...
    'HorizontalAlignment','center');

%% =========================================================================
%  SETTINGS
%% =========================================================================
total_images  = 500;
img_h         = 400;
img_w         = 700;

out_root        = 'fault_detection_output';
folder_detected = fullfile(out_root, 'detected_faults');
if ~exist(out_root,        'dir'), mkdir(out_root);        end
if ~exist(folder_detected, 'dir'), mkdir(folder_detected); end

fault_types   = {'LG Fault','LL Fault','LLG Fault','LLL Fault','LLLG Fault'};
fault_colors  = [0.9 0.1 0.1; 1 0.5 0; 0.9 0.7 0; 0.2 0.7 0.2; 0.1 0.3 0.9];
n_fault_types = length(fault_types);

summary_fault   = cell(total_images,1);
summary_fault_k = zeros(total_images,1);
summary_edges   = zeros(total_images,1);
summary_lines_n = zeros(total_images,1);
summary_names   = cell(total_images,1);

fprintf('\n Processing 500 Fault Images...\n\n');

%% =========================================================================
%  GENERATE + PROCESS 500 IMAGES
%% =========================================================================
for idx = 1:total_images

    fault_k        = randi(n_fault_types);
    fault_k_actual = fault_k + 1;
    fault_x        = randi([100, img_w-100]);
    fname          = fault_types{fault_k};

    % Generate base image
    base_img  = draw_transmission_line(img_h, img_w);

    % Inject fault
    fault_img = inject_fault(base_img, fault_k_actual, fault_x, img_h, img_w);

    % Preprocessing
    gray_img = rgb2gray(fault_img);
    resized  = imresize(gray_img, [img_h, img_w]);
    denoised = imgaussfilt(resized, 1.2);
    enhanced = imadjust(denoised);

    % Canny Edge Detection
    edges = edge(im2double(enhanced), 'Canny', [0.08 0.22]);

    % Hough Transform
    [H_hough, theta, rho] = hough(edges);
    peaks = houghpeaks(H_hough, 30, 'Threshold', 0.25*max(H_hough(:)));
    lines = houghlines(edges, theta, rho, peaks, ...
                       'FillGap', 10, 'MinLength', 20);

    n_edges = sum(edges(:));
    n_lines = length(lines);

    % Annotate
    annotated = annotate_image(fault_img, edges, lines, fname, fault_x, img_h);

    % Save
    img_name = sprintf('fault_%04d_%s.png', idx, strrep(fname,' ','_'));
    imwrite(annotated, fullfile(folder_detected, img_name));

    summary_fault{idx}   = fname;
    summary_fault_k(idx) = fault_k;
    summary_edges(idx)   = n_edges;
    summary_lines_n(idx) = n_lines;
    summary_names{idx}   = img_name;

    fprintf('  [%03d/500] %-12s | Edges: %-6d | Lines: %d\n', ...
            idx, fname, n_edges, n_lines);
end

fprintf('\n All 500 images processed and saved!\n\n');

%% =========================================================================
%  FIGURE 2: PREPROCESSING STEPS — ONE SAMPLE
%% =========================================================================
base_img  = draw_transmission_line(img_h, img_w);
fault_img = inject_fault(base_img, 2, 300, img_h, img_w);

gray_img = rgb2gray(fault_img);
resized  = imresize(gray_img, [img_h, img_w]);
denoised = imgaussfilt(resized, 1.2);
enhanced = imadjust(denoised);

figure('Name','Preprocessing Steps','Color','w','Position',[30 30 1400 380]);
sgtitle('PREPROCESSING STEPS — Transmission Line Image',...
        'FontSize',15,'FontWeight','bold','Color',[0.1 0.1 0.5]);

subplot(1,4,1); imshow(fault_img);
title('1. Original (RGB)','FontSize',12,'FontWeight','bold','Color',[0 0 0.6]);

subplot(1,4,2); imshow(gray_img);
title('2. Grayscale Conversion','FontSize',12,'FontWeight','bold','Color',[0 0 0.6]);

subplot(1,4,3); imshow(denoised);
title('3. Noise Removal','FontSize',12,'FontWeight','bold','Color',[0 0 0.6]);

subplot(1,4,4); imshow(enhanced);
title('4. Image Enhancement','FontSize',12,'FontWeight','bold','Color',[0 0 0.6]);

%% =========================================================================
%  FIGURE 3: CANNY EDGE DETECTION — ONE SAMPLE PER FAULT TYPE
%% =========================================================================
figure('Name','Canny Edge Detection','Color','w','Position',[30 30 1400 380]);
sgtitle('CANNY EDGE DETECTION (One Sample Per Fault Type)',...
        'FontSize',15,'FontWeight','bold','Color',[0.1 0.1 0.5]);

for f = 1:n_fault_types
    base_img  = draw_transmission_line(img_h, img_w);
    fault_img = inject_fault(base_img, f+1, 300, img_h, img_w);
    gray_img  = rgb2gray(fault_img);
    enhanced  = imadjust(imgaussfilt(gray_img, 1.2));
    edges     = edge(im2double(enhanced), 'Canny', [0.08 0.22]);
    match_idx = find(summary_fault_k == f, 1);

    subplot(1,5,f);
    imshow(edges);
    title(fault_types{f},'FontSize',11,'FontWeight','bold',...
          'Color', fault_colors(f,:));
    xlabel(sprintf('Edge Pixels: %d', summary_edges(match_idx)),...
           'FontSize',9);
end

%% =========================================================================
%  FIGURE 4: HOUGH TRANSFORM — ONE SAMPLE PER FAULT TYPE
%% =========================================================================
figure('Name','Hough Transform','Color','w','Position',[30 30 1400 380]);
sgtitle('HOUGH TRANSFORM ACCUMULATOR (One Sample Per Fault Type)',...
        'FontSize',15,'FontWeight','bold','Color',[0.1 0.1 0.5]);

for f = 1:n_fault_types
    base_img  = draw_transmission_line(img_h, img_w);
    fault_img = inject_fault(base_img, f+1, 300, img_h, img_w);
    gray_img  = rgb2gray(fault_img);
    enhanced  = imadjust(imgaussfilt(gray_img, 1.2));
    edges     = edge(im2double(enhanced), 'Canny', [0.08 0.22]);
    [H_s, theta_s, rho_s] = hough(edges);

    subplot(1,5,f);
    imagesc(theta_s, rho_s, H_s);
    colormap(gca, hot);
    colorbar;
    title(fault_types{f},'FontSize',11,'FontWeight','bold');
    xlabel('\theta (deg)'); ylabel('\rho (px)');
    axis on; axis normal;
end

%% =========================================================================
%  FIGURES 5-9: ONE FIGURE PER FAULT TYPE — ALL DETECTED IMAGES CLEARLY
%% =========================================================================
fprintf(' Generating fault-wise image figures...\n');

for f = 1:n_fault_types
    matches = find(summary_fault_k == f);
    n_match = length(matches);

    figure('Name', sprintf('Fault Type: %s', fault_types{f}), ...
           'Color','k', 'Position',[0 0 1600 1000]);

    sgtitle(sprintf('FAULT DETECTED — %s  (%d Images)', ...
            fault_types{f}, n_match), ...
            'FontSize',18,'FontWeight','bold','Color',fault_colors(f,:));

    rows = 10;
    cols = ceil(n_match / rows);

    for s = 1:n_match
        idx      = matches(s);
        det_file = fullfile(folder_detected, summary_names{idx});

        subplot(rows, cols, s);
        if exist(det_file, 'file')
            imshow(imread(det_file));
        end
        title(sprintf('#%d', idx), ...
              'FontSize',6,'Color',fault_colors(f,:));
    end

    fprintf('  Figure %d — %s done (%d images)\n', f+4, fault_types{f}, n_match);
end

%% =========================================================================
%  SAVE SUMMARY CSV
%% =========================================================================
fid = fopen(fullfile(out_root,'summary_log.csv'),'w');
fprintf(fid,'Img#,Image_Name,Fault_Type,Edge_Pixels,Hough_Lines\n');
for idx = 1:total_images
    fprintf(fid,'%d,%s,%s,%d,%d\n',...
        idx, summary_names{idx}, summary_fault{idx},...
        summary_edges(idx), summary_lines_n(idx));
end
fclose(fid);

fprintf('\n CSV saved: %s\n', fullfile(out_root,'summary_log.csv'));
fprintf('\n=====================================================\n');
fprintf('  DONE! All figures generated successfully!\n');
fprintf('  Total Figures : 9\n');
fprintf('  Figure 1      : Title Slide\n');
fprintf('  Figure 2      : Preprocessing Steps\n');
fprintf('  Figure 3      : Canny Edge Detection\n');
fprintf('  Figure 4      : Hough Transform\n');
fprintf('  Figure 5      : LG  Fault  — All Detected Images\n');
fprintf('  Figure 6      : LL  Fault  — All Detected Images\n');
fprintf('  Figure 7      : LLG Fault  — All Detected Images\n');
fprintf('  Figure 8      : LLL Fault  — All Detected Images\n');
fprintf('  Figure 9      : LLLG Fault — All Detected Images\n');
fprintf('=====================================================\n\n');


%% =========================================================================
%%  HELPER: Draw Transmission Line
%% =========================================================================
function img = draw_transmission_line(H, W)
    img = ones(H, W, 3);
    for r = 1:H
        sky_val = 0.55 + 0.35*(1 - r/H);
        img(r,:,1) = sky_val * 0.72;
        img(r,:,2) = sky_val * 0.88;
        img(r,:,3) = sky_val * 1.00;
    end
    ground_y = round(H * 0.82);
    for r = ground_y:H
        t_g = (r-ground_y)/(H-ground_y);
        img(r,:,1) = 0.15+0.10*t_g;
        img(r,:,2) = 0.40+0.15*t_g;
        img(r,:,3) = 0.10+0.05*t_g;
    end
    pole_x     = [80,220,370,520,650];
    pole_top_y = round(H*0.18);
    pole_bot_y = ground_y;
    pole_width = 6;
    for p = 1:length(pole_x)
        px = pole_x(p);
        x1 = max(1,px-pole_width);
        x2 = min(W,px+pole_width);
        for r = pole_top_y:pole_bot_y
            img(r,x1:x2,1)=0.28;
            img(r,x1:x2,2)=0.18;
            img(r,x1:x2,3)=0.08;
        end
        arm_y=pole_top_y+15; arm_hw=35;
        ax1=max(1,px-arm_hw); ax2=min(W,px+arm_hw);
        ay1=max(1,arm_y-4);   ay2=min(H,arm_y+4);
        img(ay1:ay2,ax1:ax2,1)=0.28;
        img(ay1:ay2,ax1:ax2,2)=0.18;
        img(ay1:ay2,ax1:ax2,3)=0.08;
    end
    wire_offsets = [-25, 0, 25];
    wire_sag     = 18;
    wire_y_base  = pole_top_y + 22;
    for w = 1:3
        img = draw_wire(img, pole_x, wire_offsets(w), ...
                        wire_y_base, wire_sag, W, H, [0.1 0.1 0.1]);
    end
    img = draw_wire(img, pole_x, 0, pole_top_y, 8, W, H, [0.3 0.3 0.3]);
    img = im2uint8(img);
end

%% =========================================================================
%%  HELPER: Draw Wire
%% =========================================================================
function img = draw_wire(img, pole_x, x_off, y_base, sag, W, H, col)
    for seg = 1:length(pole_x)-1
        x1 = max(1,min(W,pole_x(seg)+x_off));
        x2 = max(1,min(W,pole_x(seg+1)+x_off));
        for xp = x1:x2
            frac = (xp-x1)/(x2-x1);
            yp   = max(1,min(H,round(y_base+sag*4*frac*(1-frac))));
            for dy = -1:1
                yr = max(1,min(H,yp+dy));
                img(yr,xp,1)=col(1);
                img(yr,xp,2)=col(2);
                img(yr,xp,3)=col(3);
            end
        end
    end
end

%% =========================================================================
%%  HELPER: Inject Fault
%% =========================================================================
function img = inject_fault(base_img, fault_type, fault_x, H, W)
    img = base_img;
    if fault_type==1, return; end
    if fault_x==0, fault_x=300; end
    img_d = im2double(img);
    switch fault_type
        case 2
            img_d=draw_arc(img_d,fault_x,90,20,[1 0.1 0.1],H);
            img_d=draw_spark(img_d,fault_x,90,H,W);
        case 3
            img_d=draw_arc(img_d,fault_x,90, 20,[1 0.4 0.1],H);
            img_d=draw_arc(img_d,fault_x,115,20,[1 0.4 0.1],H);
            img_d=draw_spark(img_d,fault_x,102,H,W);
        case 4
            img_d=draw_arc(img_d,fault_x,90, 20,[1 0.6 0.0],H);
            img_d=draw_arc(img_d,fault_x,115,20,[1 0.6 0.0],H);
            img_d=draw_ground_flash(img_d,fault_x,H,W);
        case 5
            img_d=draw_arc(img_d,fault_x,90, 20,[1 0.5 0.0],H);
            img_d=draw_arc(img_d,fault_x,115,20,[1 0.5 0.0],H);
            img_d=draw_arc(img_d,fault_x,65, 20,[1 0.5 0.0],H);
        case 6
            img_d=draw_arc(img_d,fault_x,90, 25,[1 1 0.2],H);
            img_d=draw_arc(img_d,fault_x,115,25,[1 1 0.2],H);
            img_d=draw_arc(img_d,fault_x,65, 25,[1 1 0.2],H);
            img_d=draw_ground_flash(img_d,fault_x,H,W);
            for r=60:160
                for c=max(1,fault_x-50):min(W,fault_x+50)
                    d=sqrt((r-90)^2+(c-fault_x)^2);
                    if d<50
                        glow=0.4*exp(-d/20);
                        img_d(r,c,1)=min(1,img_d(r,c,1)+glow);
                        img_d(r,c,2)=min(1,img_d(r,c,2)+glow*0.8);
                        img_d(r,c,3)=min(1,img_d(r,c,3)+glow*0.3);
                    end
                end
            end
    end
    bx1=max(1,fault_x-60); bx2=min(W,fault_x+60);
    img_d=draw_box(img_d,55,200,bx1,bx2,[1 0 0],H,W);
    img=im2uint8(img_d);
end

%% =========================================================================
%%  HELPER: Draw Arc
%% =========================================================================
function img = draw_arc(img, cx, cy, radius, col, H)
    W=size(img,2);
    for angle=0:2:360
        for r=radius-3:radius+3
            xp=round(cx+r*cosd(angle));
            yp=round(cy+r*sind(angle)*0.4);
            if xp>=1&&xp<=W&&yp>=1&&yp<=H
                img(yp,xp,1)=col(1);
                img(yp,xp,2)=col(2);
                img(yp,xp,3)=col(3);
            end
        end
    end
end

%% =========================================================================
%%  HELPER: Draw Spark
%% =========================================================================
function img = draw_spark(img, cx, wire_y, H, W)
    x=cx; y=wire_y+5; col=[1 0.9 0.0];
    for step=1:20
        dx=randi([-8 8]); dy=randi([3 8]);
        nx=max(1,min(W,x+dx)); ny=max(1,min(H,y+dy));
        n_pts=max(abs(nx-x),abs(ny-y));
        if n_pts==0, n_pts=1; end
        for p=0:n_pts
            xp=max(1,min(W,round(x+(nx-x)*p/n_pts)));
            yp=max(1,min(H,round(y+(ny-y)*p/n_pts)));
            img(yp,xp,1)=col(1); img(yp,xp,2)=col(2); img(yp,xp,3)=col(3);
            if yp+1<=H
                img(yp+1,xp,1)=col(1);
                img(yp+1,xp,2)=col(2);
                img(yp+1,xp,3)=col(3);
            end
        end
        x=nx; y=ny;
        if y>300, break; end
    end
end

%% =========================================================================
%%  HELPER: Draw Ground Flash
%% =========================================================================
function img = draw_ground_flash(img, cx, H, W)
    col=[1 0.85 0.0]; ground_y=round(H*0.82);
    for y=130:ground_y
        xp=max(1,min(W,cx+randi([-5 5])));
        for dx2=-2:2
            xc=max(1,min(W,xp+dx2));
            img(y,xc,1)=col(1); img(y,xc,2)=col(2); img(y,xc,3)=col(3);
        end
    end
end

%% =========================================================================
%%  HELPER: Draw Bounding Box
%% =========================================================================
function img = draw_box(img, r1, r2, c1, c2, col, H, W)
    r1=max(1,r1); r2=min(H,r2); c1=max(1,c1); c2=min(W,c2);
    for t=0:2
        img(max(1,r1+t),c1:c2,1)=col(1); img(max(1,r1+t),c1:c2,2)=col(2); img(max(1,r1+t),c1:c2,3)=col(3);
        img(min(H,r2-t),c1:c2,1)=col(1); img(min(H,r2-t),c1:c2,2)=col(2); img(min(H,r2-t),c1:c2,3)=col(3);
        img(r1:r2,max(1,c1+t),1)=col(1); img(r1:r2,max(1,c1+t),2)=col(2); img(r1:r2,max(1,c1+t),3)=col(3);
        img(r1:r2,min(W,c2-t),1)=col(1); img(r1:r2,min(W,c2-t),2)=col(2); img(r1:r2,min(W,c2-t),3)=col(3);
    end
end

%% =========================================================================
%%  HELPER: Annotate Image
%% =========================================================================
function out = annotate_image(orig_img, edges, lines, fault_name, fault_x, H)
    W     = size(orig_img,2);
    out_d = im2double(orig_img);
    for r = 1:size(edges,1)
        for c = 1:size(edges,2)
            if edges(r,c)
                out_d(r,c,1) = 0;
                out_d(r,c,2) = out_d(r,c,2)*0.4+0.6;
                out_d(r,c,3) = out_d(r,c,3)*0.4+0.6;
            end
        end
    end
    for m = 1:length(lines)
        p1=lines(m).point1; p2=lines(m).point2;
        n_pts=max(abs(p2(1)-p1(1)),abs(p2(2)-p1(2)));
        if n_pts==0, continue; end
        for p=0:n_pts
            xp=max(1,min(W,round(p1(1)+(p2(1)-p1(1))*p/n_pts)));
            yp=max(1,min(H,round(p1(2)+(p2(2)-p1(2))*p/n_pts)));
            for dy=-1:1
                yr=max(1,min(H,yp+dy));
                out_d(yr,xp,1)=0.0;
                out_d(yr,xp,2)=1.0;
                out_d(yr,xp,3)=0.2;
            end
        end
    end
    if fault_x>0
        out_d=draw_box(out_d,55,200,...
                       max(1,fault_x-60),min(W,fault_x+60),...
                       [1 0 0],H,W);
    end
    out=im2uint8(out_d);
    try
        out=insertText(out,[10 10],sprintf('FAULT: %s',fault_name),...
            'FontSize',16,'TextColor','red',...
            'BoxColor','yellow','BoxOpacity',0.7);
        out=insertText(out,[10 40],'STATUS: FAULT DETECTED',...
            'FontSize',14,'TextColor','white',...
            'BoxColor','red','BoxOpacity',0.8);
    catch
    end
end
