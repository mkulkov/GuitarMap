param([int]$TimeoutSeconds = 45)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path $PSScriptRoot -Parent
$godotCli = 'C:\dev\Godot\Godot_console.exe'
# Recovery mode keeps the import/parse gate deterministic when a globally
# configured editor bridge is active; project scripts and resources are still scanned.
$checks = ,@('--recovery-mode', '--editor', '--quit')
$checks += @(Get-ChildItem -LiteralPath $PSScriptRoot -Filter 'run_*_tests.gd' | Sort-Object Name | ForEach-Object { ,@('--script', "res://tests/$($_.Name)") })
$checks += ,@('--quit-after', '90')
foreach ($arguments in $checks) {
    $startInfo = [System.Diagnostics.ProcessStartInfo]::new()
    $startInfo.FileName = $godotCli
    $startInfo.UseShellExecute = $false
    $startInfo.CreateNoWindow = $true
    $startInfo.RedirectStandardOutput = $true
    $startInfo.RedirectStandardError = $true
    foreach ($argument in (@('--headless', '--path', $projectRoot) + $arguments)) {
        $startInfo.ArgumentList.Add($argument)
    }
    $process = [System.Diagnostics.Process]::Start($startInfo)
    $stdout = $process.StandardOutput.ReadToEndAsync()
    $stderr = $process.StandardError.ReadToEndAsync()
    if (-not $process.WaitForExit($TimeoutSeconds * 1000)) {
        $process.Kill($true)
        throw "Godot check timed out: $arguments"
    }
    $output = $stdout.GetAwaiter().GetResult() + $stderr.GetAwaiter().GetResult()
    if ($process.ExitCode -ne 0 -or $output -match '(?m)(SCRIPT ERROR:|ERROR:|Assertion failed|WARNING:)') {
        Write-Output $output
        throw "Godot check failed: $arguments (exit $($process.ExitCode))"
    }
    Write-Output "PASS: $arguments"
}
