param (
    [switch]$f  # The -f flag for using file-based data, defaults to API
)

# Define URLs for the APIs
$staffApiUrl = "https://api.oregonlegislature.gov/odata/odataservice.svc/CommitteeStaffMembers"
$sessionsApiUrl = "https://api.oregonlegislature.gov/odata/odataservice.svc/LegislativeSessions"

# Define the paths for the XML files
$staffXmlPath = ".\import_files\committee_staff_members.xml"
$sessionsXmlPath = ".\import_files\legislative_sessions.xml"

# Define the namespaces for XML parsing
$namespaceManager = New-Object System.Xml.XmlNamespaceManager([System.Xml.NameTable]::new())
$namespaceManager.AddNamespace("atom", "http://www.w3.org/2005/Atom")
$namespaceManager.AddNamespace("d", "http://schemas.microsoft.com/ado/2007/08/dataservices")
$namespaceManager.AddNamespace("m", "http://schemas.microsoft.com/ado/2007/08/dataservices/metadata")

# Function to fetch and parse XML data
function Get-XmlDataFromSource($source, $urlOrPath) {
    try {
        if ($source -eq 'API') {
            # Create WebClient object
            $webClient = New-Object System.Net.WebClient

            # Fetch data from API
            $responseXml = $webClient.DownloadString($urlOrPath)
            $xmlDoc = New-Object System.Xml.XmlDocument
            $xmlDoc.LoadXml($responseXml)
            return $xmlDoc
        }
        elseif ($source -eq 'File') {
            # Read and parse XML from file
            if (Test-Path $urlOrPath) {
                $xmlContent = [xml] (Get-Content -Path $urlOrPath)
                return $xmlContent
            }
            else {
                Write-Host "XML file not found: $urlOrPath"
                return $null
            }
        }
    }
    catch {
        Write-Host "Error fetching XML data from ${source}: $_"
        return $null
    }
}

# Helper function to handle namespace and extract the data from XML
function Get-XmlNodeValue($node, $xpath, $namespaceManager) {
    $selectedNode = $node.SelectSingleNode($xpath, $namespaceManager)
    if ($selectedNode) {
        return $selectedNode.InnerText.Trim()
    }
    return $null
}

# Check if -f flag is provided (use file-based data)
if ($f) {
    Write-Host "Using XML files for data."

    # Load data from XML files
    $staffXml = Get-XmlDataFromSource -source 'File' -urlOrPath $staffXmlPath
    $sessionsXml = Get-XmlDataFromSource -source 'File' -urlOrPath $sessionsXmlPath

    if (-not $staffXml -or -not $sessionsXml) {
        Write-Host "Error loading XML data, exiting script."
        exit
    }
}
else {
    Write-Host "Using API for data."

    # Fetch data from the APIs
    $staffXml = Get-XmlDataFromSource -source 'API' -urlOrPath $staffApiUrl
    if (-not $staffXml) {
        Write-Host "No staff data fetched, exiting script."
        exit
    }

    $sessionsXml = Get-XmlDataFromSource -source 'API' -urlOrPath $sessionsApiUrl
    if (-not $sessionsXml) {
        Write-Host "No legislative session data fetched, exiting script."
        exit
    }
}

# Extract staff and session data from XML
$staffMembers = $staffXml.SelectNodes("//atom:entry", $namespaceManager) | ForEach-Object {
    [PSCustomObject]@{
        StaffMember           = "$(Get-XmlNodeValue $_ 'atom:content/m:properties/d:FirstName' $namespaceManager) $(Get-XmlNodeValue $_ 'atom:content/m:properties/d:LastName' $namespaceManager)"
        LegislativeSessionKey = Get-XmlNodeValue $_ 'atom:content/m:properties/d:SessionKey' $namespaceManager
        CommitteeCode         = Get-XmlNodeValue $_ 'atom:content/m:properties/d:CommitteeCode' $namespaceManager
        Title                 = Get-XmlNodeValue $_ 'atom:content/m:properties/d:Title' $namespaceManager
    }
}

$legislativeSessions = $sessionsXml.SelectNodes("//atom:entry", $namespaceManager) | ForEach-Object {
    [PSCustomObject]@{
        SessionKey  = Get-XmlNodeValue $_ 'atom:content/m:properties/d:SessionKey' $namespaceManager
        SessionName = Get-XmlNodeValue $_ 'atom:content/m:properties/d:SessionName' $namespaceManager
        BeginDate   = Get-XmlNodeValue $_ 'atom:content/m:properties/d:BeginDate' $namespaceManager
        EndDate     = Get-XmlNodeValue $_ 'atom:content/m:properties/d:EndDate' $namespaceManager
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
$csvPath = ".\export_files\osl_staff_session_data.csv"
$sortedData | Export-Csv -Path $csvPath -NoTypeInformation

Write-Host "CSV file has been saved to: $csvPath"
