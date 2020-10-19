# nmonnucypher

pseudo-rpc data aggregation of Nucypher node data for the purpose of monitoring. Creates Logs that look like

```
[2020-10-19 07:45:05+00:00] status=up currentPeriod=18554 worker=0xxxxxxxxxxxxxxxxxxxxxxxxxx workerETH=.17 owned=467381.44 stakedCurrent=467381.44 stakedNext=467381.44 activelyStakedTokens=477110777.295143170401521649 stakersPopulation=1715 confirmed=1608 pendingConfirmation=21 inactive=86 pctStakersConfirmed=94.98 lockedETH=768.34 availableRefund=0 completedWork=9 refundedWork=2206895511230564990117 remainingWork=55939921966221186859930 pctWorkDone=3.79
[2020-10-19 07:46:02+00:00] status=up currentPeriod=18554 worker=0xxxxxxxxxxxxxxxxxxxxxxxxxx workerETH=.17 owned=467381.44 stakedCurrent=467381.44 stakedNext=467381.44 activelyStakedTokens=477110777.295143170401521649 stakersPopulation=1715 confirmed=1608 pendingConfirmation=21 inactive=86 pctStakersConfirmed=94.98 lockedETH=768.34 availableRefund=0 completedWork=9 refundedWork=2206895511230564990117 remainingWork=55939921966221186859930 pctWorkDone=3.79
[2020-10-19 07:46:57+00:00] status=up currentPeriod=18554 worker=0xxxxxxxxxxxxxxxxxxxxxxxxxx workerETH=.17 owned=467381.44 stakedCurrent=467381.44 stakedNext=467381.44 activelyStakedTokens=477110777.295143170401521649 stakersPopulation=1715 confirmed=1608 pendingConfirmation=21 inactive=86 pctStakersConfirmed=94.98 lockedETH=768.34 availableRefund=0 completedWork=9 refundedWork=2206895511230564990117 remainingWork=55939921966221186859930 pctWorkDone=3.79
```

status: up | down | delinquent | error
