# run_sm61_tests.ps1 - Execute Triton Language Unit Tests on SM61 (NVIDIA Pascal)
# This script runs all tests in python/test/unit/language and generates a report

# Ensure sm61 directory exists for storing results
if (!(Test-Path "sm61")) {
    New-Item -ItemType Directory -Path "sm61" | Out-Null
}

Write-Host "Starting Triton Language Unit Tests on SM61 (NVIDIA Pascal)..." -ForegroundColor Cyan
Write-Host "================================================================" -ForegroundColor Cyan

# Check GPU capabilities
Write-Host "Checking GPU capabilities..." -ForegroundColor Yellow
$gpuInfo = python -c "
import torch
if torch.cuda.is_available():
    device_name = torch.cuda.get_device_name(0)
    capability = torch.cuda.get_device_capability(0)
    print(f'GPU: {device_name}')
    print(f'Compute Capability: {capability[0]}.{capability[1]}')
    if capability[0] < 7:
        print('WARNING: This GPU may not support all Triton features')
else:
    print('ERROR: CUDA is not available')
"
Write-Host $gpuInfo -ForegroundColor White

# Set environment variable for SM61
$env:TRITON_TEST_ARCH = "sm61"

# Define test files
$testFiles = @(
    "test_annotations.py",
    "test_block_pointer.py",
    "test_compile_errors.py",
    "test_compile_only.py",
    "test_conversions.py",
    "test_core.py",
    "test_decorator.py",
    "test_fp_conversion.py",
    "test_frontend.py",
    "test_libdevice.py",
    "test_line_info.py",
    "test_matmul.py",
    "test_module.py",
    "test_mxfp.py",
    "test_pipeliner.py",
    "test_random.py",
    "test_reproducer.py",
    "test_standard.py",
    "test_subprocess.py",
    "test_tensor_descriptor.py",
    "test_tuple.py",
    "test_warp_specialization.py"
)

# Initialize results tracking
$results = @()
$passed = 0
$failed = 0
$skipped = 0
$incomplete = 0

# Function to run a single test and capture results
function Run-Test {
    param (
        [string]$testFile
    )
    
    Write-Host "Running $testFile..." -ForegroundColor Yellow
    
    # Run the test and capture output
    $output = python -m pytest "python/test/unit/language/$testFile" -v 2>&1
    $lastLine = $output | Select-Object -Last 1
    
    # Parse results
    $status = "INCOMPLETE"
    $notes = ""
    
    if ($lastLine -match "passed.*skipped") {
        # Format: "=== 84 passed, 12 skipped in 2.15s ==="
        if ($lastLine -match "(\d+) passed.*(\d+) skipped") {
            $passCount = $matches[1]
            $skipCount = $matches[2]
            $status = "PASSED"
            $notes = "$passCount/$($passCount + $skipCount) tests passed, $skipCount skipped"
        }
    }
    elseif ($lastLine -match "passed") {
        # Format: "=== 1 passed in 0.23s ==="
        if ($lastLine -match "(\d+) passed") {
            $passCount = $matches[1]
            $status = "PASSED"
            $notes = "All tests passed"
        }
    }
    elseif ($lastLine -match "failed") {
        # Format: "=== 1 failed in 0.23s ==="
        $status = "FAILED"
        $notes = "Test execution failed"
    }
    elseif ($lastLine -match "skipped") {
        # Format: "=== 1 skipped in 0.23s ==="
        $status = "SKIPPED"
        $notes = "All tests skipped"
    }
    else {
        # Could not parse result
        $status = "INCOMPLETE"
        $notes = "Test execution incomplete or not parsed"
    }
    
    # Save detailed output to file
    $outputPath = "sm61/$($testFile -replace '\.py$', '.txt')"
    $output | Out-File -FilePath $outputPath -Encoding UTF8
    
    # Return result object
    return @{
        TestFile = $testFile
        Status = $status
        Notes = $notes
        OutputFile = $outputPath
    }
}

# Run all tests
foreach ($testFile in $testFiles) {
    try {
        $result = Run-Test -testFile $testFile
        $results += $result
        
        switch ($result.Status) {
            "PASSED" { $passed++ }
            "FAILED" { $failed++ }
            "SKIPPED" { $skipped++ }
            "INCOMPLETE" { $incomplete++ }
        }
        
        Write-Host "  Status: $($result.Status)" -ForegroundColor $(if($result.Status -eq "PASSED") { "Green" } elseif($result.Status -eq "FAILED") { "Red" } else { "Yellow" })
        Write-Host "  Notes: $($result.Notes)" -ForegroundColor Gray
    }
    catch {
        $results += @{
            TestFile = $testFile
            Status = "ERROR"
            Notes = "Script error: $($_.Exception.Message)"
            OutputFile = "sm61/$($testFile -replace '\.py$', '_error.txt')"
        }
        $failed++
        Write-Host "  Status: ERROR" -ForegroundColor Red
        Write-Host "  Notes: Script error occurred" -ForegroundColor Red
    }
    
    Write-Host ""
}

# Generate summary report
$report = @"
# Triton Language Unit Tests Report for SM61 (NVIDIA Pascal)

## Test Execution Environment
- **GPU**: $($gpuInfo.Split("`n")[0].Replace("GPU: ", ""))
- **Compute Capability**: $($gpuInfo.Split("`n")[1].Replace("Compute Capability: ", ""))
- **Operating System**: Windows 10
- **Execution Method**: PowerShell
- **Date**: $(Get-Date)

## Test Results Summary

| Status Indicator | Meaning |
|------------------|---------|
| ✅ PASSED | Test executed successfully |
| ⏭ SKIPPED | Test skipped due to hardware constraints |
| ❌ FAILED | Test failed to execute |
| 🔄 INCOMPLETE | Test partially executed or not executed |

| Test File | Status | Notes |
|-----------|--------|-------|
"@

foreach ($result in $results) {
    $statusIcon = switch ($result.Status) {
        "PASSED" { "✅" }
        "SKIPPED" { "⏭" }
        "FAILED" { "❌" }
        "ERROR" { "❌" }
        default { "🔄" }
    }
    $report += "| $($result.TestFile) | $statusIcon $($result.Status) | $($result.Notes) |`n"
}

$report += @"

## Summary Statistics
- **Total Tests**: $($results.Count)
- **Passed**: $passed
- **Failed**: $failed
- **Skipped**: $skipped
- **Incomplete**: $incomplete

## Notes
- Tests were run on SM61 architecture (NVIDIA Pascal)
- Some tests may be skipped due to hardware limitations
- Detailed output for each test is available in the sm61 directory
"@

# Save report
$report | Out-File -FilePath "sm61/test_report.md" -Encoding UTF8

# Display summary
Write-Host "Test Execution Summary:" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host "Total Tests: $($results.Count)" -ForegroundColor White
Write-Host "Passed: $passed" -ForegroundColor $(if($passed -gt 0) { "Green" } else { "Gray" })
Write-Host "Failed: $failed" -ForegroundColor $(if($failed -gt 0) { "Red" } else { "Gray" })
Write-Host "Skipped: $skipped" -ForegroundColor $(if($skipped -gt 0) { "Yellow" } else { "Gray" })
Write-Host "Incomplete: $incomplete" -ForegroundColor $(if($incomplete -gt 0) { "Yellow" } else { "Gray" })
Write-Host ""
Write-Host "Detailed report saved to sm61/test_report.md" -ForegroundColor Green
Write-Host "Individual test results saved in sm61 directory" -ForegroundColor Green
Write-Host ""
Write-Host "Test execution completed!" -ForegroundColor Green