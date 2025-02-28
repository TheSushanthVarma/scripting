# Script to launch Google Chrome
try {
    # Default Chrome path
    $chromePath = "C:\Program Files\Google\Chrome\Application\chrome.exe"
    
    # Alternative Chrome path (x86)
    $chromePathx86 = "C:\Program Files (x86)\Google\Chrome\Application\chrome.exe"
    
    # Check if Chrome exists in the default location
    if (Test-Path $chromePath) {
        Start-Process $chromePath
    }
    # Check if Chrome exists in the x86 location
    elseif (Test-Path $chromePathx86) {
        Start-Process $chromePathx86
    }
    else {
        Write-Host "Chrome is not installed in the default locations." -ForegroundColor Red
    }
}
catch {
    Write-Host "An error occurred: $($_.Exception.Message)" -ForegroundColor Red
}
