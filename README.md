# ITSM System Developer Test
This repository is my (Jaiden Hodson) implementation for the following exercises:

## JavaScript Email Metric Summary (Exercise 1)

### Directions:
Using the attached file (TypeScript_Source_Data.json), create a script in TypeScript (preferred) or JavaScript that:

Ingests the data (however you prefer)

Aggregate the data into a summary for each assigned team (you have complete creative license as to what metrics or information to summarize)

Returns a JavaScript object for an email message (subject, body, etc) that will display each team’s summary in a stylized table in HTML format

### Steps to Run:

1. Navigate to: `ITSM-System-Developer-Test\javascript_email_metric_summary`

2. Build node_modules with: `npm install`

3. Run with: `npx tsx .\data_summarizer.ts`

4. Copy HTML from console and paste it into an online HTML viewer ([HTML Online Viewer](https://html.onlineviewer.net/))

  

## Powershell API Workflow (Exercise 2)

### Directions:
Using PowerShell, create a script that:

Pulls the current staff member list from the Oregon State Legislature (link: https://api.oregonlegislature.gov/odata/odataservice.svc/CommitteeStaffMembers)

Merges the data using the Legislative Session Key from the following source (link: https://api.oregonlegislature.gov/odata/odataservice.svc/LegislativeSessions)

Outputs a CSV containing the individual, the associated legislative session name, the beginning and end times ordered by session begin date/time.

### Steps to Run:

1. Navigate to: `ITSM-System-Developer-Test\powershell_api_workflow`

2. Run with: `.\osl_staff_csv_generator.ps1`

3. Alternatively, to run the script using xml files rather than pulling from the API, use the -f flag: `.\osl_staff_csv_generator.ps1 -f`

4. CSV file with be generated as: `osl_staff_session_data.csv`