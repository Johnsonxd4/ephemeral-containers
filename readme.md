 
 # Using kubernetes ephemeral containers to dump dotnet memory application:
 According with [kubernetes documentation](https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/),  ephemeral container use case is: "Sometimes it's necessary to inspect the state of an existing Pod, however, for example to troubleshoot a hard-to-reproduce bug. In these cases you can run an ephemeral container in an existing Pod to inspect its state and run arbitrary commands."

 Considering the problem is hard to produce, its a good way to take all the information you need to understand the problem.

 A good example of it is when you use a distroless image, or a scratch base image, and:
 * You Dont have any tool inside the container to get the memory dump.
 * The problem is hard to produce.
 * You dont want to stop your application in production, or degrade performance.

 Memory dump is just an example, considering you can use any dotnet tool inside this ephemeral container.

## Requirements: 

 ### Your target deployment must have shareProcessNamespace enabled: 

``` yaml 
    spec:
      shareProcessNamespace: true
 ```
 This will enable your ephemeral container to access the process in the target container.

 ### SYS_PTRACE also need to be enabled for the application:
 ```yaml
securityContext:
          capabilities:
            add:
              - SYS_PTRACE
```
 
 ### Create an empty volume (emptydir), and mount it in the /tmp container folder. It will be used later.

```yaml

 volumeMounts:
    - mountPath: /tmp
      name: cache-volume
  volumes:
  - name: cache-volume
    emptyDir:
      sizeLimit: 500Mi
```
### Adding environment variables:
Add the following environment variables to your container:
```sh
COMPlus_EnableDiagnostic=1
TMPDIR=/tmp
```
## Creating an ephemeral container:

The easyest way to create an ephemeral container is using the command `kubectl debug`
```pwsh
 kubectl debug -it --attach=true -c debugger --image=mcr.microsoft.com/dotnet/nightly/sdk:6.0 --share-processes <pod-name>
```
Unfortunatelly, `kubectl debug` do not allow us to define volume mounts for this container via command line. So, we gonna need to create it using the kubernetes rest api. 
 
 Here's an example of how to creat it, before run it, execute ```kubectl proxy```:
 ```pwsh
invoke-webrequest -URI 'http://127.0.0.1:8001/api/v1/namespaces/<namespace>/pods/<pod-name>/ephemeralcontainers' `
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
```

Here we created a ephemeral container, using the same volume we mounted for the target deployment. They must share this directory.


## Connecting to ephemeral container:
```pwsh
kubectl attach <pod-name> -c dump-debugger -i -t
```
Now, we're inside the ephemeral container.
# Inside ephemeral container:
## Install `dotnet-dump`:

```
dotnet tool install -g dotnet-dump
```

## make sure you have access to the process:
```pwsh

 > dotnet dump ps
 7  dotnet  /usr/share/dotnet/dotnet  dotnet my-leaking-app.dll
 452  dotnet  /usr/share/dotnet/dotnet  dotnet dump ps

 # collect the memory dump using /tmp as output
 > dotnet dump collect --process-id 7 -o /tmp/my-dump
 Writing full to /tmp/my-dump
```


By this time, you should be able to see the dump inside the folder `/tmp`

You can analyse it inside of the container itself, or download it to your machine and analyse it using `dotnet dump analyze` or `windbg`:

```
> dotnet dump analyze /tmp/my-dump
Loading core dump: my-dump ...
Ready to process analysis commands. Type 'help' to list available commands or 'help [command]' to get detailed help on a command.
Type 'quit' or 'exit' to exit the session.
>dumpheap -stat
Statistics:
MT Count TotalSize Class Name
...
7fc5163c15c0   386    40,144 System.Reflection.RuntimeMethodInfo
7fc517397888   152    41,752 System.Reflection.CustomAttributeNamedParameter[]
7fc5163cd630   462    44,352 System.Reflection.RuntimeParameterInfo
7fc5149d8390 1,356    54,240 System.RuntimeType
7fc592b71450   241    57,168 Free
7fc51819b4f8   902    57,728 System.Collections.Concurrent.ConcurrentDictionary<System.Int64, Microsoft.AspNetCore.Server.Kestrel.Core.Internal.Infrastructure.ConnectionReference>+Enumerator
7fc51593d180   488    74,176 System.RuntimeType+RuntimeTypeCache
7fc51591cc48 1,258   112,377 System.Byte[]
7fc5149da508   449   131,744 System.Object[]
7fc514a4b9d8   346   217,008 System.Int32[]
7fc514b01038 3,741   319,034 System.String
Total 27,288 objects, 2,233,629 bytes
```


References:
* https://bmiguel-teixeira.medium.com/ephemeral-containers-for-a-more-civilized-debugging-age-399fa3162f3b
* https://learn.microsoft.com/en-us/dotnet/core/diagnostics/diagnostics-in-containers
* https://kubernetes.io/docs/concepts/workloads/pods/ephemeral-containers/
