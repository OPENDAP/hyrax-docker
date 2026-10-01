# Hyrax Performance Configuration Tips

## OLFS ([olfs.xml](https://git.earthdata.nasa.gov/projects/HYRAX/repos/hyrax/browse/bamboo/deploy/files))

### \<timeOut\>
```xml
<timeOut>165</timeOut>
```
CloudFront (aka AWS) has a max time to first byte (TTFB) of 180 seconds.  We set that internal timeOut to a small number because we know that the timer is polled and not interrupt driven. We hope that by setting the value somewhat less than 180 seconds that we'll poll the time and find it expired with enough time to act, and with enough slop to not hit 180 seconds in between polling the timer. 

### \<maxResponseSize>
```xml
<maxResponseSize>0</maxResponseSize>
```
We set the maxResponseSize to 0 (unlimited) here because we know that BES will be using the value we place in the `site.conf` file.


### \<ClientPool>
```xml
<ClientPool maximum="15" maxCmds="100" />
```

The `ClientPool` configuration has a multiple performance effects.

The `maxiumum` values defines the limit to the number of open connections the OLFS will maintain with running `beslistener` processes. The memory utilized by each `beslistener` may grow significantly during the process of fulfilling a request. A good place to start an estimate of this would be to look at the `site.conf` entry for `BES.MaxVariableSize.bytes`, double it, and then multiple that value by the max number of client connections.

_memory_high_water_ = `BES.MaxVariableSize.bytes` * 2 * `ClientPool@maximum`


The `maxCmds` value indicates how many BES commands the OLFS will send be fore disconnecting from a particular `beslistener`, causing it to terminate.

* Larger values will improve the chances that in memory caches are utilized.
* Larger values may expose unpatched memory management issues in the BES.
* Smaller values will mean that memory cache is less useful because the shorter lif cycle of the `beslistener` will not have populated the memory cache and used the cached results.
* Smaller values will help to quell memory management problems.

## BES ([site.conf](https://git.earthdata.nasa.gov/projects/HYRAX/repos/hyrax/browse/bamboo/deploy/files))

### BES.MaxVariableSize.bytes
```
BES.MaxVariableSize.bytes = 2104533975
```
This is really about managing memory utilization. You can figure that, at least in NGAP, that the `beslistener` handling a request will consume about 2x the memory needed to hold the largest variable in the request.

So if we set the value to 72GB:
```
BES.MaxVariableSize.bytes = 77309411328
```
Then a `beslistener` handling a request for a 72GB variable can be expected to consume 144GB of memory.

And if the OLFS is configured to support 100 `beslistener` connections that could mean, in a worst case scenario, that the memory utilization high watermark for the system would be 14.4 TB


### BES.MaxResponseSize.bytes
```
BES.MaxResponseSize.bytes = 8329006592
```
This value serves as a proxy for max TTFB: How big a netcdf4 response can we build and begin transmitting within the value of `timeOut` set in the `olfs.xml`

Some of the knobs that affect this:
* Processor Speed
* Network and response speeds to S3 (or whatever system holds the granule)
* Which algorythm is being used to build the netcdf-4 response (To `dio` or not `dio`? _That_ is the question...)

This is evaluated early in the request handling process by the BES  - before the `dio` question can be answered. We probably need to fix that so we can be sensitive to the different netcdf-4 production algorithms.

