import torch
import triton
import triton.language as tl
import time

# Utility function for benchmarking
def benchmark_func(func, *args, warmup=5, rep=10):
    # Warmup
    for _ in range(warmup):
        func(*args)
    
    # Benchmark
    start_time = time.time()
    for _ in range(rep):
        func(*args)
    end_time = time.time()
    
    return (end_time - start_time) / rep * 1000  # Convert to milliseconds

# Vector Addition Benchmark
@triton.jit
def triton_add(x_ptr, y_ptr, output_ptr, n_elements, BLOCK_SIZE: tl.constexpr):
    pid = tl.program_id(axis=0)
    block_start = pid * BLOCK_SIZE
    offsets = block_start + tl.arange(0, BLOCK_SIZE)
    mask = offsets < n_elements
    x = tl.load(x_ptr + offsets, mask=mask)
    y = tl.load(y_ptr + offsets, mask=mask)
    output = x + y
    tl.store(output_ptr + offsets, output, mask=mask)

# Softmax Benchmark
@triton.jit
def triton_softmax(input_ptr, output_ptr, row_size, BLOCK_SIZE: tl.constexpr):
    row_idx = tl.program_id(0)
    row_start_ptr = input_ptr + row_idx * row_size
    col_offsets = tl.arange(0, BLOCK_SIZE)
    input_ptrs = row_start_ptr + col_offsets
    row = tl.load(input_ptrs, mask=col_offsets < row_size, other=-float('inf'))
    row_minus_max = row - tl.max(row, axis=0)
    numerator = tl.exp(row_minus_max)
    denominator = tl.sum(numerator, axis=0)
    softmax_output = numerator / denominator
    output_row_start_ptr = output_ptr + row_idx * row_size
    output_ptrs = output_row_start_ptr + col_offsets
    tl.store(output_ptrs, softmax_output, mask=col_offsets < row_size)

# Run benchmarks
if __name__ == '__main__':
    device = 'cuda'
    
    # Check if CUDA is available
    if not torch.cuda.is_available():
        print('CUDA is not available. Exiting benchmark.')
        exit(1)
    
    # Vector Addition Benchmark
    print('Vector Addition Benchmark (1M elements)')
    size = 1048576
    x = torch.rand(size, device=device)
    y = torch.rand(size, device=device)
    output_torch = torch.empty_like(x, device=device)
    output_triton = torch.empty_like(x, device=device)
    
    # PyTorch version
    def torch_add_func():
        torch.add(x, y, out=output_torch)
    
    # Triton version
    def launch_triton_add():
        grid = lambda meta: (triton.cdiv(size, meta['BLOCK_SIZE']),)
        triton_add[grid](x, y, output_triton, size, BLOCK_SIZE=1024)
    
    torch_time = benchmark_func(torch_add_func)
    triton_time = benchmark_func(launch_triton_add)
    
    print(f'PyTorch: {torch_time:.2f} ms')
    print(f'Triton: {triton_time:.2f} ms')
    print(f'Speedup: {torch_time/triton_time:.2f}x')
    
    # Softmax Benchmark
    print('\nSoftmax Benchmark (8192x1024)')
    x = torch.randn(8192, 1024, device=device)
    output_torch = torch.empty_like(x, device=device)
    output_triton = torch.empty_like(x, device=device)
    
    # PyTorch version
    def torch_softmax_func():
        torch.softmax(x, dim=-1, out=output_torch)
    
    # Triton version
    def launch_triton_softmax():
        grid = (x.shape[0],)
        triton_softmax[grid](x, output_triton, x.shape[1], BLOCK_SIZE=1024)
    
    torch_time = benchmark_func(torch_softmax_func)
    triton_time = benchmark_func(launch_triton_softmax)
    
    print(f'PyTorch: {torch_time:.2f} ms')
    print(f'Triton: {triton_time:.2f} ms')
    print(f'Speedup: {torch_time/triton_time:.2f}x')
