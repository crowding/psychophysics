function grow(N)
    %no allocation: a = zeros(1,N);
    for i = 1:N
        a(i) = rand();
    end
end
