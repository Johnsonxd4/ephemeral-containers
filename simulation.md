# Simulation

> enable proxy:
```pwsh
 kubectl proxy --port 9090
 ```
>Attach to container:
```pwsh
kubectl exec -it <pod-name> -- sh  
```

>Exec inside ethe container:
```sh
apk add curl
touch commands.sh
#content
i=0
while [ $i -ne 1000 ]
do
        i=$(($i+1))
        curl http://localhost:9000/weatherforecast
done
#and get out
``` 

> Exec current to create the ephemeral container:
```pwsh
.\current.ps1
```
Attach the debugger:
```pwsh
kubectl attach -i -t <pod-name> -c dump-debugger
```

> install dotnet counter inside the debugger:
```sh
dotnet tool install --global dotnet-counters
```
>add dotnet commands to envvars:
```
export PATH="$PATH:/root/.dotnet/tools"
```
> Run dotnet counters 
```sh
dotnet counters monitor --process-id <process-id>
# gen 1 probably will be big 
```
> Install dotnet dump
```sh
dotnet tool install --global dotnet-dump
```
> List the dotnet processes available:
```sh
dotnet dump ps 
```
> Collect the memory dump of target process:
```sh
 dotnet dump collect --process-id 7 -o /tmp/my-dump
```

> Start the analysis of memory dump:
```sh 
dotnet dump analyze /tmp/my-dump
```
> list the current stack:
```
clrstack
```
> show current managed threads
```
clrthreads
```
> Show the status of all the heaps available, and s(mall)oh, l(arg)oh and p(inned)oh:
```
 gcheapstat
 ```
> Summarizes the amount of objects available in memory:
```
dumpheap -stat
# 7f4f6fe4dd00 15,025   480,800 my_leaking_app.WeatherForecast
```
> dumpheap by type:
```
 dumpheap -type my_leaking_app.WeatherForecast[]
```
> show objects of method table:
 ``` 
 dumpheap -mt <method-table>
 ```
 > show object properties:
 ``` 
 dumpobj <obj-address>
```

 > Whos pinning these objects? 
 ```
 gcroot <objaddress>
 ```
 
 
