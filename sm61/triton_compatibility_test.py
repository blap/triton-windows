#!/usr/bin/env python3

"""
Simple Triton test script to verify that Triton is working correctly with the updated PyTorch
"""

import torch
import triton
import triton.language as tl
import sys

def check_environment():
    """Check the current environment setup"""
    print("Environment Check:")
    print(f"  PyTorch version: {torch.__version__}")
    print(f"  CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"  GPU: {torch.cuda.get_device_name(0)}")
        print(f"  CUDA capability: {torch.cuda.get_device_capability(0)}")
    print(f"  Triton version: {triton.__version__}")
    print()

@triton.jit
def add_kernel(x_ptr, y_ptr, output_ptr, n_elements, BLOCK_SIZE: tl.constexpr):
    """A simple vector addition kernel"""
    pid = tl.program_id(axis=0)
    block_start = pid * BLOCK_SIZE
    offsets = block_start + tl.arange(0, BLOCK_SIZE)
    mask = offsets < n_elements
    x = tl.load(x_ptr + offsets, mask=mask)
    y = tl.load(y_ptr + offsets, mask=mask)
    output = x + y
    tl.store(output_ptr + offsets, output, mask=mask)

def test_triton_functionality():
    """Test basic Triton functionality"""
    print("Testing Triton functionality...")
    
    # Create test data
    size = 1024
    x = torch.randn(size, device='cuda')
    y = torch.randn(size, device='cuda')
    output = torch.empty_like(x, device='cuda')
    
    # Launch kernel
    try:
        grid = lambda meta: (triton.cdiv(size, meta['BLOCK_SIZE']),)
        add_kernel[grid](x, y, output, size, BLOCK_SIZE=128)
        
        # Verify result
        expected = x + y
        is_correct = torch.allclose(output, expected, rtol=1e-4)
        
        print(f"  Input x: {x[:3]}")
        print(f"  Input y: {y[:3]}")
        print(f"  Output: {output[:3]}")
        print(f"  Expected: {expected[:3]}")
        print(f"  Result correct: {is_correct}")
        
        return is_correct
    except Exception as e:
        print(f"  Error during kernel execution: {e}")
        return False

def test_simple_pytorch():
    """Test that PyTorch CUDA is working"""
    print("Testing PyTorch CUDA functionality...")
    try:
        x = torch.randn(100, 100, device='cuda')
        y = torch.randn(100, 100, device='cuda')
        z = torch.mm(x, y)
        print(f"  PyTorch CUDA test successful. Result shape: {z.shape}")
        return True
    except Exception as e:
        print(f"  PyTorch CUDA test failed: {e}")
        return False

def main():
    """Main function"""
    print("Triton SM61 Compatibility Test")
    print("=" * 40)
    
    # Check environment
    check_environment()
    
    # Test PyTorch CUDA
    pytorch_success = test_simple_pytorch()
    print()
    
    # Test Triton
    triton_success = test_triton_functionality()
    print()
    
    # Summary
    print("Summary:")
    print(f"  PyTorch CUDA: {'PASS' if pytorch_success else 'FAIL'}")
    print(f"  Triton: {'PASS' if triton_success else 'FAIL'}")
    
    if pytorch_success and triton_success:
        print("\nAll tests passed! Triton is working correctly with the updated PyTorch.")
        return 0
    else:
        print("\nSome tests failed. There may be compatibility issues.")
        return 1

if __name__ == "__main__":
    sys.exit(main())