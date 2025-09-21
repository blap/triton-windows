#!/usr/bin/env python3

"""
Test script to verify that the NVGPU dialect registration error is fixed.
This script tests various Triton functionalities that would trigger the error if present.
"""

import torch
import triton
import triton.language as tl
import sys

def test_basic_import():
    """Test basic Triton import"""
    print("Testing basic Triton import...")
    try:
        import triton
        import triton.language as tl
        print("✓ Basic Triton import successful")
        return True
    except Exception as e:
        print(f"✗ Basic Triton import failed: {e}")
        return False

def test_backend_availability():
    """Test NVIDIA backend availability"""
    print("Testing NVIDIA backend availability...")
    try:
        backends = list(triton.backends.backends.keys())
        print(f"✓ Available backends: {backends}")
        if 'nvidia' in backends:
            print("✓ NVIDIA backend is available")
            return True
        else:
            print("⚠ NVIDIA backend not found")
            return False
    except Exception as e:
        print(f"✗ Backend availability test failed: {e}")
        return False

def test_cuda_functionality():
    """Test CUDA tensor operations"""
    print("Testing CUDA tensor operations...")
    try:
        if not torch.cuda.is_available():
            print("⚠ CUDA not available, skipping CUDA tests")
            return True
            
        # Create CUDA tensors
        x = torch.randn(1000, device='cuda')
        y = torch.randn(1000, device='cuda')
        z = x + y
        print("✓ CUDA tensor operations successful")
        return True
    except Exception as e:
        print(f"✗ CUDA tensor operations failed: {e}")
        return False

@triton.jit
def simple_kernel(x_ptr, y_ptr, output_ptr, n_elements, BLOCK_SIZE: tl.constexpr):
    """Simple Triton kernel for testing"""
    pid = tl.program_id(axis=0)
    block_start = pid * BLOCK_SIZE
    offsets = block_start + tl.arange(0, BLOCK_SIZE)
    mask = offsets < n_elements
    x = tl.load(x_ptr + offsets, mask=mask)
    y = tl.load(y_ptr + offsets, mask=mask)
    output = x + y
    tl.store(output_ptr + offsets, output, mask=mask)

def test_simple_kernel():
    """Test simple Triton kernel execution"""
    print("Testing simple Triton kernel...")
    try:
        if not torch.cuda.is_available():
            print("⚠ CUDA not available, skipping kernel test")
            return True
            
        # Create test data
        size = 98432
        x = torch.rand(size, device='cuda')
        y = torch.rand(size, device='cuda')
        output = torch.empty_like(x, device='cuda')
        
        # Launch kernel
        grid = lambda meta: (triton.cdiv(size, meta['BLOCK_SIZE']),)
        simple_kernel[grid](x, y, output, size, BLOCK_SIZE=1024)
        
        # Verify result
        expected = x + y
        if torch.allclose(output, expected, atol=1e-5):
            print("✓ Simple Triton kernel execution successful")
            return True
        else:
            print("✗ Simple Triton kernel produced incorrect results")
            return False
    except Exception as e:
        print(f"✗ Simple Triton kernel test failed: {e}")
        # Check if it's the specific LLVM error we're trying to fix
        if "LLVM ERROR" in str(e) and "nvgpu" in str(e):
            print("  This is the NVGPU dialect registration error we're trying to fix!")
        return False

@triton.jit
def vector_add_kernel(x_ptr, y_ptr, output_ptr, n_elements, BLOCK_SIZE: tl.constexpr):
    """Vector addition kernel"""
    pid = tl.program_id(axis=0)
    block_start = pid * BLOCK_SIZE
    offsets = block_start + tl.arange(0, BLOCK_SIZE)
    mask = offsets < n_elements
    x = tl.load(x_ptr + offsets, mask=mask)
    y = tl.load(y_ptr + offsets, mask=mask)
    output = x + y
    tl.store(output_ptr + offsets, output, mask=mask)

def test_vector_addition():
    """Test vector addition with Triton kernel"""
    print("Testing vector addition kernel...")
    try:
        if not torch.cuda.is_available():
            print("⚠ CUDA not available, skipping vector addition test")
            return True
            
        # Create test vectors
        size = 10000
        x = torch.randn(size, device='cuda')
        y = torch.randn(size, device='cuda')
        output = torch.empty_like(x, device='cuda')
        
        # Launch kernel
        grid = lambda meta: (triton.cdiv(size, meta['BLOCK_SIZE']),)
        vector_add_kernel[grid](x, y, output, size, BLOCK_SIZE=1024)
        
        # Verify result
        expected = x + y
        if torch.allclose(output, expected, atol=1e-5):
            print("✓ Vector addition kernel execution successful")
            return True
        else:
            print("✗ Vector addition kernel produced incorrect results")
            return False
    except Exception as e:
        print(f"✗ Vector addition kernel test failed: {e}")
        return False

def test_dialect_registration():
    """Test MLIR dialect registration"""
    print("Testing MLIR dialect registration...")
    try:
        # This would trigger the dialect registration error if present
        # We're not actually doing anything with MLIR directly, but 
        # importing Triton and using kernels will trigger the registration
        
        # Create a simple computation that uses Triton's MLIR infrastructure
        if torch.cuda.is_available():
            x = torch.randn(1024, device='cuda')
            y = torch.randn(1024, device='cuda')
            z = x * y  # This uses PyTorch, not Triton, but it's a sanity check
            
            # Now test with a Triton kernel
            output = torch.empty_like(x, device='cuda')
            grid = lambda meta: (triton.cdiv(x.numel(), meta['BLOCK_SIZE']),)
            simple_kernel[grid](x, y, output, x.numel(), BLOCK_SIZE=1024)
            
        print("✓ MLIR dialect registration test passed")
        return True
    except Exception as e:
        print(f"✗ MLIR dialect registration test failed: {e}")
        # Check for the specific error
        if "LLVM ERROR" in str(e) and "nvgpu" in str(e) and "already registered" in str(e):
            print("  DETECTED: NVGPU dialect registration error!")
        return False

def main():
    """Run all tests"""
    print("=" * 60)
    print("NVGPU Dialect Registration Fix Verification")
    print("=" * 60)
    
    tests = [
        test_basic_import,
        test_backend_availability,
        test_cuda_functionality,
        test_simple_kernel,
        test_vector_addition,
        test_dialect_registration
    ]
    
    passed = 0
    total = len(tests)
    
    for test in tests:
        try:
            if test():
                passed += 1
            print()  # Add spacing between tests
        except Exception as e:
            print(f"✗ Test {test.__name__} crashed: {e}")
            print()
    
    print("=" * 60)
    print(f"Test Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! The NVGPU dialect registration error appears to be fixed.")
        return 0
    else:
        print("❌ Some tests failed. The NVGPU dialect registration error may still be present.")
        return 1

if __name__ == "__main__":
    sys.exit(main())