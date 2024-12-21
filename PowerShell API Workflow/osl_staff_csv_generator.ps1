# Define URLs for the APIs
$staffApiUrl = "https://api.oregonlegislature.gov/odata/odataservice.svc/CommitteeStaffMembers"
$sessionsApiUrl = "https://api.oregonlegislature.gov/odata/odataservice.svc/LegislativeSessions"

# Define the paths for the XML files
$staffXmlPath = ".\committee_staff_members.xml"
$sessionsXmlPath = ".\legislative_sessions.xml"

# Flag to decide whether to use XML files or APIs
$useXmlData = $true

# Function to get XML data from the API
function Get-ApiData($url) {
    try {
        # Create a WebClient object to fetch the API data
        $webClient = New-Object System.Net.WebClient
        $responseXml = $webClient.DownloadString($url)  # Download the XML as a string

        # Load the XML content into an XmlDocument object
        $xmlDoc = New-Object System.Xml.XmlDocument
        $xmlDoc.LoadXml($responseXml)

        return $xmlDoc
    }
    catch {
        Write-Host "Error fetching data from API: $_"
        return $null
    }
}

# Function to parse XML data from a file
function Get-XmlData($filePath) {
    if (Test-Path $filePath) {
        try {
            $xmlContent = [xml] (Get-Content -Path $filePath)
            return $xmlContent
        }
        catch {
            Write-Host "Error reading XML file: $_"
            return $null
        }
    }
    else {
        Write-Host "XML file not found: $filePath"
        return $null
    }
}

# Decide whether to use XML files or pull data from the API
if ($useXmlData) {
    Write-Host "Using XML files for data."

    # Load data from XML files
    $staffXml = Get-XmlData -filePath $staffXmlPath
    $sessionsXml = Get-XmlData -filePath $sessionsXmlPath

    if (-not $staffXml -or -not $sessionsXml) {
        Write-Host "Error loading XML data, exiting script."
        exit
    }

    # Define the namespaces for XML parsing
    $namespaceManager = New-Object System.Xml.XmlNamespaceManager($staffXml.NameTable)
    $namespaceManager.AddNamespace("atom", "http://www.w3.org/2005/Atom")
    $namespaceManager.AddNamespace("d", "http://schemas.microsoft.com/ado/2007/08/dataservices")
    $namespaceManager.AddNamespace("m", "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata")

    # Extract staff and session data from XML
    $staffMembers = $staffXml.SelectNodes("//atom:entry", $namespaceManager) | ForEach-Object {
        [PSCustomObject]@{
            StaffMember           = "$($_.SelectSingleNode("atom:content/m:properties/d:FirstName", $namespaceManager).InnerText) $($_.SelectSingleNode("atom:content/m:properties/d:LastName", $namespaceManager).InnerText)"
            LegislativeSessionKey = $_.SelectSingleNode("atom:content/m:properties/d:SessionKey", $namespaceManager).InnerText
            CommitteeCode         = $_.SelectSingleNode("atom:content/m:properties/d:CommitteeCode", $namespaceManager).InnerText
            Title                 = $_.SelectSingleNode("atom:content/m:properties/d:Title", $namespaceManager).InnerText
        }
    }

    $legislativeSessions = $sessionsXml.SelectNodes("//atom:entry", $namespaceManager) | ForEach-Object {
        [PSCustomObject]@{
            SessionKey  = $_.SelectSingleNode("atom:content/m:properties/d:SessionKey", $namespaceManager).InnerText
            SessionName = $_.SelectSingleNode("atom:content/m:properties/d:SessionName", $namespaceManager).InnerText
            BeginDate   = $_.SelectSingleNode("atom:content/m:properties/d:BeginDate", $namespaceManager).InnerText
            EndDate     = $_.SelectSingleNode("atom:content/m:properties/d:EndDate", $namespaceManager).InnerText
        }
    }
}
else {
    Write-Host "Using API for data."

    # Fetch data from the APIs
    $staffMembers = Get-ApiData -url $staffApiUrl
    if (-not $staffMembers) {
        Write-Host "No staff data fetched, exiting script."
        exit
    }

    $legislativeSessions = Get-ApiData -url $sessionsApiUrl
    if (-not $legislativeSessions) {
        Write-Host "No legislative session data fetched, exiting script."
        exit
    }
}

# Merge staff data with session data by LegislativeSessionKey
$mergedData = @()

foreach ($staff in $staffMembers) {
    # Find the corresponding session for the staff member based on LegislativeSessionKey
    $session = $legislativeSessions | Where-Object { $_.SessionKey -eq $staff.LegislativeSessionKey }

    if ($session) {
        $mergedData += [PSCustomObject]@{
            StaffMember        = $staff.StaffMember
            LegislativeSession = $session.SessionName
            SessionBeginDate   = $session.BeginDate
            SessionEndDate     = $session.EndDate
        }
    }
}

# Sort the merged data by the session begin date
$sortedData = $mergedData | Sort-Object -Property SessionBeginDate

# Output the data to a CSV file
$csvPath = "osl_staff_session_data.csv"
$sortedData | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host "CSV file has been saved to: $csvPath"
