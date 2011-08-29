function It($name, [ScriptBlock] $test, [Type] $expectExceptionOfType) 
{
    $results = Get-GlobalTestResults
    $margin = " " * $results.TestDepth
    $error_margin = $margin * 2
    $results.TestCount += 1

    $output = " $margin$name"

    $start_line_position = $test.StartPosition.StartLine
    $test_file = $test.File

    $exceptionWasCaught = $false
    $expectedExceptionWasCaught = $false

    Setup-TestFunction
    . $TestDrive\temp.ps1

    Start-PesterConsoleTranscript
    try {
        temp
    } 
	catch {
        $exceptionWasCaught = $true

		if($_.GetType() -eq 'PesterFailure') {
			$failure_message = $_.toString() -replace "Exception calling", "Assert failed on"
		}
		else {
            if($expectExceptionOfType -ne $null -and $_.Exception -isnot $expectExceptionOfType)
            {
                $caughtTypeName = $_.Exception.GetType().Name
                $failure_message = "Expected exception of type $expectExceptionOfType but caught $caughtTypeName instead."
                # TODO: We want to include $_.ToString() in the failure message as well, in this case
            }
            else {
    			$failure_message = $_.toString()
            }
		}
		
		if($expectExceptionOfType -ne $null -and $_.Exception -is $expectExceptionOfType) {
            $expectedExceptionWasCaught = $true
		}
		else {
			$temp_line_number =  $_.InvocationInfo.ScriptLineNumber - 2
			$failure_line_number = $start_line_position + $temp_line_number

			$results.FailedTests += $name
			$output | Write-Host -ForegroundColor red

			Write-Host -ForegroundColor red $error_margin$failure_message
			Write-Host -ForegroundColor red $error_margin$error_margin"at line: $failure_line_number in  $test_file"
		}
    }
	finally {
        if(($exceptionWasCaught -eq $false -and $expectExceptionOfType -eq $null) -or ($exceptionWasCaught -and $expectedExceptionWasCaught)) {
        	$output | Write-Host -ForegroundColor green;
        }
        else
        {
            if($exceptionWasCaught -eq $false -and $expectExceptionOfType -ne $null)
            {
			    $output | Write-Host -ForegroundColor red 
                $failure_message = "Expected exception of type $expectExceptionOfType but no exception was thrown."                
    			Write-Host -ForegroundColor red $error_margin$failure_message
            }
        }

		Stop-PesterConsoleTranscript
	}
	if($global:Pester_EnableAutoConsoleText) {
		Get-ConsoleText | Write-Host
	}
}

function Start-PesterConsoleTranscript {
    if (-not (Test-Path $TestDrive\transcripts)) {
        md $TestDrive\transcripts | Out-Null
    }
    Start-Transcript -Path "$TestDrive\transcripts\console.out" | Out-Null
}

function Stop-PesterConsoleTranscript {
    Stop-Transcript | Out-Null
}

function Get-ConsoleText {
    return (Get-Content "$TestDrive\transcripts\console.out")
}

function Setup-TestFunction {
    "function temp {" | out-file $TestDrive\temp.ps1
    $test | out-file -append $TestDrive\temp.ps1
    "}" | out-file -append $TestDrive\temp.ps1
}
