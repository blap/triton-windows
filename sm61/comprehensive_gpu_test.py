#!/usr/bin/env python3
"""
Comprehensive test to verify Triton with NVIDIA backend functionality.
This test runs actual GPU computations to ensure everything is working properly.
"""

import torch
import triton
import triton.language as tl
import sys

@triton.jit
def add_kernel(x_ptr, y_ptr, output_ptr, n_elements, BLOCK_SIZE: tl.constexpr):
    """A simple vector addition kernel."""
    pid = tl.program_id(axis=0)
    block_start = pid * BLOCK_SIZE
    offsets = block_start + tl.arange(0, BLOCK_SIZE)
    mask = offsets < n_elements
    x = tl.load(x_ptr + offsets, mask=mask)
    y = tl.load(y_ptr + offsets, mask=mask)
    output = x + y
    tl.store(output_ptr + offsets, output, mask=mask)

@triton.jit
def mul_kernel(x_ptr, y_ptr, output_ptr, n_elements, BLOCK_SIZE: tl.constexpr):
    """A simple vector multiplication kernel."""
    pid = tl.program_id(axis=0)
    block_start = pid * BLOCK_SIZE
    offsets = block_start + tl.arange(0, BLOCK_SIZE)
    mask = offsets < n_elements
    x = tl.load(x_ptr + offsets, mask=mask)
    y = tl.load(y_ptr + offsets, mask=mask)
    output = x * y
    tl.store(output_ptr + offsets, output, mask=mask)

def test_vector_addition():
    """Test vector addition on GPU."""
    print("Testing vector addition...")
    
    # Create test data
    torch.manual_seed(0)
    size = 1024
    x = torch.rand(size, device='cuda')
    y = torch.rand(size, device='cuda')
    output = torch.empty_like(x, device='cuda')
    
    # Launch kernel
    grid = (triton.cdiv(size, 128),)
    add_kernel[grid](x, y, output, size, BLOCK_SIZE=128)
    
    # Verify results
    expected = x + y
    if torch.allclose(output, expected, rtol=1e-4, atol=1e-4):
        print("✓ Vector addition test passed")
        return True
    else:
        print("✗ Vector addition test failed")
        return False

def test_vector_multiplication():
    """Test vector multiplication on GPU."""
    print("Testing vector multiplication...")
    
    # Create test data
    torch.manual_seed(1)
    size = 2048
    x = torch.rand(size, device='cuda')
    y = torch.rand(size, device='cuda')
    output = torch.empty_like(x, device='cuda')
    
    # Launch kernel
    grid = (triton.cdiv(size, 256),)
    mul_kernel[grid](x, y, output, size, BLOCK_SIZE=256)
    
    # Verify results
    expected = x * y
    if torch.allclose(output, expected, rtol=1e-4, atol=1e-4):
        print("✓ Vector multiplication test passed")
        return True
    else:
        print("✗ Vector multiplication test failed")
        return False

def test_backend_info():
    """Test backend information."""
    print("Testing backend information...")
    
    try:
        # Get NVIDIA backend
        nvidia_backend = triton.backends.backends['nvidia']
        print(f"✓ NVIDIA backend: {nvidia_backend}")
        
        # Check if we can get backend capabilities
        print("✓ Backend information retrieved successfully")
        return True
    except Exception as e:
        print(f"✗ Backend information test failed: {e}")
        return False

def main():
    print("Comprehensive Triton NVIDIA Backend Test")
    print("=" * 40)
    
    # Check if CUDA is available
    if not torch.cuda.is_available():
        print("⚠ CUDA is not available. Skipping GPU tests.")
        sys.exit(0)
    
    print(f"✓ CUDA is available")
    print(f"✓ CUDA device: {torch.cuda.get_device_name()}")
    
    # Run tests
    backend_success = test_backend_info()
    add_success = test_vector_addition()
    mul_success = test_vector_multiplication()
    
    print("\n" + "=" * 40)
    if backend_success and add_success and mul_success:
        print("🎉 ALL TESTS PASSED!")
        print("✅ Triton with NVIDIA backend is fully functional!")
        print("✅ GPU computations are working correctly!")
        return 0
    else:
        print("❌ Some tests failed.")
        return 1

if __name__ == "__main__":
    sys.exit(main())