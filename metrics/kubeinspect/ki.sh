#!/bin/bash
# kubeinpsect - show useful information about cpu sets/slices/usage on a node.

set -e

# Grab a list of *all* the pod names in the cluster
kubectl get pod --all-namespaces -o=custom-columns=NAME:.metadata.name,UID:.metadata.uid

allpods=$(kubectl get pod --all-namespaces -o=json)

declare -a podarray uidarray qosarray

podnames=$(jq ".items | .[] | .metadata.name" <<< "$allpods")
podarray=($podnames)
uids=$(jq ".items | .[] | .metadata.uid" <<< "$allpods")
uidarray=($uids)
qos=$(jq ".items | .[] | .status.qosClass" <<< "$allpods")
qosarray=($qos)

echo "Podnames: $podnames"
#echo "Podarray: $podarray"
echo "UIDs: $uids"
#echo "UIDarray: $uidarray"

for n in $(seq 0 $((${#podarray[@]}-1)) ); do
	echo "Pod ${podarray[$n]} : ${uidarray[$n]} : ${qosarray[$n]}"
	uid=${uidarray[$n]//\"/}
	shortuid=${uid:0:6}
	qos=${qosarray[$n]//\"/}

	case ${qos} in
		Guaranteed)
			setname="cpuset:/kubepods/pod${uid}"
			;;
		Burstable)
			setname="cpuset:/kubepods/burstable/pod${uid}"
			;;
		BestEffort)
			setname="cpuset:/kubepods/besteffort/pod${uid}"
			;;
		*)
			echo "QoS type parse failure: [${qos}"
			return
			;;
	esac


	cpusets=($(lscgroup ${setname}))
	#echo "cpusets are [${cpusets[@]}]"
	for cg in ${cpusets[@]}; do
		shortcg=${cg/cpuset://}
		vshortcg=${shortcg%/}
		vshortcg=${vshortcg##*/}
		vshortcg=${vshortcg:0:10}
		echo -n "    Examine $vshortcg: "
		cpuset=$(cgget -v -n -r cpuset.cpus ${shortcg})
		echo "cpuset: $cpuset"
	done
done
