# Copilot Task Monitor
# Monitors failed/rate-limited Copilot tasks and re-queues them when capacity frees up

param(
    [int]$MaxConcurrentTasks = 15,      # Maximum concurrent Copilot tasks before pausing
    [int]$CheckIntervalSeconds = 300,   # How often to check (5 minutes default)
    [int]$RequeueDelaySeconds = 60,     # Delay between re-queue attempts
    [switch]$DryRun                     # Don't actually re-queue, just report
)

$Owner = "ReleMai"
$Repo = "CargoEscape"
$Token = $env:GITHUB_PERSONAL_ACCESS_TOKEN
$Headers = @{
    "Authorization" = "token $Token"
    "Accept" = "application/vnd.github+json"
}
$BaseUrl = "https://api.github.com/repos/$Owner/$Repo"

# Rate limit error message to look for
$RateLimitMessage = "The rate limit was exceeded"
$AgentErrorMessage = "The agent encountered an error"

function Write-Log {
    param([string]$Message, [string]$Level = "INFO")
    $timestamp = Get-Date -Format "yyyy-MM-dd HH:mm:ss"
    $color = switch ($Level) {
        "ERROR" { "Red" }
        "WARN"  { "Yellow" }
        "SUCCESS" { "Green" }
        default { "White" }
    }
    Write-Host "[$timestamp] [$Level] $Message" -ForegroundColor $color
}

function Get-OpenIssues {
    $issues = @()
    $page = 1
    do {
        $response = Invoke-RestMethod -Uri "$BaseUrl/issues?state=open&per_page=100&page=$page" -Headers $Headers
        $issues += $response
        $page++
    } while ($response.Count -eq 100)
    return $issues
}

function Get-IssueComments {
    param([int]$IssueNumber)
    try {
        $comments = Invoke-RestMethod -Uri "$BaseUrl/issues/$IssueNumber/comments" -Headers $Headers
        return $comments
    } catch {
        Write-Log "Failed to get comments for issue #$IssueNumber : $_" "ERROR"
        return @()
    }
}

function Get-OpenPullRequests {
    $prs = @()
    $page = 1
    do {
        $response = Invoke-RestMethod -Uri "$BaseUrl/pulls?state=open&per_page=100&page=$page" -Headers $Headers
        $prs += $response
        $page++
    } while ($response.Count -eq 100)
    return $prs
}

function Get-CopilotActiveTasks {
    # Count PRs that are actively being worked on by Copilot (WIP PRs)
    $prs = Get-OpenPullRequests
    $activeTasks = $prs | Where-Object { $_.title -like "*[WIP]*" -or $_.user.login -eq "copilot" }
    return $activeTasks.Count
}

function Find-RateLimitedIssues {
    Write-Log "Scanning issues for rate-limited tasks..."
    $issues = Get-OpenIssues
    $rateLimitedIssues = @()
    
    foreach ($issue in $issues) {
        # Skip PRs (they show up in issues endpoint too)
        if ($issue.pull_request) { continue }
        
        $comments = Get-IssueComments -IssueNumber $issue.number
        
        foreach ($comment in $comments) {
            if ($comment.body -like "*$RateLimitMessage*" -or $comment.body -like "*$AgentErrorMessage*") {
                $rateLimitedIssues += @{
                    Number = $issue.number
                    Title = $issue.title
                    Labels = ($issue.labels | ForEach-Object { $_.name }) -join ", "
                    ErrorComment = $comment.body.Substring(0, [Math]::Min(200, $comment.body.Length))
                }
                Write-Log "Found rate-limited issue #$($issue.number): $($issue.title)" "WARN"
                break
            }
        }
        
        # Small delay to avoid hitting rate limits ourselves
        Start-Sleep -Milliseconds 100
    }
    
    return $rateLimitedIssues
}

function Invoke-RequeueIssue {
    param([int]$IssueNumber, [string]$Title)
    
    if ($DryRun) {
        Write-Log "[DRY RUN] Would re-queue issue #$IssueNumber : $Title" "INFO"
        return $true
    }
    
    Write-Log "Re-queuing issue #$IssueNumber : $Title" "INFO"
    
    # Use GitHub CLI or API to assign Copilot
    # Note: This requires the copilot API endpoint which may need MCP
    # For now, we'll add a comment requesting re-assignment
    
    $commentBody = @{
        body = "@copilot Please try again on this issue. The previous attempt failed due to rate limiting."
    } | ConvertTo-Json
    
    try {
        Invoke-RestMethod -Uri "$BaseUrl/issues/$IssueNumber/comments" -Method Post -Headers $Headers -Body $commentBody -ContentType "application/json"
        Write-Log "Added re-queue comment to issue #$IssueNumber" "SUCCESS"
        return $true
    } catch {
        Write-Log "Failed to add comment to issue #$IssueNumber : $_" "ERROR"
        return $false
    }
}

function Show-Status {
    $activeTasks = Get-CopilotActiveTasks
    $rateLimitedIssues = Find-RateLimitedIssues
    
    Write-Host ""
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host "       COPILOT TASK MONITOR STATUS     " -ForegroundColor Cyan
    Write-Host "========================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host "Active Copilot Tasks: $activeTasks / $MaxConcurrentTasks" -ForegroundColor $(if ($activeTasks -ge $MaxConcurrentTasks) { "Red" } else { "Green" })
    Write-Host "Rate-Limited Issues:  $($rateLimitedIssues.Count)" -ForegroundColor $(if ($rateLimitedIssues.Count -gt 0) { "Yellow" } else { "Green" })
    Write-Host ""
    
    if ($rateLimitedIssues.Count -gt 0) {
        Write-Host "Rate-Limited Issues:" -ForegroundColor Yellow
        foreach ($issue in $rateLimitedIssues) {
            Write-Host "  #$($issue.Number): $($issue.Title)" -ForegroundColor Yellow
        }
    }
    
    return @{
        ActiveTasks = $activeTasks
        RateLimitedIssues = $rateLimitedIssues
    }
}

function Start-Monitor {
    Write-Log "Starting Copilot Task Monitor..." "INFO"
    Write-Log "Max Concurrent Tasks: $MaxConcurrentTasks" "INFO"
    Write-Log "Check Interval: $CheckIntervalSeconds seconds" "INFO"
    Write-Log "Press Ctrl+C to stop" "INFO"
    Write-Host ""
    
    $requeueQueue = @()
    
    while ($true) {
        try {
            $status = Show-Status
            
            # Add newly found rate-limited issues to queue
            foreach ($issue in $status.RateLimitedIssues) {
                if ($requeueQueue.Number -notcontains $issue.Number) {
                    $requeueQueue += $issue
                    Write-Log "Added issue #$($issue.Number) to re-queue list" "INFO"
                }
            }
            
            # If we have capacity and issues to re-queue
            if ($status.ActiveTasks -lt $MaxConcurrentTasks -and $requeueQueue.Count -gt 0) {
                $availableSlots = $MaxConcurrentTasks - $status.ActiveTasks
                $toRequeue = $requeueQueue | Select-Object -First $availableSlots
                
                Write-Log "Capacity available! Re-queuing $($toRequeue.Count) issues..." "SUCCESS"
                
                foreach ($issue in $toRequeue) {
                    $success = Invoke-RequeueIssue -IssueNumber $issue.Number -Title $issue.Title
                    if ($success) {
                        $requeueQueue = $requeueQueue | Where-Object { $_.Number -ne $issue.Number }
                    }
                    Start-Sleep -Seconds $RequeueDelaySeconds
                }
            }
            
            Write-Log "Next check in $CheckIntervalSeconds seconds..." "INFO"
            Write-Host ""
            Start-Sleep -Seconds $CheckIntervalSeconds
            
        } catch {
            Write-Log "Error during monitoring: $_" "ERROR"
            Start-Sleep -Seconds 60
        }
    }
}

# Main execution
Write-Host ""
Write-Host "  ____            _ _       _     __  __             _ _             " -ForegroundColor Cyan
Write-Host " / ___|___  _ __ (_) | ___ | |_  |  \/  | ___  _ __ (_) |_ ___  _ __ " -ForegroundColor Cyan
Write-Host "| |   / _ \| '_ \| | |/ _ \| __| | |\/| |/ _ \| '_ \| | __/ _ \| '__|" -ForegroundColor Cyan
Write-Host "| |__| (_) | |_) | | | (_) | |_  | |  | | (_) | | | | | || (_) | |   " -ForegroundColor Cyan
Write-Host " \____\___/| .__/|_|_|\___/ \__| |_|  |_|\___/|_| |_|_|\__\___/|_|   " -ForegroundColor Cyan
Write-Host "           |_|                                                       " -ForegroundColor Cyan
Write-Host ""

# If no arguments, show status once
if ($args.Count -eq 0 -and -not $PSBoundParameters.ContainsKey('CheckIntervalSeconds')) {
    Show-Status
    Write-Host ""
    Write-Host "To start continuous monitoring, run:" -ForegroundColor Gray
    Write-Host "  .\copilot_monitor.ps1 -CheckIntervalSeconds 300" -ForegroundColor White
} else {
    Start-Monitor
}
