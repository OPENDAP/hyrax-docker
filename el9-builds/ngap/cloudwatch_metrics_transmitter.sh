#!/bin/bash
# Here are the fields/contents of /proc/meminfo
#
#  MemTotal:        1817080 kB
#  MemFree:          604092 kB
#  MemAvailable:     984796 kB
#  Buffers:               0 kB
#  Cached:           580776 kB
#  SwapCached:            0 kB
#  Active:           282772 kB
#  Inactive:         759916 kB
#  Active(anon):      46812 kB
#  Inactive(anon):   513800 kB
#  Active(file):     235960 kB
#  Inactive(file):   246116 kB
#  Unevictable:           0 kB
#  Mlocked:               0 kB
#  SwapTotal:             0 kB
#  SwapFree:              0 kB
#  Dirty:                48 kB
#  Writeback:             0 kB
#  AnonPages:        461936 kB
#  Mapped:            87612 kB
#  Shmem:             98700 kB
#  KReclaimable:      58508 kB
#  Slab:             116820 kB
#  SReclaimable:      58508 kB
#  SUnreclaim:        58312 kB
#  KernelStack:        2576 kB
#  PageTables:         9100 kB
#  NFS_Unstable:          0 kB
#  Bounce:                0 kB
#  WritebackTmp:          0 kB
#  CommitLimit:      908540 kB
#  Committed_AS:     974356 kB
#  VmallocTotal:   34359738367 kB
#  VmallocUsed:           0 kB
#  VmallocChunk:          0 kB
#  Percpu:             1064 kB
#  HardwareCorrupted:     0 kB
#  AnonHugePages:    348160 kB
#  ShmemHugePages:        0 kB
#  ShmemPmdMapped:        0 kB
#  FileHugePages:         0 kB
#  FilePmdMapped:         0 kB
#  HugePages_Total:       0
#  HugePages_Free:        0
#  HugePages_Rsvd:        0
#  HugePages_Surp:        0
#  Hugepagesize:       2048 kB
#  Hugetlb:               0 kB
#  DirectMap4k:      141224 kB
#  DirectMap2M:     1916928 kB
#  DirectMap1G:           0 kB


function aws_units(){
    local memproc_units="${1}"
    local aws_units="Bytes"
# An error occurred (InvalidParameterValue) when calling the PutMetricData operation: The parameter MetricData.member.1.Unit must be a value in the set [ Megabits, Terabits, Gigabits, Count, Bytes, Gigabytes, Gigabytes/Second, Kilobytes, Kilobits/Second, Terabytes, Terabits/Second, Bytes/Second, Percent, Megabytes, Megabits/Second, Milliseconds, Microseconds, Kilobytes/Second, Gigabits/Second, Megabytes/Second, Bits, Bits/Second, Count/Second, Seconds, Kilobits, Terabytes/Second, None ].

    if test "${memproc_units}" == "kB"; then aws_units="Kilobytes"; 
    elif test "${memproc_units}" == "MB"; then aws_units="Megabytes"; 
    elif test "${memproc_units}" == "GB"; then aws_units="Gigabytes"; 
    elif test "${memproc_units}" == "TB"; then aws_units="Terabytes"; fi
    echo "${aws_units}"
}

function mem_watch() {
    
    # Acquire instance metadata, doesn't change so outside loop.
    export instance_id=$(curl -s http://169.254.169.254/latest/meta-data/instance-id)
    if test -n "${verbose}"; then echo "instance_id: ${instance_id}" >&2; fi
    
    export instance_type=$(curl -s http://169.254.169.254/latest/meta-data/instance-type)
    if test -n "${verbose}"; then echo "instance_type: ${instance_type}" >&2; fi

    while(true)
    do
        # Set sample_time
        sample_time=$(date '+%Y-%m-%dT%H:%M:%S.000%Z')
        if test -n "${verbose}"; then echo "sample_time: ${sample_time}" >&2; fi
        # Sample /proc/memproc
        memproc_sample=$(cat /proc/meminfo)
    
        # Get the goodies...
        mem_avail=$(echo "${memproc_sample}" | grep  MemAvailable /proc/meminfo | awk '{print $2}')
        mem_units=$(echo "${memproc_sample}" | grep  MemAvailable /proc/meminfo | awk '{print $3}')
        units=$(aws_units ${mem_units})
    
        if test -n "${verbose}"; then echo "mem_avail: ${mem_avail} ${units}" >&2; fi
    
    
        aws cloudwatch put-metric-data \
            --metric-name MemAvailable \
            --namespace hyrax \
            --unit "${units}" \
            --value "${mem_avail}" \
            --timestamp "${sample_time}"\
            --dimensions InstanceId="${instance_id}",InstanceType="${instance_type}"
    
        status=$?
        if test ${status} -ne 0 ; then echo "ERROR - The call to 'aws cloudwatch put-metric-data' failed. status: ${status}" >&2; fi
            
        sleep 1
    done
}

mem_watch

