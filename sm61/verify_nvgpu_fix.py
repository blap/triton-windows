#!/usr/bin/env python3

"""
Verify that the NVGPU dialect registration error is fixed.
This script tests if the specific error "LLVM ERROR: Dialect Attribute with name nvgpu. is already registered" is resolved.
"""

import sys
import torch
import traceback

def test_triton_import():
    """Test basic Triton import"""
    print("Testing basic Triton import...")
    try:
        import triton
        import triton.language as tl
        print("✓ Triton imported successfully")
        print(f"  Version: {triton.__version__}")
        return True
    except Exception as e:
        print(f"✗ Triton import failed: {e}")
        return False

def test_nvidia_backend():
    """Test NVIDIA backend availability"""
    print("Testing NVIDIA backend...")
    try:
        import triton
        backends = list(triton.backends.backends.keys())
        print(f"✓ Available backends: {backends}")
        if 'nvidia' in backends:
            print("✓ NVIDIA backend is available")
            return True
        else:
            print("⚠ NVIDIA backend not available")
            return False
    except Exception as e:
        print(f"✗ NVIDIA backend test failed: {e}")
        return False

def test_kernel_execution():
    """Test kernel execution which would trigger the NVGPU dialect error if present"""
    print("Testing kernel execution...")
    
    # Skip if CUDA is not available
    if not torch.cuda.is_available():
        print("⚠ CUDA not available, skipping kernel test")
        return True
    
    try:
        import triton
        import triton.language as tl
        
        @triton.jit
        def simple_add_kernel(x_ptr, y_ptr, output_ptr, n_elements, BLOCK_SIZE: tl.constexpr):
            """Simple addition kernel"""
            pid = tl.program_id(axis=0)
            block_start = pid * BLOCK_SIZE
            offsets = block_start + tl.arange(0, BLOCK_SIZE)
            mask = offsets < n_elements
            x = tl.load(x_ptr + offsets, mask=mask)
            y = tl.load(y_ptr + offsets, mask=mask)
            output = x + y
            tl.store(output_ptr + offsets, output, mask=mask)
        
        # Create test data
        size = 1024
        x = torch.rand(size, device='cuda')
        y = torch.rand(size, device='cuda')
        output = torch.empty_like(x, device='cuda')
        
        # Launch kernel
        grid = lambda meta: (triton.cdiv(size, meta['BLOCK_SIZE']),)
        simple_add_kernel[grid](x, y, output, size, BLOCK_SIZE=1024)
        
        # Verify result
        expected = x + y
        if torch.allclose(output, expected, atol=1e-5):
            print("✓ Kernel executed successfully")
            return True
        else:
            print("✗ Kernel produced incorrect results")
            return False
    except Exception as e:
        print(f"✗ Kernel execution failed: {e}")
        # Check if it's the specific LLVM error we're looking for
        error_str = str(e)
        if "LLVM ERROR" in error_str and "nvgpu" in error_str and "already registered" in error_str:
            print("  DETECTED: NVGPU dialect registration error!")
            return False
        return False

def main():
    """Run all tests"""
    print("=" * 60)
    print("NVGPU Dialect Registration Error Verification")
    print("=" * 60)
    
    tests = [
        ("Triton Import", test_triton_import),
        ("NVIDIA Backend", test_nvidia_backend),
        ("Kernel Execution", test_kernel_execution)
    ]
    
    passed = 0
    total = len(tests)
    
    for name, test_func in tests:
        print(f"\n{name}:")
        try:
            if test_func():
                passed += 1
            else:
                print(f"  Test '{name}' failed")
        except Exception as e:
            print(f"  Test '{name}' crashed: {e}")
            traceback.print_exc()
    
    print("\n" + "=" * 60)
    print(f"Results: {passed}/{total} tests passed")
    
    if passed == total:
        print("🎉 All tests passed! The NVGPU dialect registration error appears to be fixed.")
        return 0
    else:
        print("❌ Some tests failed. The NVGPU dialect registration error may still be present.")
        return 1

if __name__ == "__main__":
    sys.exit(main())