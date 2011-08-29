function Cleanup() {
	if(-not $global:Pester_TestDriveAllowCleanup) { return }

    if (Test-Path $TestDrive) {
        Remove-Item $TestDrive -Recurse -Force
        Remove-PSDrive -Name TestDrive -Scope Global -Force
    }
}
