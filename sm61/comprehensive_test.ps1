# Comprehensive Triton Test Script for SM61
# This script will test various aspects of Triton functionality on SM61

Write-Host "Comprehensive Triton Test for SM61 (NVIDIA Pascal)" -ForegroundColor Cyan
Write-Host "=================================================" -ForegroundColor Cyan

# Check environment
Write-Host "1. Environment Check" -ForegroundColor Yellow
$envCheck = python -c "
import torch
import triton
print(f'PyTorch: {torch.__version__}')
print(f'CUDA Available: {torch.cuda.is_available()}')
if torch.cuda.is_available():
    print(f'GPU: {torch.cuda.get_device_name(0)}')
    print(f'Compute Capability: {torch.cuda.get_device_capability(0)}')
print(f'Triton: {triton.__version__}')
"
Write-Host $envCheck -ForegroundColor White

# Test PyTorch CUDA
Write-Host "`n2. PyTorch CUDA Test" -ForegroundColor Yellow
$pytorchTest = python -c "
import torch
try:
    x = torch.randn(100, 100, device='cuda')
    y = torch.randn(100, 100, device='cuda')
    z = torch.mm(x, y)
    print('SUCCESS: PyTorch CUDA is working correctly')
    print(f'Result shape: {z.shape}')
except Exception as e:
    print(f'FAILED: {e}')
"
Write-Host $pytorchTest -ForegroundColor White

# Test simple Triton kernel
Write-Host "`n3. Simple Triton Kernel Test" -ForegroundColor Yellow
$tritonTest = python -c "
import torch
import triton
import triton.language as tl

@triton.jit
def simple_kernel(x_ptr, y_ptr, n_elements, BLOCK_SIZE: tl.constexpr):
    pid = tl.program_id(axis=0)
    block_start = pid * BLOCK_SIZE
    offsets = block_start + tl.arange(0, BLOCK_SIZE)
    mask = offsets < n_elements
    x = tl.load(x_ptr + offsets, mask=mask)
    y = x * 2
    tl.store(y_ptr + offsets, y, mask=mask)

try:
    size = 1024
    x = torch.randn(size, device='cuda')
    y = torch.empty_like(x, device='cuda')
    
    grid = lambda meta: (triton.cdiv(size, meta['BLOCK_SIZE']),)
    simple_kernel[grid](x, y, size, BLOCK_SIZE=128)
    
    expected = x * 2
    is_correct = torch.allclose(y, expected)
    print(f'SUCCESS: Simple Triton kernel executed')
    print(f'Result correct: {is_correct}')
except Exception as e:
    print(f'FAILED: {e}')
"
Write-Host $tritonTest -ForegroundColor White

# Test specific unit tests that might work
Write-Host "`n4. Specific Unit Test Checks" -ForegroundColor Yellow
Write-Host "Checking which test files exist and have tests..." -ForegroundColor Gray

$testFiles = @(
    'test_module.py',
    'test_decorator.py',
    'test_reproducer.py',
    'test_mxfp.py'
)

foreach ($testFile in $testFiles) {
    Write-Host "  Checking $testFile..." -ForegroundColor Gray
    $testCount = python -m pytest python/test/unit/language/$testFile --collect-only -q 2>$null | Select-String -Pattern "tests collected" | ForEach-Object { ($_ -split " ")[0] }
    if ($testCount -and $testCount -ne "0") {
        Write-Host "    Found $testCount tests" -ForegroundColor Green
    } else {
        Write-Host "    No tests found" -ForegroundColor Red
    }
}

Write-Host "`n5. Summary" -ForegroundColor Yellow
Write-Host "Test execution completed." -ForegroundColor Cyan