 for file in `virsh list|awk '{ print $2 }'|grep -v "Name"|grep -v "s"`; do echo "hostname= $file"; virsh dumpxml $file|grep "device='disk'" -A 2; done

