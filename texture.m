clear all;

img_name = char('Canvas-Board.jpg','Canvas-Paper.jpg' ,'Fiber.jpg','Japanese-paper.jpg','Newsprint.jpg','Paper-Towel.jpg','pink.jpg','pumice.JPG','rock.JPG','Washi.jpg','Washi-Canvas.jpg','white_honey.jpg');
directory = char('C:\Users\Ilkyu\Desktop\2009002229\3\2\Numerical Methods\texture image\');

N_img = 12;
lookup_size = 32;
scale = 16;
sample_number = 100;
except_bright = 1; % DC 성분을 제외 하는지 마는지.
try_numb = 1; % 비교 대상의 임의 좌표 시도 횟수
print = 1; % 출력 관련.
wrong_count = 0;

img_av(1:scale,1:scale,1:N_img) = 0; % 각 이미지의 FTT를 

img_add = strcat(directory,img_name);
img_add_length = length(img_add);
img_bright(1:N_img) = 0;

figure(1);

for(image_number=1:N_img)
    img = imread(img_add(image_number,1:length(img_add)));
    
    img = rgb2gray(img); % rgb to gray
    
    how_big = size(img);
    col = how_big(1);
    row = how_big(2);
    
    %     imtool(img);
    sum = 0;
    
    for(get_sample=1:sample_number)
        x = round(rand()*(col-lookup_size));
        y = round(rand()*(row-lookup_size));
        
        target(1:lookup_size,1:lookup_size) = 0;
        
        for(i=1:lookup_size)
            for(j=1:lookup_size)
                target(i,j) = img(x+i,y+j);
            end
        end
        
        Y = fft2(target,scale,scale);
        img_bright(image_number) = img_bright(image_number) + Y(1,1);
        if(except_bright)
            Y(1,1)=0;
        end% DC성분이 너무 커서 이 부분을 따로 기록을 해놓고 그래프를
        %출력하기 위함. 그러지 않으면 1,1의 성분이 너무 커서 다른 그래프와
        %차이를 육안으로 확인하기 힘듦.
        %또한 전체적인 밝기를 제외한 패턴을 보기위해서는 이게 더욱 효율적이라고 생각했음.
        
        real_ratio_Y =  (abs(real(Y))/max(max(abs(real(Y)))));
%         real_ratio_Y =  abs(real(Y));
        
        for(i=1:scale)
            for(j=1:scale)
                img_av(i,j,image_number) = img_av(i,j,image_number) + real_ratio_Y(i,j);
            end
        end
        
    end
    
    % k means clustering 을 응용하여 사용 하기 위함.
    img_av(:,:,image_number) = img_av(:,:,image_number) / sample_number;
    img_bright(image_number) = img_bright(image_number) / sample_number;
    
    subplot(3,4,image_number);
    mesh(img_av(1:scale,1:scale,image_number));
    
    if(print) disp(sprintf('complete image #%d',image_number)); end
    clear img;
end

if(print) disp('learning patterns completes.'); end % 학습 완료. 

% 텍스쳐를 확인할 대상을 가져옴.

for(number=1:N_img)
    
    img_add = strcat(directory,'tofind\',num2str(number),'.jpg');
    img_obj = imread(img_add);
    
    img_obj = rgb2gray(img_obj); % 대상 이미지를 그레이 스케일.
    
    obj_size = size(img_obj); % 대상 이미지의 전체 사이즈 측정.
    obj_col = obj_size(1);
    obj_row = obj_size(2);
    
    count = [ ];
    
    for(try_val=1:try_numb) % 오브젝트에서의 임의의 좌표를 추출한다.
        x = round(rand()*(obj_col-lookup_size));
        y = round(rand()*(obj_row-lookup_size));
        
        target(1:lookup_size,1:lookup_size) = 0; %초기화
        
        for(i=1:lookup_size) % 대상 이미지에서 일부를 채취함.
            for(j=1:lookup_size)
                target(i,j) = img_obj(x+i,y+j);
            end
        end
        
        obj_Y = fft2(target,scale,scale); % 대상을 일부를 ftt
        obj_bright = obj_Y(1,1);
        if(except_bright) % 설정에 따라 밝기를 제외함.
            obj_Y(1,1) = 0;
        end
        
        real_ratio_obj_Y =  (abs(real(obj_Y))/max(max(abs(real(obj_Y)))));
%         real_ratio_obj_Y =  abs(real(obj_Y));
        
        %figure(2);
        %mesh(real_ratio_obj_Y);
        
        %disp('extracting data from target completes');
        
        min_flag = 1;
        min_sum = 219219219;
        sum_of_diff = 0;
        
        for(n=1:N_img)
            
            sum_of_diff = 0;
            
            for(i=1:scale)
                for(j=1:scale) % k-means-clustering 을 사용한 새롭게 어느 그룹에 추가되는게 가장 합당한가를 찾는다
                    sum_of_diff = sum_of_diff + (real_ratio_obj_Y(i,j)-img_av(i,j,n))*(real_ratio_obj_Y(i,j)-img_av(i,j,n));
                end
            end
            
            if(min_sum > sum_of_diff) % difference 가 가장 작은 번호를 기록.
                min_flag = n;
                min_sum = sum_of_diff;
            end
            
        end
        count = [count min_flag]; % 현재 좌표에서 가장 적합한 이미지 번호를 저장.
    end
    
    % mode(count) 는 저장된 숫자들중 최빈값을 뱉어준다.
    if(print) disp(sprintf('it seems like %s/%s/%s',img_name(mode(count),1:length(img_name)),img_name(number,1:length(img_name)),(mode(count)==number)*'OK')); end
    
    wrong_count = wrong_count + (mode(count)~=number);
    
end