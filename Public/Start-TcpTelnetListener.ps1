function Start-TcpTelnetListener {
    <#
    .SYNOPSIS
        Starts a simple TCP listener for telnet connections.

    .DESCRIPTION
        Allows telnet clients to connect and receive an echo response. Includes Ctrl+C support to exit cleanly.

    .PARAMETER Port
        TCP port to listen on. Default is 2323.

    .PARAMETER IPAddress
        IP address to bind the listener to. Default is 0.0.0.0.

    .EXAMPLE
        Start-TcpTelnetListener -Port 2323
    #>
    [CmdletBinding()]
    param (
        [int]$Port = 2323,
        [string]$IPAddress = '0.0.0.0'
    )

    Write-Warning "This script starts an unauthenticated TCP listener."
    Write-Warning "Do NOT expose this to the internet or untrusted networks."
    $confirmation = Read-Host "Type 'YES' to proceed"
    if ($confirmation -ne 'YES') {
        Write-Host "Aborted by user."
        return
    }

    $script:stopListening = $false

    Register-EngineEvent -SourceIdentifier Console_CancelKeyPress -Action {
        Write-Host "`nCtrl+C detected. Stopping listener..."
        $script:stopListening = $true
    } | Out-Null

    try {
        $ipAddressParsed = [System.Net.IPAddress]::Parse($IPAddress)
        $listener = [System.Net.Sockets.TcpListener]::new($ipAddressParsed, $Port)
        $listener.Start()
        Write-Host "TCP listener started on $IPAddress" + ":$Port. Press Ctrl+C to stop."

        while (-not $script:stopListening) {
            if ($listener.Pending()) {
                $client = $listener.AcceptTcpClient()
                Write-Host "Client connected from $($client.Client.RemoteEndPoint)"

                $stream = $client.GetStream()
                $writer = [System.IO.StreamWriter]::new($stream)
                $reader = [System.IO.StreamReader]::new($stream)

                $writer.AutoFlush = $true
                $writer.WriteLine("Welcome to the PowerShell Telnet Listener!")
                $writer.WriteLine("Type 'exit' to disconnect.`n")

                while ($client.Connected -and $stream.CanRead -and -not $script:stopListening) {
                    if ($stream.DataAvailable) {
                        $line = $reader.ReadLine()
                        if ($line -eq "exit") {
                            $writer.WriteLine("Goodbye!")
                            break
                        }
                        $writer.WriteLine("You said: $line")
                    } else {
                        Start-Sleep -Milliseconds 200
                    }
                }

                $client.Close()
                Write-Host "Client disconnected."
            } else {
                Start-Sleep -Milliseconds 200
            }
        }

    } catch {
        Write-Error "Error: $_"
    } finally {
        if ($listener) {
            $listener.Stop()
            Write-Host "TCP listener stopped."
        }

        # Clean up event
        Unregister-Event -SourceIdentifier Console_CancelKeyPress -ErrorAction SilentlyContinue
        Remove-Event -SourceIdentifier Console_CancelKeyPress -ErrorAction SilentlyContinue
    }
}
