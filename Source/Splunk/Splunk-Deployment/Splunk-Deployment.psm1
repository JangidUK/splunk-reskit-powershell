# Copyright 2011 Splunk, Inc.
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

#region Deployment

#region Get-SplunkServerClass

function Get-SplunkServerClass
{
	<# .ExternalHelp ../Splunk-Help.xml #>

	[Cmdletbinding(DefaultParameterSetName="byFilter")]
    Param(
	    
        [Parameter(Position=0,ParameterSetName="byFilter")]
        [STRING]$Filter = '.*',
	    
        [Alias('Name')]
		[Parameter(Position=0,ParameterSetName="byName")]
		[STRING]$ServerClass,
       
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [String]$ComputerName = ( get-splunkconnectionobject ).ComputerName,
        
        [Parameter()]
        [int]$Port            = ( get-splunkconnectionobject ).Port,
        
        [Parameter()]
		[ValidateSet("http", "https")]
        [STRING]$Protocol     = ( get-splunkconnectionobject ).Protocol,
        
        [Parameter()]
        [int]$Timeout         = ( get-splunkconnectionobject ).Timeout,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential = ( get-splunkconnectionobject ).Credential
        
    )
	
	Begin
	{
		Write-Verbose " [Get-SplunkServerClass] :: Starting..."
        
        $ParamSetName = $pscmdlet.ParameterSetName
        switch ($ParamSetName)
        {
            "byFilter"  { $WhereFilter = { $_.ServerClass -match $Filter } } 
            "byName"    { $WhereFilter = { $_.ServerClass -ceq   $ServerClass } }
        }
        
	}
	Process
	{
		Write-Verbose " [Get-SplunkServerClass] :: Parameters"
        Write-Verbose " [Get-SplunkServerClass] ::  - ParameterSet = $ParamSetName"
		Write-Verbose " [Get-SplunkServerClass] ::  - ComputerName = $ComputerName"
		Write-Verbose " [Get-SplunkServerClass] ::  - Port         = $Port"
		Write-Verbose " [Get-SplunkServerClass] ::  - Protocol     = $Protocol"
		Write-Verbose " [Get-SplunkServerClass] ::  - Timeout      = $Timeout"
		Write-Verbose " [Get-SplunkServerClass] ::  - Credential   = $Credential"
        Write-Verbose " [Get-SplunkServerClass] ::  - WhereFilter  = $WhereFilter"
		Write-Verbose " [Get-SplunkServerClass] ::  - Filter  	   = $Filter"
		Write-Verbose " [Get-SplunkServerClass] ::  - ServerClass  = $ServerClass"

		Write-Verbose " [Get-SplunkServerClass] :: Setting up Invoke-APIRequest parameters"
		$InvokeAPIParams = @{
			ComputerName = $ComputerName
			Port         = $Port
			Protocol     = $Protocol
			Timeout      = $Timeout
			Credential   = $Credential
			Endpoint     = '/services/deployment/serverclass' 
			Verbose      = $VerbosePreference -eq "Continue"
		}
			
		Write-Verbose " [Get-SplunkServerClass] :: Calling Invoke-SplunkAPIRequest @InvokeAPIParams"
		try
		{
			[XML]$Results = Invoke-SplunkAPIRequest @InvokeAPIParams
        }
		catch
		{
			Write-Verbose " [Get-SplunkServerClass] :: Invoke-SplunkAPIRequest threw an exception: $_"
            Write-Error $_
		}
        try
        {
			if($Results -and ($Results -is [System.Xml.XmlDocument]))
			{
				Write-Verbose " [Get-SplunkServerClass] :: Creating Hash Table to be used to create Splunk.SDK.Deployment.ServerClass"
				$Results.outerxml | clip;
                foreach($Entry in $Results.feed.entry)
                {
				    $MyObj = @{
                        ComputerName                = $ComputerName
                        ServerClass                 = $Entry.Title
                        ServiceEndpoint             = $Entry.link | ?{$_.rel -eq "edit"} | select -ExpandProperty href
                        FilterType                  = $null
                        Blacklist                   = $null
                        RestartSplunkd              = $null
                        ContinueMatching            = $null
                        MachineTypes                = $null
                        RepositoryLocation          = $null
                        RestartSplunkWeb            = $null
                        Whitelist                   = $null
                        Disabled                    = $null
                        TmpFolder                   = $null
                        StateOnClient               = $null
                        TargetRepositoryLocation    = $null
                        Endpoint                    = $null
                    }
    				
    				switch ($Entry.content.dict.key)
    				{
                        { $_.name -eq "filterType" }                { $Myobj.FilterType               = $_.'#text' ; continue }
                        { $_.name -eq "blacklist" }                 { $Myobj.Blacklist                = $_.'#text' ; continue }
                        { $_.name -eq "restartSplunkd" }            { $Myobj.RestartSplunkd           = [bool]([int]$_.'#text') ; continue }
                        { $_.name -eq "continueMatching" }          { $Myobj.ContinueMatching         = [bool]([int]$_.'#text') ; continue }
                        { $_.name -eq "machineTypes" }              { $Myobj.MachineTypes             = $_.'#text' ; continue }
                        { $_.name -eq "repositoryLocation" }        { $Myobj.RepositoryLocation       = $_.'#text' ; continue }
                        { $_.name -eq "restartSplunkWeb" }          { $Myobj.RestartSplunkWeb         = [bool]([int]$_.'#text') ; continue }
                        { $_.name -eq "whitelist" }                 { $Myobj.Whitelist                = $_.'#text' ; continue }
                        { $_.name -eq "disabled" }                  { $Myobj.Disabled                 = [bool]([int]$_.'#text') ; continue }
                        { $_.name -eq "tmpFolder" }                 { $Myobj.TmpFolder                = $_.'#text' ; continue }
                        { $_.name -eq "stateOnClient" }             { $Myobj.StateOnClient            = $_.'#text' ; continue }
                        { $_.name -eq "targetRepositoryLocation" }  { $Myobj.TargetRepositoryLocation = $_.'#text' ; continue }
                        { $_.name -eq "endpoint" }                  { $Myobj.Endpoint                 = $_.'#text' ; continue }
    		        	Default		                                { $Myobj.Add($_.Name,$_.'#text')               ; continue }
    				}
    				
					# Creating Splunk.SDK.ServiceStatus
    			    $obj = New-Object PSObject -Property $MyObj
    			    $obj.PSTypeNames.Clear()
    			    $obj.PSTypeNames.Add('Splunk.SDK.Deployment.ServerClass')
    			    $obj | Where $WhereFilter					
                }
			}
			else
			{
				Write-Verbose " [Get-SplunkServerClass] :: No Response from REST API. Check for Errors from Invoke-SplunkAPIRequest"
			}
		}
		catch
		{
			Write-Verbose " [Get-SplunkServerClass] :: Get-SplunkServerClass threw an exception: $_"
            Write-Error $_
		}
	}
	End
	{
		Write-Verbose " [Get-SplunkServerClass] :: =========    End   ========="
	}
} # Get-SplunkServerClass

#endregion Get-SplunkServerClass

#region Set-SplunkServerClass

function Set-SplunkServerClass
{
	<# .ExternalHelp ../Splunk-Help.xml #>
	[Cmdletbinding(SupportsShouldProcess=$true)]
    Param(
	    
        [Alias('Name')]
		[Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true,Mandatory=$True)]
		[STRING]$ServerClass,
        
        [Parameter()]
        [STRING[]]$Blacklist,
        
        [Parameter()]
        [STRING[]]$Whitelist,
        
        [Parameter()]
        [ValidateSet( "true","false" )]
        [STRING]$ContinueMatching,
        
        [Parameter()]
        [STRING]$Endpoint,
        
        [Parameter()]
		[ValidateSet( "whitelist","blacklist" )]
        [STRING]$FilterType,
        
        [Parameter()]
        [STRING]$RepositoryLocation,
        
        [Parameter()]
        [STRING]$TargetRepositoryLocation,
        
        [Parameter()]
        [STRING]$TmpFolder,
       
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [String]$ComputerName = ( get-splunkconnectionobject ).ComputerName,
        
        [Parameter()]
        [int]$Port            = ( get-splunkconnectionobject ).Port,
        
        [Parameter()]
		[ValidateSet("http", "https")]
        [STRING]$Protocol     = ( get-splunkconnectionobject ).Protocol,
        
        [Parameter()]
        [int]$Timeout         = ( get-splunkconnectionobject ).Timeout,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = ( get-splunkconnectionobject ).Credential
        
    )
	
	Begin
	{
		Write-Verbose " [Set-SplunkServerClass] :: Starting..."
        
	}
	Process
	{
        
		Write-Verbose " [Set-SplunkServerClass] :: Parameters"
        Write-Verbose " [Set-SplunkServerClass] ::  - ParameterSet = $ParamSetName"
		Write-Verbose " [Set-SplunkServerClass] ::  - ComputerName = $ComputerName"
		Write-Verbose " [Set-SplunkServerClass] ::  - Port         = $Port"
		Write-Verbose " [Set-SplunkServerClass] ::  - Protocol     = $Protocol"
		Write-Verbose " [Set-SplunkServerClass] ::  - Timeout      = $Timeout"
		Write-Verbose " [Set-SplunkServerClass] ::  - Credential   = $Credential"
        Write-Verbose " [Set-SplunkServerClass] ::  - WhereFilter  = $WhereFilter"
		Write-Verbose " [Set-SplunkServerClass] ::  - Filter  	   = $Filter"
		Write-Verbose " [Set-SplunkServerClass] ::  - ServerClass  = $ServerClass"
       
        
        Write-Verbose " [Set-SplunkServerClass] :: checking if ServerClass is from Pipeline"
        if($ServerClass.PSTypeNames -contains "Splunk.SDK.Deployment.ServerClass")
        {
            $MyServerClass = $ServerClass
        }
        else
		{
            $InvokeAPIParams = @{
            			ComputerName = $ComputerName
            			Port         = $Port
            			Protocol     = $Protocol
            			Timeout      = $Timeout
            			Credential   = $Credential
                        ServerClass  = $ServerClass
            }
			$MyServerClass = Get-SplunkServerClass @InvokeAPIParams

		}

        Write-Verbose " [Set-SplunkServerClass] ::  - Endpoint    = $($MyServerClass.ServiceEndpoint)"
		Write-Verbose " [Set-SplunkServerClass] :: Setting up Invoke-APIRequest parameters"
		$InvokeAPIParams = @{
			ComputerName = $ComputerName
			Port         = $Port
			Protocol     = $Protocol
			Timeout      = $Timeout
			Credential   = $Credential
			Endpoint     = $MyServerClass.ServiceEndpoint 
			Verbose      = $VerbosePreference -eq "Continue"
		}
        
        $MyArgs = @{}
        
        if($Blacklist)
        {
			$FilterType = 'blacklist'
            $i = 0
            foreach($Entry in $Blacklist)
            {
                Write-Verbose " [Set-SplunkServerClass] :: Adding blacklist entry [$Entry] to `$MyArgs"
                $MyArgs.Add("blacklist.${i}",$Entry)
                $i++
            }   
        }
        
        if($Whitelist)
        {
		$FilterType = 'whitelist'
            $i = 0
            foreach($Entry in $Whitelist)
            {
                Write-Verbose " [Set-SplunkServerClass] :: Adding whitelist entry [$Entry] to `$MyArgs"
                $MyArgs.Add("whitelist.${i}",$Entry)
                $i++
            }
        }
        
        if($ContinueMatching)
        {
            Write-Verbose " [Set-SplunkServerClass] :: Adding ContinueMatching [$ContinueMatching] to `$MyArgs"
            $MyArgs.Add("continueMatching",$ContinueMatching)
        }
        
        if($Endpoint)
        {
            Write-Verbose " [Set-SplunkServerClass] :: Adding Endpoint [$Endpoint] to `$MyArgs"
            $MyArgs.Add("endpoint",$Endpoint)
        }
        
        if($FilterType)
        {
            Write-Verbose " [Set-SplunkServerClass] :: Adding FilterType [$FilterType] to `$MyArgs"
            $MyArgs.Add("filterType",$FilterType)
        }
        
        if($RepositoryLocation)
        {
            Write-Verbose " [Set-SplunkServerClass] :: Adding RepositoryLocation [$RepositoryLocation] to `$MyArgs"
            $MyArgs.Add("repositoryLocation",$RepositoryLocation)
        }
        
        if($TargetRepositoryLocation)
        {
            Write-Verbose " [Set-SplunkServerClass] :: Adding TargetRepositoryLocation [$TargetRepositoryLocation] to `$MyArgs"
            $MyArgs.Add("targetRepositoryLocation",$TargetRepositoryLocation)
        }
        
        if($TmpFolder)
        {
            Write-Verbose " [Set-SplunkServerClass] :: Adding TmpFolder [$TmpFolder] to `$MyArgs"
            $MyArgs.Add("tmpFolder",$TmpFolder)
        }
			
		Write-Verbose " [Set-SplunkServerClass] :: Calling Invoke-SplunkAPIRequest @InvokeAPIParams"
		try
		{
            if($PSCmdlet.ShouldProcess($ComputerName,"Setting new server class $($MyServerClass.ServerClass)"))
    		{
			    [XML]$Results = Invoke-SplunkAPIRequest @InvokeAPIParams -Arguments $MyArgs -RequestType POST 
            }
        }
		catch
		{
			Write-Verbose " [Set-SplunkServerClass] :: Invoke-SplunkAPIRequest threw an exception: $_"
            Write-Error $_
		}
        try
        {
			Write-Verbose " [Set-SplunkServerClass] :: Checking for valid results"
			if($Results -and ($Results -is [System.Xml.XmlDocument]))
			{
				Write-Verbose " [Set-SplunkServerClass] :: Fetching server class $ServerClass"
                $InvokeAPIParams = @{
        			ComputerName = $ComputerName
        			Port         = $Port
        			Protocol     = $Protocol
        			Timeout      = $Timeout
        			Credential   = $Credential
                    ServerClass  = $MyServerClass.ServerClass
                }
                Get-SplunkServerClass @InvokeAPIParams
			}
			else
			{
				Write-Verbose " [Set-SplunkServerClass] :: No Response from REST API. Check for Errors from Invoke-SplunkAPIRequest"
			}
		}
		catch
		{
			Write-Verbose " [Set-SplunkServerClass] :: Get-SplunkServerClass threw an exception: $_"
            Write-Error $_
		}
	}
	End
	{
		Write-Verbose " [Set-SplunkServerClass] :: =========    End   ========="
	}
} # Set-SplunkServerClass

#endregion Set-SplunkServerClass

#region New-SplunkServerClass

function New-SplunkServerClass
{
	<# .ExternalHelp ../Splunk-Help.xml #>
	[Cmdletbinding(SupportsShouldProcess=$true)]
    Param(
	    
        [Alias('Name')]
		[Parameter(Mandatory=$True)]
		[STRING]$ServerClass,
        
        [Parameter()]
        [STRING[]]$Blacklist,
        
        [Parameter()]
        [STRING[]]$Whitelist,
        
        [Parameter()]
        [SWITCH]$ContinueMatching,
        
        [Parameter()]
        [STRING]$Endpoint,
        
        [Parameter()]
		[ValidateSet( "whitelist","blacklist" )]
        [STRING]$FilterType,
        
        [Parameter()]
        [STRING]$RepositoryLocation,
        
        [Parameter()]
        [STRING]$TargetRepositoryLocation,
        
        [Parameter()]
        [STRING]$TmpFolder,
       
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [String]$ComputerName = ( get-splunkconnectionobject ).ComputerName,
        
        [Parameter()]
        [int]$Port            = ( get-splunkconnectionobject ).Port,
        
        [Parameter()]
		[ValidateSet("http", "https")]
        [STRING]$Protocol     = ( get-splunkconnectionobject ).Protocol,
        
        [Parameter()]
        [int]$Timeout         = ( get-splunkconnectionobject ).Timeout,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential = ( get-splunkconnectionobject ).Credential
        
    )
	
	Begin
	{
		Write-Verbose " [New-SplunkServerClass] :: Starting..."
        
	}
	Process
	{
    
        
		Write-Verbose " [New-SplunkServerClass] :: Parameters"
        Write-Verbose " [New-SplunkServerClass] ::  - ParameterSet = $ParamSetName"
		Write-Verbose " [New-SplunkServerClass] ::  - ComputerName = $ComputerName"
		Write-Verbose " [New-SplunkServerClass] ::  - Port         = $Port"
		Write-Verbose " [New-SplunkServerClass] ::  - Protocol     = $Protocol"
		Write-Verbose " [New-SplunkServerClass] ::  - Timeout      = $Timeout"
		Write-Verbose " [New-SplunkServerClass] ::  - Credential   = $Credential"
        Write-Verbose " [New-SplunkServerClass] ::  - WhereFilter  = $WhereFilter"
		Write-Verbose " [New-SplunkServerClass] ::  - Filter  	   = $Filter"
		Write-Verbose " [New-SplunkServerClass] ::  - ServerClass  = $ServerClass"
        
		if( -not $pscmdlet.ShouldProcess( $ComputerName, "Creating new Splunk server class $ServerClass of type $FilterType" ) )
		{
			return;
		}
        
        Write-Verbose " [New-SplunkServerClass] :: checking for existance of server class"
        $InvokeAPIParams = @{
        			ComputerName = $ComputerName
        			Port         = $Port
        			Protocol     = $Protocol
        			Timeout      = $Timeout
        			Credential   = $Credential
                    ServerClass  = $ServerClass
                }
        $MyServerClass = Get-SplunkServerClass @InvokeAPIParams
        
        if($MyServerClass)
        {
            Write-Host " [New-SplunkServerClass] :: Server Class [$ServerClass] already exist: [ $($MyServerClass.ServiceEndpoint) ]"
            Return
        }

		Write-Verbose " [New-SplunkServerClass] :: Setting up Invoke-APIRequest parameters"
		$InvokeAPIParams = @{
			ComputerName = $ComputerName
			Port         = $Port
			Protocol     = $Protocol
			Timeout      = $Timeout
			Credential   = $Credential
			Endpoint     = '/services/deployment/serverclass' 
			Verbose      = $VerbosePreference -eq "Continue"
		}
        
        $MyArgs = @{}
        
        Write-Verbose " [New-SplunkServerClass] :: Adding Name [$ServerClass] to `$MyArgs"
        $MyArgs.Add("name",$ServerClass)
        
        if($Blacklist)
        {
			$FilterType = 'blacklist'
            $i = 0
            foreach($Entry in $Blacklist)
            {
                Write-Verbose " [New-SplunkServerClass] :: Adding blacklist entry [$Entry] to `$MyArgs"
                $MyArgs.Add("blacklist.${i}",$Entry)
                $i++
            }   
        }
        
        if($Whitelist)
        {
		$FilterType = 'whitelist'
            $i = 0
            foreach($Entry in $Whitelist)
            {
                Write-Verbose " [New-SplunkServerClass] :: Adding whitelist entry [$Entry] to `$MyArgs"
                $MyArgs.Add("whitelist.${i}",$Entry)
                $i++
            }
        }
        
        if($ContinueMatching)
        {
            Write-Verbose " [New-SplunkServerClass] :: Adding ContinueMatching [$ContinueMatching] to `$MyArgs"
            $MyArgs.Add("continueMatching",$True)
        }
        
        if($Endpoint)
        {
            Write-Verbose " [New-SplunkServerClass] :: Adding Endpoint [$Endpoint] to `$MyArgs"
            $MyArgs.Add("endpoint",$Endpoint)
        }
        
        if($FilterType)
        {
            Write-Verbose " [New-SplunkServerClass] :: Adding FilterType [$FilterType] to `$MyArgs"
            $MyArgs.Add("filterType",$FilterType)
        }
        
        if($RepositoryLocation)
        {
            Write-Verbose " [New-SplunkServerClass] :: Adding RepositoryLocation [$RepositoryLocation] to `$MyArgs"
            $MyArgs.Add("repositoryLocation",$RepositoryLocation)
        }
        
        if($TargetRepositoryLocation)
        {
            Write-Verbose " [New-SplunkServerClass] :: Adding TargetRepositoryLocation [$TargetRepositoryLocation] to `$MyArgs"
            $MyArgs.Add("targetRepositoryLocation",$TargetRepositoryLocation)
        }
        
        if($TmpFolder)
        {
            Write-Verbose " [New-SplunkServerClass] :: Adding TmpFolder [$TmpFolder] to `$MyArgs"
            $MyArgs.Add("tmpFolder",$TmpFolder)
        }
			
		Write-Verbose " [New-SplunkServerClass] :: Calling Invoke-SplunkAPIRequest @InvokeAPIParams"
		try
		{
            if($PSCmdlet.ShouldProcess($ComputerName,"Creating new server class $ServerClass"))
    		{
			    [XML]$Results = Invoke-SplunkAPIRequest @InvokeAPIParams -Arguments $MyArgs -RequestType POST 
            }
        }
		catch
		{
			Write-Verbose " [New-SplunkServerClass] :: Invoke-SplunkAPIRequest threw an exception: $_"
            Write-Error $_
		}
        try
        {
			Write-Verbose " [New-SplunkServerClass] :: Checking for valid results"
			if($Results -and ($Results -is [System.Xml.XmlDocument]))
			{
				Write-Verbose " [New-SplunkServerClass] :: Fetching server class $ServerClass"
                $InvokeAPIParams = @{
        			ComputerName = $ComputerName
        			Port         = $Port
        			Protocol     = $Protocol
        			Timeout      = $Timeout
        			Credential   = $Credential
                    ServerClass  = $ServerClass
                }
                Get-SplunkServerClass @InvokeAPIParams
			}
			else
			{
				Write-Verbose " [New-SplunkServerClass] :: No Response from REST API. Check for Errors from Invoke-SplunkAPIRequest"
			}
		}
		catch
		{
			Write-Verbose " [New-SplunkServerClass] :: Get-SplunkServerClass threw an exception: $_"
            Write-Error $_
		}
	}
	End
	{
		Write-Verbose " [New-SplunkServerClass] :: =========    End   ========="
	}
} # New-SplunkServerClass

#endregion New-SplunkServerClass

#region Disable-SplunkServerClass

function Disable-SplunkServerClass
{
	<# .ExternalHelp ../Splunk-Help.xml #>
	[Cmdletbinding(SupportsShouldProcess=$true)]
    Param(
	    
        [Alias('Name')]
		[Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true,Mandatory=$True)]
		[STRING]$ServerClass,
        
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [String]$ComputerName = ( get-splunkconnectionobject ).ComputerName,
        
        [Parameter()]
        [int]$Port            = ( get-splunkconnectionobject ).Port,
        
        [Parameter()]
		[ValidateSet("http", "https")]
        [STRING]$Protocol     = ( get-splunkconnectionobject ).Protocol,
        
        [Parameter()]
        [int]$Timeout         = ( get-splunkconnectionobject ).Timeout,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = ( get-splunkconnectionobject ).Credential
        
    )
	
	Begin
	{
		Write-Verbose " [Disable-SplunkServerClass] :: Starting..."
        
	}
	Process
	{
        
		Write-Verbose " [Disable-SplunkServerClass] :: Parameters"
        Write-Verbose " [Disable-SplunkServerClass] ::  - ParameterSet = $ParamSetName"
		Write-Verbose " [Disable-SplunkServerClass] ::  - ComputerName = $ComputerName"
		Write-Verbose " [Disable-SplunkServerClass] ::  - Port         = $Port"
		Write-Verbose " [Disable-SplunkServerClass] ::  - Protocol     = $Protocol"
		Write-Verbose " [Disable-SplunkServerClass] ::  - Timeout      = $Timeout"
		Write-Verbose " [Disable-SplunkServerClass] ::  - Credential   = $Credential"
        Write-Verbose " [Disable-SplunkServerClass] ::  - WhereFilter  = $WhereFilter"
		Write-Verbose " [Disable-SplunkServerClass] ::  - Filter  	   = $Filter"
		Write-Verbose " [Disable-SplunkServerClass] ::  - ServerClass  = $ServerClass"
       
        
        Write-Verbose " [Disable-SplunkServerClass] :: checking if ServerClass is from Pipeline"
        if($ServerClass.PSTypeNames -contains "Splunk.SDK.Deployment.ServerClass")
        {
            $MyServerClass = $ServerClass
        }
        else
		{
            $InvokeAPIParams = @{
            			ComputerName = $ComputerName
            			Port         = $Port
            			Protocol     = $Protocol
            			Timeout      = $Timeout
            			Credential   = $Credential
                        ServerClass  = $ServerClass
            }
			$MyServerClass = Get-SplunkServerClass @InvokeAPIParams

		}

        Write-Verbose " [Disable-SplunkServerClass] ::  - Endpoint    = $($MyServerClass.ServiceEndpoint)"
		Write-Verbose " [Disable-SplunkServerClass] :: Setting up Invoke-APIRequest parameters"
		$InvokeAPIParams = @{
			ComputerName = $ComputerName
			Port         = $Port
			Protocol     = $Protocol
			Timeout      = $Timeout
			Credential   = $Credential
			Endpoint     = "{0}/disable" -f $MyServerClass.ServiceEndpoint 
			Verbose      = $VerbosePreference -eq "Continue"
		}
        
		Write-Verbose " [Disable-SplunkServerClass] :: Calling Invoke-SplunkAPIRequest @InvokeAPIParams"
		try
		{
            if($PSCmdlet.ShouldProcess($ComputerName,"Disabling server class $($MyServerClass.ServerClass)"))
    		{
			    [XML]$Results = Invoke-SplunkAPIRequest @InvokeAPIParams #-Arguments $MyArgs -RequestType POST 
            }
        }
		catch
		{
			Write-Verbose " [Disable-SplunkServerClass] :: Invoke-SplunkAPIRequest threw an exception: $_"
            Write-Error $_
		}
        try
        {
			Write-Verbose " [Disable-SplunkServerClass] :: Checking for valid results"
			if($Results -and ($Results -is [System.Xml.XmlDocument]))
			{
				Write-Verbose " [Disable-SplunkServerClass] :: Fetching server class $ServerClass"
                $InvokeAPIParams = @{
        			ComputerName = $ComputerName
        			Port         = $Port
        			Protocol     = $Protocol
        			Timeout      = $Timeout
        			Credential   = $Credential
                    ServerClass  = $MyServerClass.ServerClass
                }
                Get-SplunkServerClass @InvokeAPIParams
			}
			else
			{
				Write-Verbose " [Disable-SplunkServerClass] :: No Response from REST API. Check for Errors from Invoke-SplunkAPIRequest"
			}
		}
		catch
		{
			Write-Verbose " [Disable-SplunkServerClass] :: Get-SplunkServerClass threw an exception: $_"
            Write-Error $_
		}
	}
	End
	{
		Write-Verbose " [Disable-SplunkServerClass] :: =========    End   ========="
	}
} # Disable-SplunkServerClass

#endregion Disable-SplunkServerClass 

#region Enable-SplunkServerClass

function Enable-SplunkServerClass
{
	<# .ExternalHelp ../Splunk-Help.xml #>
	[Cmdletbinding(SupportsShouldProcess=$true)]
    Param(
	    
        [Alias('Name')]
		[Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true,Mandatory=$True)]
		[STRING]$ServerClass,
        
        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [String]$ComputerName = ( get-splunkconnectionobject ).ComputerName,
        
        [Parameter()]
        [int]$Port            = ( get-splunkconnectionobject ).Port,
        
        [Parameter()]
		[ValidateSet("http", "https")]
        [STRING]$Protocol     = ( get-splunkconnectionobject ).Protocol,
        
        [Parameter()]
        [int]$Timeout         = ( get-splunkconnectionobject ).Timeout,

        [Parameter()]
        [System.Management.Automation.PSCredential]
        [System.Management.Automation.Credential()]$Credential = ( get-splunkconnectionobject ).Credential
        
    )
	
	Begin
	{
		Write-Verbose " [Enable-SplunkServerClass] :: Starting..."
        
	}
	Process
	{
        
		Write-Verbose " [Enable-SplunkServerClass] :: Parameters"
        Write-Verbose " [Enable-SplunkServerClass] ::  - ParameterSet = $ParamSetName"
		Write-Verbose " [Enable-SplunkServerClass] ::  - ComputerName = $ComputerName"
		Write-Verbose " [Enable-SplunkServerClass] ::  - Port         = $Port"
		Write-Verbose " [Enable-SplunkServerClass] ::  - Protocol     = $Protocol"
		Write-Verbose " [Enable-SplunkServerClass] ::  - Timeout      = $Timeout"
		Write-Verbose " [Enable-SplunkServerClass] ::  - Credential   = $Credential"
        Write-Verbose " [Enable-SplunkServerClass] ::  - WhereFilter  = $WhereFilter"
		Write-Verbose " [Enable-SplunkServerClass] ::  - Filter  	   = $Filter"
		Write-Verbose " [Enable-SplunkServerClass] ::  - ServerClass  = $ServerClass"
       
        
        Write-Verbose " [Enable-SplunkServerClass] :: checking if ServerClass is from Pipeline"
        if($ServerClass.PSTypeNames -contains "Splunk.SDK.Deployment.ServerClass")
        {
            $MyServerClass = $ServerClass
        }
        else
		{
            $InvokeAPIParams = @{
            			ComputerName = $ComputerName
            			Port         = $Port
            			Protocol     = $Protocol
            			Timeout      = $Timeout
            			Credential   = $Credential
                        ServerClass  = $ServerClass
            }
			$MyServerClass = Get-SplunkServerClass @InvokeAPIParams

		}

        Write-Verbose " [Enable-SplunkServerClass] ::  - Endpoint    = $($MyServerClass.ServiceEndpoint)"
		Write-Verbose " [Enable-SplunkServerClass] :: Setting up Invoke-APIRequest parameters"
		$InvokeAPIParams = @{
			ComputerName = $ComputerName
			Port         = $Port
			Protocol     = $Protocol
			Timeout      = $Timeout
			Credential   = $Credential
			Endpoint     = "{0}/enable" -f $MyServerClass.ServiceEndpoint 
			Verbose      = $VerbosePreference -eq "Continue"
		}
        
		Write-Verbose " [Enable-SplunkServerClass] :: Calling Invoke-SplunkAPIRequest @InvokeAPIParams"
		try
		{
            if($PSCmdlet.ShouldProcess($ComputerName,"Disabling server class $($MyServerClass.ServerClass)"))
    		{
			    [XML]$Results = Invoke-SplunkAPIRequest @InvokeAPIParams #-Arguments $MyArgs -RequestType POST 
            }
        }
		catch
		{
			Write-Verbose " [Enable-SplunkServerClass] :: Invoke-SplunkAPIRequest threw an exception: $_"
            Write-Error $_
		}
        try
        {
			Write-Verbose " [Enable-SplunkServerClass] :: Checking for valid results"
			if($Results -and ($Results -is [System.Xml.XmlDocument]))
			{
				Write-Verbose " [Enable-SplunkServerClass] :: Fetching server class $ServerClass"
                $InvokeAPIParams = @{
        			ComputerName = $ComputerName
        			Port         = $Port
        			Protocol     = $Protocol
        			Timeout      = $Timeout
        			Credential   = $Credential
                    ServerClass  = $MyServerClass.ServerClass
                }
                Get-SplunkServerClass @InvokeAPIParams
			}
			else
			{
				Write-Verbose " [Enable-SplunkServerClass] :: No Response from REST API. Check for Errors from Invoke-SplunkAPIRequest"
			}
		}
		catch
		{
			Write-Verbose " [Enable-SplunkServerClass] :: Get-SplunkServerClass threw an exception: $_"
            Write-Error $_
		}
	}
	End
	{
		Write-Verbose " [Enable-SplunkServerClass] :: =========    End   ========="
	}
} # Enable-SplunkServerClass

#endregion Enable-SplunkServerClass 

#region Invoke-SplunkDeploymentServerReload

function Invoke-SplunkDeploymentServerReload
{
	<# .ExternalHelp ../Splunk-Help.xml #>

	[Cmdletbinding(SupportsShouldProcess=$true, ConfirmImpact='High')]
    Param(

        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [String]$ComputerName = ( get-splunkconnectionobject ).ComputerName,
        
        [Parameter()]
        [int]$Port            = ( get-splunkconnectionobject ).Port,
        
        [Parameter()]
		[ValidateSet("http", "https")]
        [STRING]$Protocol     = ( get-splunkconnectionobject ).Protocol,
        
        [Parameter()]
        [int]$Timeout         = ( get-splunkconnectionobject ).Timeout,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential = ( get-splunkconnectionobject ).Credential
        
    )
	
	Begin
	{
		Write-Verbose " [Invoke-SplunkDeploymentServerReload] :: Starting..."
	}
	Process
	{
		Write-Verbose " [Invoke-SplunkDeploymentServerReload] :: Parameters"
		Write-Verbose " [Invoke-SplunkDeploymentServerReload] ::  - ComputerName = $ComputerName"
		Write-Verbose " [Invoke-SplunkDeploymentServerReload] ::  - Port         = $Port"
		Write-Verbose " [Invoke-SplunkDeploymentServerReload] ::  - Protocol     = $Protocol"
		Write-Verbose " [Invoke-SplunkDeploymentServerReload] ::  - Timeout      = $Timeout"
		Write-Verbose " [Invoke-SplunkDeploymentServerReload] ::  - Credential   = $Credential"

		if( -not $pscmdlet.ShouldProcess( $ComputerName, "Reload Splunk Deployment Server" ) )
		{
			return;
		}

		Write-Verbose " [Invoke-SplunkDeploymentServerReload] :: Setting up Invoke-APIRequest parameters"
		$InvokeAPIParams = @{
			ComputerName = $ComputerName
			Port         = $Port
			Protocol     = $Protocol
			Timeout      = $Timeout
			Credential   = $Credential
			Endpoint     = '/services/deployment/server/_reload' 
			Verbose      = $VerbosePreference -eq "Continue"
		}
			
		Write-Verbose " [Invoke-SplunkDeploymentServerReload] :: Calling Invoke-SplunkAPIRequest @InvokeAPIParams"
		try
		{
			$xml = Invoke-SplunkAPIRequest @InvokeAPIParams
			
			#workaround bug in Splunk API where empy results are returned as invalid XML
			if( $xml -notmatch '<[^?]' )
			{
				return;
			}
			
			[XML]$Results = $xml;
        }
		catch
		{
			Write-Verbose " [Invoke-SplunkDeploymentServerReload] :: Invoke-SplunkAPIRequest threw an exception: $_"
            Write-Error $_
		}
        try
        {
			if($Results -and ($Results -is [System.Xml.XmlDocument]))
			{
                Write-Host "Reload of [$ComputerName] successful"
			}
			else
			{
				Write-Verbose " [Invoke-SplunkDeploymentServerReload] :: No Response from REST API. Check for Errors from Invoke-SplunkAPIRequest"
			}
		}
		catch
		{
			Write-Verbose " [Invoke-SplunkDeploymentServerReload] :: Get-SplunkServerClass threw an exception: $_"
            Write-Error $_
		}
	}
	End
	{
		Write-Verbose " [Invoke-SplunkDeploymentServerReload] :: =========    End   ========="
	}
} # Invoke-SplunkDeploymentServerReload

#endregion Invoke-SplunkDeploymentServerReload

#region Get-SplunkDeploymentClient

function Get-SplunkDeploymentClient
{
	<# .ExternalHelp ../Splunk-Help.xml #>

    [Cmdletbinding(DefaultParameterSetName="byFilter")]
    Param(

        [Parameter(Position=0,ParameterSetName="byFilter")]
        [STRING]$Filter = '.*',
	
		[Parameter(Position=0,ParameterSetName="byName")]
		[STRING]$Name,

        [Parameter(ValueFromPipelineByPropertyName=$true,ValueFromPipeline=$true)]
        [String]$ComputerName = ( get-splunkconnectionobject ).ComputerName,
        
        [Parameter()]
        [int]$Port            = ( get-splunkconnectionobject ).Port,
        
        [Parameter()]
		[ValidateSet("http", "https")]
        [STRING]$Protocol     = ( get-splunkconnectionobject ).Protocol,
        
        [Parameter()]
        [int]$Timeout         = ( get-splunkconnectionobject ).Timeout,

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential = ( get-splunkconnectionobject ).Credential
        
    )
    Begin
	{
		Write-Verbose " [Get-SplunkDeploymentClient] :: Starting..."
        $ParamSetName = $pscmdlet.ParameterSetName
        
        switch ($ParamSetName)
        {
            "byFilter"  { $WhereFilter = { $_.Name -match $Filter } } 
            "byName"    { $WhereFilter = { $_.Name -eq    $Name } }
        }
	}
	Process
	{
		Write-Verbose " [Get-SplunkDeploymentClient] :: Parameters"
        Write-Verbose " [Get-SplunkDeploymentClient] ::  - ParameterSet = $ParamSetName"
		Write-Verbose " [Get-SplunkDeploymentClient] ::  - ComputerName = $ComputerName"
		Write-Verbose " [Get-SplunkDeploymentClient] ::  - Port         = $Port"
		Write-Verbose " [Get-SplunkDeploymentClient] ::  - Protocol     = $Protocol"
		Write-Verbose " [Get-SplunkDeploymentClient] ::  - Timeout      = $Timeout"
		Write-Verbose " [Get-SplunkDeploymentClient] ::  - Credential   = $Credential"
        Write-Verbose " [Get-SplunkDeploymentClient] ::  - WhereFilter  = $WhereFilter"

		Write-Verbose " [Get-SplunkDeploymentClient] :: Setting up Invoke-APIRequest parameters"
		$InvokeAPIParams = @{
			ComputerName = $ComputerName
			Port         = $Port
			Protocol     = $Protocol
			Timeout      = $Timeout
			Credential   = $Credential
			Endpoint     = '/servicesNS/nobody/system/deployment/server/default/default.Clients' 
			Verbose      = $VerbosePreference -eq "Continue"
		}
			
		Write-Verbose " [Get-SplunkDeploymentClient] :: Calling Invoke-SplunkAPIRequest @InvokeAPIParams"
		try
		{
			[XML]$Results = Invoke-SplunkAPIRequest @InvokeAPIParams
        }
        catch
		{
			Write-Verbose " [Get-SplunkDeploymentClient] :: Invoke-SplunkAPIRequest threw an exception: $_"
            Write-Error $_
		}
        try
        {
			if($Results -and ($Results -is [System.Xml.XmlDocument]) -and ($results.feed.entry.content.dict) )
			{
				$MyObj = @{}
				Write-Verbose " [Get-SplunkDeploymentClient] :: Creating Hash Table to be used to create Splunk.SDK.Deployment.DeploymentClient"
				switch ($results.feed.entry.content.dict.key)
				{
		        	{$_.name -eq "build"}		    { $Myobj.Add("Build",$_.'#text')    ; continue }
					{$_.name -eq "ip"}	            { $Myobj.Add("IP",$_.'#text')       ; continue }
			        {$_.name -eq "hostname"}	    { $Myobj.Add("ComputerName",$_.'#text'); continue }
                    {$_.name -eq "mgmt"}		    { $Myobj.Add("MgmtPort",$_.'#text') ; continue }
                    {$_.name -eq "name"}		    { $Myobj.Add("Name",$_.'#text')     ; continue }
                    {$_.name -eq "phoneHomeTime"}	{ $Myobj.Add("LastUpdate",(ConvertFrom-SplunkTime $_.'#text')); continue }
                    {$_.name -eq "utsname"}		    { $Myobj.Add("utsname",$_.'#text')  ; continue }
                    {$_.name -eq "id"}		        { $Myobj.Add("ID",$_.'#text')       ; continue }
				}
				
				# Creating Splunk.SDK.ServiceStatus
			    $obj = New-Object PSObject -Property $MyObj
			    $obj.PSTypeNames.Clear()
			    $obj.PSTypeNames.Add('Splunk.SDK.Deployment.DeploymentClient')
			    $obj | Where-Object $WhereFilter
			}
			else
			{
				Write-Verbose " [Get-SplunkDeploymentClient] :: No Response from REST API. Check for Errors from Invoke-SplunkAPIRequest"
			}
		}
		catch
		{
			Write-Verbose " [Get-SplunkDeploymentClient] :: Get-SplunkDeploymentClient threw an exception: $_"
            Write-Error $_
		}
	}
	End
	{
		Write-Verbose " [Get-SplunkDeploymentClient] :: =========    End   ========="
	}

}    # Get-SplunkDeploymentClient

#endregion Get-SplunkDeploymentClient

#endregion Deployment
