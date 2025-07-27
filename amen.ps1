Add-Type -AssemblyName System.Windows.Forms
Add-Type -AssemblyName System.Drawing

$form = New-Object System.Windows.Forms.Form
$form.Text = "Event Log Viewer (Stable Edition)"
$form.Size = New-Object System.Drawing.Size(1250, 750)
$form.StartPosition = "CenterScreen"

$logLabel = New-Object System.Windows.Forms.Label
$logLabel.Text = "Log Types:"
$logLabel.Location = New-Object System.Drawing.Point(10,10)
$form.Controls.Add($logLabel)

$logBox = New-Object System.Windows.Forms.CheckedListBox
$logBox.Location = New-Object System.Drawing.Point(10,30)
$logBox.Size = New-Object System.Drawing.Size(180,100)
$logBox.Items.AddRange(@(
    "Application", "System", "Security", "Setup", "ForwardedEvents",
    "Microsoft-Windows-PowerShell/Operational",
    "Microsoft-Windows-Windows Defender/Operational"
))
$form.Controls.Add($logBox)

$idLabel = New-Object System.Windows.Forms.Label
$idLabel.Text = "Event ID(s):"
$idLabel.Location = New-Object System.Drawing.Point(200,10)
$form.Controls.Add($idLabel)

$idBox = New-Object System.Windows.Forms.TextBox
$idBox.Location = New-Object System.Drawing.Point(200,30)
$idBox.Size = New-Object System.Drawing.Size(150,20)
$form.Controls.Add($idBox)

$textLabel = New-Object System.Windows.Forms.Label
$textLabel.Text = "Message Contains:"
$textLabel.Location = New-Object System.Drawing.Point(370,10)
$form.Controls.Add($textLabel)

$textBox = New-Object System.Windows.Forms.TextBox
$textBox.Location = New-Object System.Drawing.Point(370,30)
$textBox.Size = New-Object System.Drawing.Size(150,20)
$form.Controls.Add($textBox)

$fromLabel = New-Object System.Windows.Forms.Label
$fromLabel.Text = "From:"
$fromLabel.Location = New-Object System.Drawing.Point(540,10)
$form.Controls.Add($fromLabel)

$fromDate = New-Object System.Windows.Forms.DateTimePicker
$fromDate.Location = New-Object System.Drawing.Point(540,30)
$fromDate.Format = 'Short'
$fromDate.Value = [datetime]::Today.AddDays(-7)
$form.Controls.Add($fromDate)

$toLabel = New-Object System.Windows.Forms.Label
$toLabel.Text = "To:"
$toLabel.Location = New-Object System.Drawing.Point(680,10)
$form.Controls.Add($toLabel)

$toDate = New-Object System.Windows.Forms.DateTimePicker
$toDate.Location = New-Object System.Drawing.Point(680,30)
$toDate.Format = 'Short'
$toDate.Value = [datetime]::Today
$form.Controls.Add($toDate)

$levelLabel = New-Object System.Windows.Forms.Label
$levelLabel.Text = "Level:"
$levelLabel.Location = New-Object System.Drawing.Point(820,10)
$form.Controls.Add($levelLabel)

$levelBox = New-Object System.Windows.Forms.ComboBox
$levelBox.Location = New-Object System.Drawing.Point(820,30)
$levelBox.Size = New-Object System.Drawing.Size(120,20)
$levelBox.Items.AddRange(@("All", "Information", "Warning", "Error", "Critical", "Verbose"))
$levelBox.SelectedIndex = 0
$form.Controls.Add($levelBox)

$loadButton = New-Object System.Windows.Forms.Button
$loadButton.Text = "Load Logs"
$loadButton.Location = New-Object System.Drawing.Point(960,30)
$form.Controls.Add($loadButton)

$clearButton = New-Object System.Windows.Forms.Button
$clearButton.Text = "Clear Filters"
$clearButton.Location = New-Object System.Drawing.Point(1060,30)
$form.Controls.Add($clearButton)

$exportButton = New-Object System.Windows.Forms.Button
$exportButton.Text = "Export CSV"
$exportButton.Location = New-Object System.Drawing.Point(1160,30)
$form.Controls.Add($exportButton)

$listView = New-Object System.Windows.Forms.ListView
$listView.Location = New-Object System.Drawing.Point(10,150)
$listView.Size = New-Object System.Drawing.Size(1210,540)
$listView.View = 'Details'
$listView.FullRowSelect = $true
$listView.GridLines = $true
$listView.Columns.Add("Time",150) | Out-Null
$listView.Columns.Add("Level",80) | Out-Null
$listView.Columns.Add("Source",200) | Out-Null
$listView.Columns.Add("Event ID",80) | Out-Null
$listView.Columns.Add("Message",700) | Out-Null
$form.Controls.Add($listView)

$global:eventCache = @()

$loadButton.Add_Click({
    $listView.Items.Clear()
    $global:eventCache = @()
    $selectedLogs = @()
    foreach ($item in $logBox.CheckedItems) { $selectedLogs += $item }

    $levelFilter = $levelBox.SelectedItem
    $textFilter = $textBox.Text
    $idInput = $idBox.Text -replace '\s',''
    $idList = @()
    if ($idInput) { $idList = $idInput -split ',' | ForEach-Object { $_.Trim() } }

    $from = $fromDate.Value
    $to = $toDate.Value

    if ($selectedLogs.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("Please select at least one log type.")
        return
    }

    $total = 0
    foreach ($log in $selectedLogs) {
        try {
            $filterHash = @{
                LogName   = $log
                StartTime = $from
                EndTime   = $to
            }

            $events = Get-WinEvent -FilterHashtable $filterHash -MaxEvents 500 -ErrorAction SilentlyContinue

            $events = $events | Where-Object {
                ($idList.Count -eq 0 -or $idList -contains $_.Id.ToString()) -and
                ([string]::IsNullOrWhiteSpace($textFilter) -or $_.Message -like "*$textFilter*") -and
                ($levelFilter -eq "All" -or $_.LevelDisplayName -eq $levelFilter)
            }

            foreach ($event in $events) {
                try {
                    $timeStr   = if ($event.TimeCreated) { $event.TimeCreated.ToString() } else { "(Unknown)" }
                    $levelStr  = if ($event.LevelDisplayName) { $event.LevelDisplayName } else { "(Unknown)" }
                    $sourceStr = if ($event.ProviderName)     { $event.ProviderName }     else { "(Unknown)" }
                    $idStr     = if ($event.Id)               { $event.Id.ToString() }    else { "0" }
                    $msg       = if ($event.Message)          { $event.Message }          else { "(No message)" }

                    $msg = ($msg -replace "`r`n", " ") -replace "\s+", " "
                    if ($msg.Length -gt 600) { $msg = $msg.Substring(0,600) + "..." }

                    $row = New-Object System.Windows.Forms.ListViewItem($timeStr)
                    $null = $row.SubItems.Add($levelStr)
                    $null = $row.SubItems.Add($sourceStr)
                    $null = $row.SubItems.Add($idStr)
                    $null = $row.SubItems.Add($msg)
                    $null = $listView.Items.Add($row)

                    $global:eventCache += [PSCustomObject]@{
                        Time     = $timeStr
                        Level    = $levelStr
                        Source   = $sourceStr
                        EventID  = $idStr
                        Message  = $msg
                    }

                    $total++
                } catch {
                    [System.Windows.Forms.MessageBox]::Show("Error adding row: $($_.Exception.Message)")
                }
            }
        } catch {
            [System.Windows.Forms.MessageBox]::Show("Error reading log: $log`n$($_.Exception.Message)")
        }
    }

    if ($total -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No logs matched your filters.")
    }
})

$clearButton.Add_Click({
    for ($i=0; $i -lt $logBox.Items.Count; $i++) { $logBox.SetItemChecked($i, $false) }
    $idBox.Clear()
    $textBox.Clear()
    $levelBox.SelectedIndex = 0
    $fromDate.Value = [datetime]::Today.AddDays(-7)
    $toDate.Value = [datetime]::Today
    $listView.Items.Clear()
    $global:eventCache = @()
})

$exportButton.Add_Click({
    if ($global:eventCache.Count -eq 0) {
        [System.Windows.Forms.MessageBox]::Show("No data to export.")
        return
    }

    $saveFile = New-Object System.Windows.Forms.SaveFileDialog
    $saveFile.Filter = "CSV Files (*.csv)|*.csv"
    if ($saveFile.ShowDialog() -eq "OK") {
        $global:eventCache | Export-Csv -Path $saveFile.FileName -NoTypeInformation -Encoding UTF8
        [System.Windows.Forms.MessageBox]::Show("Logs exported successfully.")
    }
})

[void]$form.ShowDialog()
