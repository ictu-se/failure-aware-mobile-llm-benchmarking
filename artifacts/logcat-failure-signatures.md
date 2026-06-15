# Logcat Failure Signature Mining

## Aggregate Hits

| Signature | Hits |
|---|---:|
| anr_timeout | 3047 |
| delegate_backend | 98247 |
| empty_output | 41976 |
| exception | 1314 |
| memory | 8524 |
| thermal | 22754 |

## Example Lines

### exception

- `20260528-235519-magicv5-litertlm-gemma4-main-medium-medium-r1: 05-29 01:27:45.922 24799 24819 E jyar    : java.lang.RuntimeException: ManagedChannel allocation site`
- `20260528-235519-magicv5-litertlm-gemma4-main-medium-medium-r1: 05-29 01:27:47.337 13947 18299 E hmpd    : RuntimeException while executing runnable hmps{apox@25ec294} with executor MoreExecutors.directExecutor()`
- `20260528-235519-magicv5-litertlm-gemma4-main-medium-medium-r2: 05-29 01:27:53.315  4784  4997 I WifiDftHandler: wifiSleepTime=485984 process wifi sleep exception: NcChipDftEvent{Id=909002092, Length=4, Flag=1}`
- `20260528-magicv5-litertlm-gemma4-batch-r1: 05-28 20:54:39.948  8485  8744 E MagicCubeIconUtils: java.lang.Exception`
- `20260528-magicv5-litertlm-gemma4-batch-r1: 05-28 20:54:39.948  8485  8775 E MagicCubeIconUtils: java.lang.Exception`
- `20260528-magicv5-litertlm-gemma4-batch-r1: 05-28 20:54:51.610  8485  8769 E MagicCubeIconUtils: java.lang.Exception`
- `20260528-magicv5-litertlm-gemma4-batch-r1: 05-28 20:54:51.615  8485  8759 E MagicCubeIconUtils: java.lang.Exception`
- `20260528-magicv5-litertlm-gemma4-batch-r2: 05-28 20:54:59.185  8485  8775 E MagicCubeIconUtils: java.lang.Exception`
- `20260528-magicv5-litertlm-gemma4-batch-r2: 05-28 20:54:59.186  8485  8744 E MagicCubeIconUtils: java.lang.Exception`
- `20260528-magicv5-litertlm-gemma4-batch-r2: 05-28 20:55:10.797  8485  8769 E MagicCubeIconUtils: java.lang.Exception`
- `20260528-magicv5-litertlm-gemma4-batch-r2: 05-28 20:55:10.798  8485  8759 E MagicCubeIconUtils: java.lang.Exception`
- `20260528-magicv5-litertlm-gemma4-long-long-r1: 05-28 23:02:35.717 29593 13744 E ccxg    : com.google.apps.dynamite.v1.shared.common.exception.AutoValue_SharedApiException: INTERNAL_STATE: FAILED_FROM_PREVIOUS_OR_BACKGROUND_SESSION`

### anr_timeout

- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:30.315  3246  3276 W ActivityTaskManager: Activity pause timeout for ActivityRecord{112445096 u0 com.example.qnn_litertlm_gemma/.BenchmarkActivity t15681}`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:30.412 19630 19665 I com.example.qnn_litertlm_gemma: vendor/qcom/proprietary/adsprpc/src/fastrpc_apps_user.c:3983: Created user PD on domain 3, dbg_trace 0x0, enabled attr=> RPC timeout:0, Dbg Mode:N, CRC:N, Unsigned:Y, Signed:N, Adapt QOS:N, PD du`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:30.470 19630 19665 I com.example.qnn_litertlm_gemma: vendor/qcom/proprietary/adsprpc/src/fastrpc_apps_user.c:2072: manage_poll_qos: poll mode updated to 3 for domain 3, handle 0xb400006da2fe0310 for timeout 9999`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:43.971  1269 19798 D strongbox_hn: close g_sbSession when timeout`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:04.601  3246  3276 W ActivityTaskManager: Activity pause timeout for ActivityRecord{94939650 u0 com.example.qnn_litertlm_gemma/.BenchmarkActivity t15682}`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:04.740 20058 20094 I com.example.qnn_litertlm_gemma: vendor/qcom/proprietary/adsprpc/src/fastrpc_apps_user.c:3983: Created user PD on domain 3, dbg_trace 0x0, enabled attr=> RPC timeout:0, Dbg Mode:N, CRC:N, Unsigned:Y, Signed:N, Adapt QOS:N, PD du`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:04.816 20058 20094 I com.example.qnn_litertlm_gemma: vendor/qcom/proprietary/adsprpc/src/fastrpc_apps_user.c:2072: manage_poll_qos: poll mode updated to 3 for domain 3, handle 0xb400006da301ed50 for timeout 9999`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:16.790  3246  4316 D HwConnectivityManagerImpl: sendIntentDnsEvent netId:711, mDnsCount:100, mDnsIpv6Timeout:0, mDnsResponseTotalTime:2281, mDnsFailCount:78, mDnsResponse20Count:14, mDnsResponse150Count:7, mDnsResponse500Count:0, mDnsResponse1000Co`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:32.116  4770  5123 I Booster_HighRatRecoveryProcessor[0]: processElevatorStatisticTimeOut`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r3: 05-29 01:29:38.978  3246  3276 W ActivityTaskManager: Activity pause timeout for ActivityRecord{154337073 u0 com.example.qnn_litertlm_gemma/.BenchmarkActivity t15683}`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r3: 05-29 01:29:39.145 20514 20551 I com.example.qnn_litertlm_gemma: vendor/qcom/proprietary/adsprpc/src/fastrpc_apps_user.c:3983: Created user PD on domain 3, dbg_trace 0x0, enabled attr=> RPC timeout:0, Dbg Mode:N, CRC:N, Unsigned:Y, Signed:N, Adapt QOS:N, PD du`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r3: 05-29 01:29:39.207 20514 20551 I com.example.qnn_litertlm_gemma: vendor/qcom/proprietary/adsprpc/src/fastrpc_apps_user.c:2072: manage_poll_qos: poll mode updated to 3 for domain 3, handle 0xb400006da2fd63d0 for timeout 9999`

### delegate_backend

- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.749  3246  7203 I PackageManager: com.example.qnn_litertlm_gemma , stopped by 1000`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.749  3246  7203 I ActivityManager: setPackageStoppedState, package:com.example.qnn_litertlm_gemma user:0 callingPackage:1000 CallingUid:1000 callingPid:19580`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.750  3246  7203 I ActivityManager: Force stopping com.example.qnn_litertlm_gemma appid=10352 user=0: from pid 19580by app`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.751  3246  7203 I ActivityManager: Killing 19238:com.example.qnn_litertlm_gemma/u0a352 (adj 900): stop com.example.qnn_litertlm_gemma due to from pid 19580by app`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.752  3246  7203 I HwActivityTaskManagerServiceEx: [activity restore] killed reason [com.example.qnn_litertlm_gemma] stop com.example.qnn_litertlm_gemma due to from pid 19580by app process name com.example.qnn_litertlm_gemma uid 10352`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.982  3246  4851 I PackageManager: com.example.qnn_litertlm_gemma , stopped by 1000`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.982  3246  4851 I ActivityManager: setPackageStoppedState, package:com.example.qnn_litertlm_gemma user:0 callingPackage:1000 CallingUid:1000 callingPid:20003`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.983  3246  4851 I ActivityManager: Force stopping com.example.qnn_litertlm_gemma appid=10352 user=0: from pid 20003by app`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.984  3246  4851 I ActivityManager: Killing 19630:com.example.qnn_litertlm_gemma/u0a352 (adj 900): stop com.example.qnn_litertlm_gemma due to from pid 20003by app`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.985  3246  4851 I HwActivityTaskManagerServiceEx: [activity restore] killed reason [com.example.qnn_litertlm_gemma] stop com.example.qnn_litertlm_gemma due to from pid 20003by app process name com.example.qnn_litertlm_gemma uid 10352`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r3: 05-29 01:29:38.364 20058 20085 I _litertlm_gemma: Explicit concurrent mark compact GC freed 256KB AllocSpace bytes, 2(40KB) LOS objects, 43% free, 2658KB/4706KB, paused 100us,1.833ms total 12.448ms`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r3: 05-29 01:29:38.372  3246  5395 I PackageManager: com.example.qnn_litertlm_gemma , stopped by 1000`

### memory

- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.760  3246  7203 I OomAdjuster: Set 13886 com.android.settings adj 905: cch-started-ui-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.760  3246  7203 I OomAdjuster: Set 12266 com.hihonor.health:DaemonService adj 905: cch-started-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.761  3246  7203 I OomAdjuster: Set 6839 com.hihonor.systemmanager:service adj 915: cch-started-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.761  3246  7203 I OomAdjuster: Set 20452 com.hihonor.detectrepair adj 945: cch-started-servicesstate.getSetAdj() :945state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.761  3246  7203 I OomAdjuster: Set 14057 com.hihonor.id adj 955: cch-emptystate.getSetAdj() :955state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.992  3246  4851 I OomAdjuster: Set 13886 com.android.settings adj 905: cch-started-ui-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.992  3246  4851 I OomAdjuster: Set 6839 com.hihonor.systemmanager:service adj 905: cch-started-servicesstate.getSetAdj() :915state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.992  3246  4851 I OomAdjuster: Set 12266 com.hihonor.health:DaemonService adj 905: cch-started-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.992  3246  4851 I OomAdjuster: Set 20452 com.hihonor.detectrepair adj 945: cch-started-servicesstate.getSetAdj() :945state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.992  3246  4851 I OomAdjuster: Set 14057 com.hihonor.id adj 955: cch-emptystate.getSetAdj() :955state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r3: 05-29 01:29:38.383  3246  5395 I OomAdjuster: Set 13886 com.android.settings adj 905: cch-started-ui-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r3: 05-29 01:29:38.383  3246  5395 I OomAdjuster: Set 6839 com.hihonor.systemmanager:service adj 905: cch-started-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`

### thermal

- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.818 19610 19610 W dumpsys : Thread Pool max thread count is 0. Cannot cache binder as linkToDeath cannot be implemented. serviceName: thermalservice`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.993  3246  7253 I BatteryService: Processing new values: info={chargerAcOnline=true,chargerUsbOnline=true,chargerWirelessOnline=false,maxChargingCurrent=3000000,maxChargingVoltage=5000000,batteryStatus=2=CHARGING,batteryHealth=2=GOOD,batteryPres`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:30.000  3246  7253 I BatteryService: Processing new values: info={chargerAcOnline=true,chargerUsbOnline=true,chargerWirelessOnline=false,maxChargingCurrent=3000000,maxChargingVoltage=5000000,batteryStatus=2=CHARGING,batteryHealth=2=GOOD,batteryPres`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:30.005  3246  7253 I BatteryService: Processing new values: info={chargerAcOnline=true,chargerUsbOnline=true,chargerWirelessOnline=false,maxChargingCurrent=3000000,maxChargingVoltage=5000000,batteryStatus=2=CHARGING,batteryHealth=2=GOOD,batteryPres`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:30.010  3246  7253 I BatteryService: Processing new values: info={chargerAcOnline=true,chargerUsbOnline=true,chargerWirelessOnline=false,maxChargingCurrent=3000000,maxChargingVoltage=5000000,batteryStatus=2=CHARGING,batteryHealth=2=GOOD,batteryPres`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.997 20004 20004 W dumpsys : Thread Pool max thread count is 0. Cannot cache binder as linkToDeath cannot be implemented. serviceName: thermalservice`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:04.250  4705  3952 I PGServer: getThermalInfo. calling pkg: com.hihonor.searchservice`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:04.250 18200 19898 I HnSearchService: [ForkJoinPool-1-worker-457]: PolicyService: temperature level: 1`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:04.250 18200 19898 I HnSearchService: [ForkJoinPool-1-worker-457]: DeviceStatusTrigger: trigger type: ChargeScreenBatteryTemperature, action: stop, params: {}`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:04.333  2531  4171 I ThermalDaemon:Shell    :: CalcShellTemp: shell[0] output exceed step range, use last temp subtract step range`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r3: 05-29 01:29:38.300  2531  4172 I ThermalDaemon:Report   :: [pa_0] tempNew :41  tempOld :40`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r3: 05-29 01:29:38.300  2531  4172 I ThermalDaemon:Report   :: [battery_0] tempNew :36  tempOld :35`

### empty_output

- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.760  3246  7203 I OomAdjuster: Set 13886 com.android.settings adj 905: cch-started-ui-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.760  3246  7203 I OomAdjuster: Set 12266 com.hihonor.health:DaemonService adj 905: cch-started-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.761  3246  7203 I OomAdjuster: Set 6839 com.hihonor.systemmanager:service adj 915: cch-started-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.761  3246  7203 I OomAdjuster: Set 20452 com.hihonor.detectrepair adj 945: cch-started-servicesstate.getSetAdj() :945state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r1: 05-29 01:28:29.761  3246  7203 I OomAdjuster: Set 14057 com.hihonor.id adj 955: cch-emptystate.getSetAdj() :955state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.992  3246  4851 I OomAdjuster: Set 13886 com.android.settings adj 905: cch-started-ui-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.992  3246  4851 I OomAdjuster: Set 6839 com.hihonor.systemmanager:service adj 905: cch-started-servicesstate.getSetAdj() :915state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.992  3246  4851 I OomAdjuster: Set 12266 com.hihonor.health:DaemonService adj 905: cch-started-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.992  3246  4851 I OomAdjuster: Set 20452 com.hihonor.detectrepair adj 945: cch-started-servicesstate.getSetAdj() :945state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r2: 05-29 01:29:03.992  3246  4851 I OomAdjuster: Set 14057 com.hihonor.id adj 955: cch-emptystate.getSetAdj() :955state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r3: 05-29 01:29:37.810  3246  4064 E HwResourcesImpl: processName is null`
- `20260528-235519-magicv5-litertlm-gemma4-main-long-long-r3: 05-29 01:29:38.383  3246  5395 I OomAdjuster: Set 13886 com.android.settings adj 905: cch-started-ui-servicesstate.getSetAdj() :905state.getAdjSource() :null reason :12 state.getCurProcState() :10 state.getSetProcState :10`
