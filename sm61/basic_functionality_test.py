#!/usr/bin/env python3

"""
Simple Triton functionality test
"""

import torch
import triton
import triton.language as tl

def test_environment():
    """Test environment setup"""
    print("Environment Check:")
    print(f"  PyTorch version: {torch.__version__}")
    print(f"  CUDA available: {torch.cuda.is_available()}")
    if torch.cuda.is_available():
        print(f"  GPU: {torch.cuda.get_device_name(0)}")
        print(f"  CUDA capability: {torch.cuda.get_device_capability(0)}")
    print(f"  Triton version: {triton.__version__}")
    print()

def test_basic_operations():
    """Test basic operations"""
    print("Testing basic operations...")
    
    # Test PyTorch CUDA
    try:
        x = torch.randn(100, 100, device='cuda')
        y = torch.randn(100, 100, device='cuda')
        z = torch.mm(x, y)
        print("  ✓ PyTorch CUDA working")
    except Exception as e:
        print(f"  ✗ PyTorch CUDA failed: {e}")
        return False
    
    # Test tensor operations
    try:
        a = torch.randn(1000, device='cuda')
        b = torch.randn(1000, device='cuda')
        c = a + b
        print("  ✓ Basic tensor operations working")
    except Exception as e:
        print(f"  ✗ Basic tensor operations failed: {e}")
        return False
    
    return True

def main():
    """Main function"""
    print("Triton SM61 Basic Functionality Test")
    print("=" * 40)
    
    test_environment()
    
    if test_basic_operations():
        print("\n✓ All basic tests passed!")
        print("The environment is properly set up for Triton testing.")
    else:
        print("\n✗ Some tests failed.")
        print("There may be compatibility issues with the current setup.")

if __name__ == "__main__":
    main()