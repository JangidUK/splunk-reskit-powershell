﻿# Copyright 2011 Splunk, Inc.
#
# Licensed under the Apache License, Version 2.0 (the "License"): you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
# http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.

param( $fixture )

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