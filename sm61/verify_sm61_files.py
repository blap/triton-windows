# Verification Script for SM61 Test Files
# This script verifies that all required files have been created in the sm61 folder

import os

def verify_sm61_files():
    """Verify that all required files exist in the sm61 folder"""
    sm61_dir = "sm61"
    
    # List of expected files
    expected_files = [
        "compatibility_report.md",
        "summary_report.md",
        "final_test_report.md",
        "benchmark_script.py",
        "benchmark_results.txt",
        "test_annotations.txt",
        "test_block_pointer.txt",
        "test_compile_errors.txt",
        "test_compile_only.txt",
        "test_conversions.txt",
        "test_core.txt",
        "test_decorator.txt",
        "test_fp_conversion.txt",
        "test_frontend.txt",
        "test_libdevice.txt",
        "test_line_info.txt",
        "test_matmul.txt",
        "test_module.txt",
        "test_mxfp.txt",
        "test_pipeliner.txt",
        "test_random.txt",
        "test_reproducer.txt",
        "test_standard.txt",
        "test_subprocess.txt",
        "test_tensor_descriptor.txt",
        "test_tuple.txt",
        "test_warp_specialization.txt"
    ]
    
    print("Verifying files in sm61 directory...")
    print("=" * 50)
    
    # Check if sm61 directory exists
    if not os.path.exists(sm61_dir):
        print("ERROR: sm61 directory does not exist!")
        return False
    
    # Check each expected file
    missing_files = []
    existing_files = []
    
    for filename in expected_files:
        filepath = os.path.join(sm61_dir, filename)
        if os.path.exists(filepath):
            existing_files.append(filename)
            # Get file size
            size = os.path.getsize(filepath)
            print(f"✓ {filename} ({size} bytes)")
        else:
            missing_files.append(filename)
            print(f"✗ {filename} (MISSING)")
    
    print("=" * 50)
    print(f"Files found: {len(existing_files)}")
    print(f"Files missing: {len(missing_files)}")
    
    if missing_files:
        print("\nMissing files:")
        for filename in missing_files:
            print(f"  - {filename}")
        return False
    else:
        print("\nAll required files are present in the sm61 directory!")
        return True

if __name__ == "__main__":
    success = verify_sm61_files()
    if success:
        print("\nVerification completed successfully!")
    else:
        print("\nVerification failed! Some files are missing.")