clear ; clc;
% I only cosnider the case that matrix A、B can be just right segmented into tiles
% i.e M/VL、K/VS、N/AD are all integers
%(1) parameters
VS = 64;     % Vector size (K chunk)
VL = 16;     % Vector lanes (tile row)
AD = 16;     % Accumulation depth (tile col)
M  = 128;    % A rows
K  = 64;    % inner dimension
N  = 64;    % B cols

%(2) matrix initialization
% random matrix A、B
A = randi([-8,7], M, K, 'int8');   % A: MxK
B = randi([-8,7], K, N, 'int8');   % B: KxN

%(3) direct computation for C
C_gold = double(A) * double(B);
% make .txt for testbench
writematrix(A, sprintf('A_full_(%dx%d).txt', M, K), 'Delimiter',' ');
writematrix(B, sprintf('B_full_(%dx%d).txt', K, N), 'Delimiter',' ');
writematrix(C_gold, sprintf('C_full_golden_(%dx%d).txt', M, N), 'Delimiter',' ');

%(4) following fig.10: tile computation
tile_row = int32(M / VL);
tile_col = int32(N / AD);
tile_knum = int32(K / VS);
C_tile_reconstructed = zeros(M, N);

for ti = 1:tile_row
    for tj = 1:tile_col
        m0 = (ti-1)*VL + 1;
        n0 = (tj-1)*AD + 1;

        Collector = zeros(VL, AD); 
        for tk = 1:tile_knum
            k0 = (tk-1)*VS + 1;
            A_sub = double(A(m0:m0+VL-1, k0:k0+VS-1));  % (16×64)
            B_sub = double(B(k0:k0+VS-1, n0:n0+AD-1));  % (64×16)
            psum = A_sub * B_sub;                      % (16×16)
            Collector = Collector + psum;              % temporal accumulate
        end
        C_tile(m0:m0+VL-1, n0:n0+AD-1) = Collector;

        tag = sprintf('r%02d_c%02d', ti, tj);
        %writematrix(A(m0:m0+VL-1, 1:VS), sprintf('A_tile_%s.txt', tag), 'Delimiter',' ');
        %writematrix(B(1:VS, n0:n0+AD-1), sprintf('B_tile_%s.txt', tag), 'Delimiter',' ');
        %writematrix(Collector, sprintf('Expected_tile_%s.txt', tag), 'Delimiter',' ');
    end
end

%(5) for verification
diff_all = norm(double(C_tile) - double(C_gold));
if diff_all == 0
    fprintf('✅ 整體 C_tile 與 C_gold 完全一致。\n');
else
    fprintf('⚠️ 差距 = %.6g\n', diff_all);
end

err_cnt = 0;
for ti = 1:tile_row
    for tj = 1:tile_col
        m0 = (ti-1)*VL + 1; n0 = (tj-1)*AD + 1;
        gold_tile = C_gold(m0:m0+VL-1, n0:n0+AD-1);
        calc_tile = C_tile(m0:m0+VL-1, n0:n0+AD-1);
        if any(gold_tile(:) ~= calc_tile(:))
            fprintf('❌ Tile(%d,%d) mismatch\n', ti, tj);
            err_cnt = err_cnt + 1;
        end
    end
end

if err_cnt == 0
    fprintf('✅ 所有 tile 結果皆正確。\n');
else
    fprintf('⚠️ 有 %d 個 tile 不一致。\n', err_cnt);
end