

invoke-webrequest -URI 'http://127.0.0.1:8001/api/v1/namespaces/<your-namespace-here>/pods/<pod-name>/ephemeralcontainers' `
-Method 'PATCH' `
-Headers @{'Content-Type' = 'application/strategic-merge-patch+json'} `
-Body '
{ 
    "spec": { 
        "ephemeralContainers": [ 
            { 
                "image": "mcr.microsoft.com/dotnet/nightly/sdk:6.0-alpine", 
                "name": "dump-debugger", 
                "args":[
                    "sh"
                ],
                "tty":true,
                "stdin": true,
                "securityContext": {
                    "capabilities": {
                        "add": [
                            "SYS_PTRACE"
                        ]
                    }
                },
                "volumeMounts": [ 
                    { 
                        "mountPath": "/tmp", 
                        "name": "cache-volume" 
                    } 
                ] 
            } 
        ] 
    } 
}' -UseBasicParsing

