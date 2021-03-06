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


#region General functions

#region Get-SplunkMessage

function Get-SplunkMessage
{
	<# .ExternalHelp ../Splunk-Help.xml #>

	[Cmdletbinding()]
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
		Write-Verbose " [Get-SplunkMessage] :: Starting..."
	}
	Process
	{
		Write-Verbose " [Get-SplunkMessage] :: Parameters"
		Write-Verbose " [Get-SplunkMessage] ::  - ComputerName = $ComputerName"
		Write-Verbose " [Get-SplunkMessage] ::  - Port         = $Port"
		Write-Verbose " [Get-SplunkMessage] ::  - Protocol     = $Protocol"
		Write-Verbose " [Get-SplunkMessage] ::  - Timeout      = $Timeout"
		Write-Verbose " [Get-SplunkMessage] ::  - Credential   = $Credential"

		Write-Verbose " [Get-SplunkMessage] :: Setting up Invoke-APIRequest parameters"
		$InvokeAPIParams = @{
			ComputerName = $ComputerName
			Port         = $Port
			Protocol     = $Protocol
			Timeout      = $Timeout
			Credential   = $Credential
			Endpoint     = '/services/messages' 
			Verbose      = $VerbosePreference -eq "Continue"
		}
			
		Write-Verbose " [Get-SplunkMessage] :: Calling Invoke-SplunkAPIRequest @InvokeAPIParams"
		try
		{
			[XML]$Results = Invoke-SplunkAPIRequest @InvokeAPIParams
        }
        catch
		{
			Write-Verbose " [Get-SplunkMessage] :: Invoke-SplunkAPIRequest threw an exception: $_"
            Write-Error $_
		}
        try
        {
			if($Results -and ($Results -is [System.Xml.XmlDocument]))
			{
                if($Results.feed.entry)
                {
                    foreach($Entry in $Results.feed.entry)
                    {
        				$MyObj = @{
                            ComputerName = $ComputerName
                        }
                        
                        $MyObj.Add("Name",$Entry.Title)
        				Write-Verbose " [Get-SplunkMessage] :: Creating Hash Table to be used to create Splunk.SDK.License.Message"
        				switch ($Entry.content.dict.key)
        				{
        		        	{$_.name -ne "eai:acl"}	{ $Myobj.Add("Message",$_.'#text')     ; continue }
        				}
        				
        				# Creating Splunk.SDK.ServiceStatus
        			    $obj = New-Object PSObject -Property $MyObj
        			    $obj.PSTypeNames.Clear()
        			    $obj.PSTypeNames.Add('Splunk.SDK.Message')
        			    $obj 
                    }
                }
                else
                {
                    Write-Verbose " [Get-SplunkMessage] :: No Messages Found"
                }
                
			}
			else
			{
				Write-Verbose " [Get-SplunkMessage] :: No Response from REST API. Check for Errors from Invoke-SplunkAPIRequest"
			}
		}
		catch
		{
			Write-Verbose " [Get-SplunkMessage] :: Get-SplunkDeploymentClient threw an exception: $_"
            Write-Error $_
		}
	}
	End
	{
		Write-Verbose " [Get-SplunkMessage] :: =========    End   ========="
	}

}    # Get-SplunkMessage

#endregion Get-SplunkMessage

#region Write-SplunkMessage

function Write-SplunkMessage
{
	<# .ExternalHelp ../Splunk-Help.xml #>

    [Cmdletbinding()]
    Param(
    
        [Parameter(Mandatory=$True)]           
        [String]$Message,
        
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
        [String]$HostName     = $Env:COMPUTERNAME,
        
        [Parameter()]           
        [String]$Source       = "Powershell_Script",
        
        [Parameter()]           
        [String]$SourceType   = "Splunk_PowerShell_ResourceKit",
        
        [Parameter()]           
        [String]$Index        = "main",

        [Parameter()]
        [System.Management.Automation.PSCredential]$Credential = ( get-splunkconnectionobject ).Credential
        
    )

	Begin
	{
		Write-Verbose " [Write-SplunkMessage] :: Starting..."
        $Stack = Get-PSCallStack
        $CallingScope = $Stack[$Stack.Count-2]
	}
	Process
	{
		Write-Verbose " [Write-SplunkMessage] :: Parameters"
		Write-Verbose " [Write-SplunkMessage] ::  - ComputerName = $ComputerName"
		Write-Verbose " [Write-SplunkMessage] ::  - Port         = $Port"
		Write-Verbose " [Write-SplunkMessage] ::  - Protocol     = $Protocol"
		Write-Verbose " [Write-SplunkMessage] ::  - Timeout      = $Timeout"
		Write-Verbose " [Write-SplunkMessage] ::  - Credential   = $Credential"

		Write-Verbose " [Write-SplunkMessage] :: Setting up Invoke-APIRequest parameters"
		$InvokeAPIParams = @{
			ComputerName = $ComputerName
			Port         = $Port
			Protocol     = $Protocol
			Timeout      = $Timeout
			Credential   = $Credential
			Endpoint     = '/services/receivers/simple' 
			Verbose      = $VerbosePreference -eq "Continue"
		}
                   
		Write-Verbose " [Write-SplunkMessage] :: Calling Invoke-SplunkAPIRequest @InvokeAPIParams"
		try
		{
            Write-Verbose " [Write-SplunkMessage] :: Creating POST message"
            $LogMessage = "{0} :: Caller={1} Message={2}" -f (Get-Date),$CallingScope.Command,$Message
            
            $MyParam = "host=${HostName}&source=${source}&sourcetype=${sourcetype}&index=$Index"
            Write-Verbose " [Write-SplunkMessage] :: URL Parameters [$MyParam]"
            
            Write-Verbose " [Write-SplunkMessage] :: Sending LogMessage - $LogMessage"
			[XML]$Results = Invoke-SplunkAPIRequest @InvokeAPIParams -PostMessage $LogMessage -URLParam $MyParam -RequestType SIMPLEPOST
        }
        catch
		{
			Write-Verbose " [Write-SplunkMessage] :: Invoke-SplunkAPIRequest threw an exception: $_"
            Write-Error $_
		}
        try
        {
			if($Results -and ($Results -is [System.Xml.XmlDocument]))
			{
                $Myobj = @{}

                foreach($key in $Results.response.results.result.field)
                {
                    $data = $key.Value.Text
                    switch -exact ($Key.k)
                    {
                        "_index"       {$Myobj.Add("Index",$data);continue}
                        "host"         {$Myobj.Add("Host",$data);continue}
                        "source"       {$Myobj.Add("Source",$data);continue} 
                        "sourcetype"   {$Myobj.Add("Sourcetype",$data);continue}
                    }
                }
                
                $obj = New-Object PSObject -Property $myobj
                $obj.PSTypeNames.Clear()
                $obj.PSTypeNames.Add('Splunk.SDK.MessageResult')
                $obj
			}
			else
			{
				Write-Verbose " [Write-SplunkMessage] :: No Response from REST API. Check for Errors from Invoke-SplunkAPIRequest"
			}
		}
		catch
		{
			Write-Verbose " [Write-SplunkMessage] :: Get-Splunkd threw an exception: $_"
            Write-Error $_
		}
	}
	End
	{
		Write-Verbose " [Write-SplunkMessage] :: =========    End   ========="
	}
    
}    # Write-SplunkMessage

#endregion Write-SplunkMessage

#endregion General functions
