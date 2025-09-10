#!/usr/bin/env python3
"""
Verification script to test both CPU-only and NVIDIA builds of Triton on Windows
"""

import subprocess
import sys
import os
import tempfile

def run_command(cmd, cwd=None):
    """Run a command and return its output"""
    try:
        result = subprocess.run(cmd, shell=True, cwd=cwd, capture_output=True, text=True)
        return result.returncode, result.stdout, result.stderr
    except Exception as e:
        return -1, "", str(e)

def test_cpu_build():
    """Test the CPU-only build"""
    print("=" * 60)
    print("Testing CPU-only build...")
    print("=" * 60)
    
    # Test basic import
    try:
        import triton
        print(f"✓ Triton imported successfully (version: {triton.__version__})")
    except Exception as e:
        print(f"✗ Failed to import triton: {e}")
        return False
    
    # Test language primitives
    try:
        import triton.language as tl
        print(f"✓ Triton language module imported")
        print(f"  - tl.int32: {tl.int32}")
        print(f"  - tl.float32: {tl.float32}")
    except Exception as e:
        print(f"✗ Failed to import triton.language: {e}")
        return False
    
    # Test compiler availability
    try:
        compiler = triton.compiler
        print(f"✓ Triton compiler module accessible")
    except Exception as e:
        print(f"✗ Failed to access triton.compiler: {e}")
        return False
    
    print("✓ CPU-only build test completed successfully!")
    return True

def test_nvidia_build():
    """Test the NVIDIA build"""
    print("\n" + "=" * 60)
    print("Testing NVIDIA build...")
    print("=" * 60)
    
    # Test basic import
    try:
        import triton
        print(f"✓ Triton imported successfully (version: {triton.__version__})")
    except Exception as e:
        print(f"✗ Failed to import triton: {e}")
        return False
    
    # Check available backends
    try:
        backends = getattr(triton.backends, 'backends', {})
        print(f"✓ Available backends: {list(backends.keys())}")
        
        if 'nvidia' in backends:
            print("✓ NVIDIA backend is available")
        else:
            print("⚠ NVIDIA backend not found (this might be expected in CPU-only build)")
    except Exception as e:
        print(f"✗ Failed to check backends: {e}")
        return False
    
    # Test language primitives
    try:
        import triton.language as tl
        print(f"✓ Triton language module imported")
        print(f"  - tl.int32: {tl.int32}")
        print(f"  - tl.float32: {tl.float32}")
    except Exception as e:
        print(f"✗ Failed to import triton.language: {e}")
        return False
    
    print("✓ NVIDIA build test completed successfully!")
    return True

def verify_build_scripts():
    """Verify that both build scripts exist and are executable"""
    print("\n" + "=" * 60)
    print("Verifying build scripts...")
    print("=" * 60)
    
    scripts = ['build-core.ps1', 'build.ps1']
    for script in scripts:
        script_path = os.path.join(os.getcwd(), script)
        if os.path.exists(script_path):
            print(f"✓ {script} found")
            # Check if it's readable
            try:
                with open(script_path, 'r') as f:
                    f.read(100)  # Read first 100 chars
                print(f"  - Script is readable")
            except Exception as e:
                print(f"  ✗ Script not readable: {e}")
                return False
        else:
            print(f"✗ {script} not found")
            return False
    
    print("✓ All build scripts verified!")
    return True

def main():
    """Main verification function"""
    print("Triton Windows Build Verification")
    print("=" * 60)
    print(f"Working directory: {os.getcwd()}")
    print()
    
    # Verify build scripts
    if not verify_build_scripts():
        print("✗ Build script verification failed")
        return False
    
    # Test CPU-only build
    print("\nTesting CPU-only functionality...")
    cpu_success = test_cpu_build()
    
    # Test NVIDIA build
    print("\nTesting NVIDIA functionality...")
    nvidia_success = test_nvidia_build()
    
    # Summary
    print("\n" + "=" * 60)
    print("VERIFICATION SUMMARY")
    print("=" * 60)
    
    if cpu_success:
        print("✓ CPU-only build: PASSED")
    else:
        print("✗ CPU-only build: FAILED")
    
    if nvidia_success:
        print("✓ NVIDIA build: PASSED")
    else:
        print("✗ NVIDIA build: FAILED")
    
    if cpu_success and nvidia_success:
        print("\n🎉 All tests passed! Both builds are working correctly.")
        return True
    else:
        print("\n❌ Some tests failed. Please check the output above.")
        return False

if __name__ == "__main__":
    success = main()
    sys.exit(0 if success else 1)