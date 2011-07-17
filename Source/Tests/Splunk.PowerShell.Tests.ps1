﻿param( $fixture )

Get-Command -Module splunk | foreach {
	$script:this = $_;
	$script:commandName = $_.Name;
	
	Describe $script:commandName {		
			
		$commonParameterNames = @"
			Verbose
			Debug
			ErrorAction
			WarningAction
			ErrorVariable
			WarningVariable
			OutVariable
			OutBuffer
			UseTransaction
			Confirm
			Whatif
"@ -split '\s+'; 

		It "has custom help" {
			$script:this | Write-Debug;
			$local:help = ( $script:this | Get-Help -full ) | Out-String;
			
			$local:help -match 'NAME' -and
				$local:help -match 'SYNOPSIS' -and
				$local:help -match 'SYNTAX' -and
				$local:help -match 'DESCRIPTION' -and
				$local:help -match 'EXAMPLE';
		}
			
		$commonParameterNames = @"
			Verbose
			Debug
			ErrorAction
			WarningAction
			ErrorVariable
			WarningVariable
			OutVariable
			OutBuffer
			UseTransaction
			Confirm
			Whatif
"@ -split '\s+'; 

		$script:this | get-help -full | select -exp parameters | select -exp parameter | select -exp Name | where {
			$commonParameterNames -notcontains $_
		} | foreach {	
			It "has documented parameter $_" {
				$paramNames = $script:this | `
					select -exp parameters | `
					select -exp keys;
					
				$paramNames -contains $_;
				
			}
		}

		$script:this | select -exp parameters | select -expand keys | where {
			$commonParameterNames -notcontains $_
		} | foreach {	
			It "has help for parameter $_" {
				$paramNames = $script:this | `
					Get-Help -full | `
					select -exp parameters | `
					select -exp parameter | `
					select -exp name;
					
				$paramNames -contains $_;
				
			}
		}
	}
}