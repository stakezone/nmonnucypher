#!/bin/bash

#####    Packages required: jq, bc

#####    CONFIG    ##################################################################################################
stakingAddress="" # the staking address CHECKSUM_ADDRESS (without 0x)
cli=""            # nucypher cli, eg. /home/user/.local/bin/nucypher
network="mainnet" # network, eg. mainnet or ibex
provider=""       # provider URI, eg. file:///home/user/.ethereum/geth.ipc
poa=""            # insert '--poa' if required by chain, otherwise leave empty
worklock="on"     # set to 'on' for worklock specific data
logname=""        # a custom log file name can be chosen, if left empty default is nodecheck-<username>.log
logpath="$(pwd)"  # the directory where the log file is stored, for customization insert path like: /my/path
logsize=200       # the max number of lines after that the log gets truncated to reduce its size
logmgmt="1"       # options for log rotation: (1) rotate to $LOGNAME.1 every $LOGSIZE lines;  (2) append to $LOGNAME.1 every $LOGSIZE lines; (3) truncate $logfile to $LOGSIZE every iteration
sleep1=30s        # polls every sleep1 sec
#####  END CONFIG  ##################################################################################################

ursulaRunning="yes"
ursula=$(ps aux | grep ursula | grep nucypher | grep $(whoami))
if [ -z "$ursula" ]; then
    echo "ursula appears to be down, please start the worker..."
    ursulaRunning="no"
fi
echo "ursula running: $ursulaRunning"

gethRunning="yes"
geth=$(ps aux | grep geth | grep $(whoami))
if [ -z "$geth" ]; then
    echo "geth appears to be down, please start geth..."
    gethRunning="no"
fi
echo "geth running: $gethRunning"

clefRunning="yes"
clef=$(ps aux | grep clef | grep $(whoami))
if [ -z "$clef" ]; then
    echo "clef appears to be down, please start clef..."
    clefRunning="no"
fi
echo "clef running: $clefRunning"

if [ -z "$stakingAddress" ]; then
    echo "please configure the staking address in script"
    exit 1
fi
statusNetwork=$($cli status network --provider $provider --network $network)
test=$(grep -c "Reading Latest Chaindata" <<<$statusNetwork)
if [ $test == "0" ]; then
    echo "please configure cli and parameters correctly"
    exit 1
fi
#echo $statusNetwork

statusStakers=$($cli status stakers --provider $provider --network $network)
#echo $statusStakers
test=$(grep -c "0x${stakingAddress}" <<<$statusStakers)
if [ $test == "0" ]; then
    echo "please make sure that the staking address is correct or in the stakers set"
    exit 1
fi
echo "staking address confirmed: $stakingAddress"

if [ -z $logname ]; then logname="nodemonitor-${USER}.log"; fi
logfile="${logpath}/${logname}"
touch $logfile

echo "log file: ${logfile}"

nloglines=$(wc -l <$logfile)
if [ $nloglines -gt $logsize ]; then sed -i "1,$(expr $nloglines - $logsize)d" $logfile; fi # the log file is trimmed for logsize

date=$(date --rfc-3339=seconds)
echo "$date status=scriptstarted chainid=$chainid" >>$logfile

echo ""

while true; do
    statusNetwork=$($cli status network --provider $provider --network $network)
    test=$(grep -c "Reading Latest Chaindata" <<<$statusNetwork)
    statusStakers=$($cli status stakers --provider $provider --network $network --staking-address $stakingAddress)
    test2=$(grep -c "$stakingAddress" <<<$statusStakers)
    if [[ "$test" != "0" && "$test2" != "0" ]]; then
        status=up
        ursula=$(ps aux | grep ursula | grep nucypher | grep $(whoami))
        if [ -z "$ursula" ]; then status=down; fi
        geth=$(ps aux | grep geth | grep $(whoami))
        if [ -z "$geth" ]; then status=down; fi
        clef=$(ps aux | grep clef | grep $(whoami))
        if [ -z "$clef" ]; then status=down; fi
        currentPeriod=$(grep -Po "Current Period ...........\s+\K[^ ^]+" <<<$statusNetwork)        # ; echo $currentPeriod
        activelyStakedTokens=$(grep -Po "Actively Staked Tokens ...\s+\K[^ ^]+" <<<$statusNetwork) # ; echo $activelyStakedTokens
        stakersPopulation=$(grep -Po "Stakers population .......\s+\K[^ ^]+" <<<$statusNetwork)    # ; echo $stakersPopulation
        confirmed=$(grep -Po "Confirmed .............\s+\K[^ ^]+" <<<$statusNetwork)               # ; echo $confirmed
        pendingConfirmation=$(grep -Po "Pending confirmation ..\s+\K[^ ^]+" <<<$statusNetwork)     # ; echo $pendingConfirmation
        inactive=$(grep -Po "Inactive ..............\s+\K[^ ^]+" <<<$statusNetwork)                # ; echo $inactive
        owned=$(grep -Po "Owned:\s+\K[^ ^]+" <<<$statusStakers)                                    # ; echo $owned
        stakedCurrent=$(grep -Po "Staked in current period:\s+\K[^ ^]+" <<<$statusStakers)         # ; echo $stakedCurrent
        stakedNext=$(grep -Po "Staked in next period:\s+\K[^ ^]+" <<<$statusStakers)               # ; echo $stakedNext
        activity=$(grep -Po "Activity:\s+\K[^ ^]+ [^ ^]+ [^ ^]+ [^ ^]+" <<<$statusStakers)         # ; echo $activity
        nextPeriod=$(grep -Po "\(#\K[0-9]+" <<<$activity)                                          # ; echo $nextPeriod
        test3=$(grep -c "period committed (#" <<<$activity)                                        # ; echo $test3
        if [[ "$test3" != "1" && "$status" != "down" ]]; then status=delinquent; fi
        worker=$(grep -Po "Worker:\s+\K[^ ^]+" <<<$statusStakers)                                                   # ; echo $worker                 # ; echo $worker
        workerETH=$(geth --exec "web3.eth.getBalance(\"$worker\")" attach)                                          # ; echo $workerETH
        workerETH=$(echo "scale=2 ; $workerETH / 1000000000000000000" | bc)                                         # ; echo $workerETH
        pctStakersConfirmed=$(echo "scale=2 ; 100 * ($confirmed + $pendingConfirmation) / $stakersPopulation" | bc) # ; echo $pctStakersConfirmed

        if [ $worklock == "on" ]; then
            worklockStatus=$($cli worklock status --provider $provider --network $network --participant-address $stakingAddress)
            lockedETH=$(grep -Po "Locked ETH .............\s+\K[^ ^]+" <<<$worklockStatus) #; echo $lockedETH
            lockedETH=$(echo "scale=2 ; $lockedETH / 1000000000000000000" | bc)
            completedWork=$(grep -Po "Completed Work .........\s+\K[^ ^]+" <<<$worklockStatus)   # ; echo $completedWork
            availableRefund=$(grep -Po "Available Refund .......\s+\K[^ ^]+" <<<$worklockStatus) # ; echo $availableRefund
            availableRefund=$(echo "scale=2 ; $availableRefund / 1000000000000000000" | bc)
            refundedWork=$(grep -Po "Refunded Work ..........\s+\K[^ ^]+" <<<$worklockStatus)                                               # ; echo $refundedWork
            remainingWork=$(grep -Po "Remaining Work .........\s+\K[^ ^]+" <<<$worklockStatus)                                              # ; echo $remainingWork
            pctWorkDone=$(echo "scale=2 ; 100 * ($completedWork + $refundedWork) / ($completedWork + $refundedWork + $remainingWork)" | bc) # ; echo $pctWorkDone
            worklockEntry="lockedETH=$lockedETH availableRefund=$availableRefund completedWork=$completedWork refundedWork=$refundedWork remainingWork=$remainingWork pctWorkDone=$pctWorkDone"
        fi

        now=$(date --rfc-3339=seconds)
        logentry="[$now] status=$status currentPeriod=$currentPeriod worker=$worker workerETH=$workerETH owned=$owned stakedCurrent=$stakedCurrent stakedNext=$stakedNext activelyStakedTokens=$activelyStakedTokens stakersPopulation=$stakersPopulation confirmed=$confirmed pendingConfirmation=$pendingConfirmation inactive=$inactive pctStakersConfirmed=$pctStakersConfirmed $worklockEntry"
        echo "$logentry" >>$logfile
    else
        now=$(date --rfc-3339=seconds)
        logentry="[$now] status=error"
        echo "$logentry" >>$logfile
    fi

    nloglines=$(wc -l <$logfile)
    if [ $nloglines -gt $logsize ]; then
        case $logmgmt in
        1)
            mv $logfile "${logfile}.1"
            touch $logfile
            ;;
        2)
            echo "$(cat $logfile)" >>${logfile}.1
            >$logfile
            ;;
        3)
            sed -i '1d' $logfile
            if [ -f ${logfile}.1 ]; then rm ${logfile}.1; fi # no log rotation with option (3)
            ;;
        *) ;;
        esac
    fi
    echo "$logentry"
    echo "sleep $sleep1"
    sleep $sleep1
done
