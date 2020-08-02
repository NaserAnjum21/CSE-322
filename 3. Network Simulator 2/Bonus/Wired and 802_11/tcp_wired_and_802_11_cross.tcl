## 1. Setting the values of parameters 

 # a. Set network size
set x_dim 500
set y_dim 500

 # b. Number of nodes
set total_nodes [lindex $argv 0] ;#20,40,60,80,100


 # c. Other attributes of flow
set time_duration 20 ;
set start_time 2 ;
set parallel_start_gap 1.0
set cross_start_gap 1.0

set num_parallel_flow 0
set num_cross_flow 0
set num_random_flow [lindex $argv 1]

 # d. Energy parameters
set val(energymodel_11)    EnergyModel     ;
set val(initialenergy_11)  1000            ;# Initial energy in Joules
set val(idlepower_11) 900e-3			;#Stargate (802.11b) 
set val(rxpower_11) 925e-3			;#Stargate (802.11b)
set val(txpower_11) 1425e-3			;#Stargate (802.11b)
set val(sleeppower_11) 300e-3			;#Stargate (802.11b)
set val(transitionpower_11) 200e-3		;#Stargate (802.11b)	??????????????????????????????/
set val(transitiontime_11) 3			;#Stargate (802.11b)


 # e. Protocols and models for different layers
set val(chan) Channel/WirelessChannel ;# channel type
set val(prop) Propagation/TwoRayGround ;# radio-propagation model
#set val(prop) Propagation/FreeSpace ;# radio-propagation model
set val(netif) Phy/WirelessPhy ;# network interface type
set val(mac) Mac/802_11 ;# MAC type
#set val(mac) SMac/802_15_4 ;# MAC type
set val(ifq) Queue/DropTail/PriQueue ;# interface queue type
set val(ll) LL ;# link layer type
set val(ant) Antenna/OmniAntenna ;# antenna model
set val(ifqlen) 50 ;# max packet in ifq
set val(rp) DSDV ;# routing protocol


 # f. Others
set packets_per_second [lindex $argv 2]
set cbr_size 500
set cbr_rate 11.0Mb
set cbr_interval [expr 1.0/$packets_per_second];# ?????? 1 for 1 packets per second and 0.1 for 10 packets per second

set extra_time 10

set num_mobile_nodes [expr $total_nodes* rand() * 0.4]
set mobile_speed [lindex $argv 3]
set motion_gap 1.0

set num_wired 2
set num_wireless 3

## 2. Initialize ns
set ns_ [new Simulator]


$ns_ node-config -addressType hierarchical
AddrParams set domain_num_ 2           ;# number of domains
lappend cluster_num 2 1                ;# number of clusters in each domain
AddrParams set cluster_num_ $cluster_num
lappend eilastlevel 1 1 4              ;# number of nodes in each cluster 
AddrParams set nodes_num_ $eilastlevel ;# of each domain


## 3. Open required files
set nm tcp_cross_trans.nam
set tr trace_tcp_cross_trans.tr
set topo_file topo_tcp_cross_trans.txt

set tracef [open $tr w]
$ns_ trace-all $tracef
#$ns_ use-newtrace ;# use the new wireless trace file format

set namtrf [open $nm w]
$ns_ namtrace-all-wireless $namtrf $x_dim $y_dim

set topof [open $topo_file w]

set topo [new Topography]
$topo load_flatgrid $x_dim $y_dim

create-god [expr $total_nodes ]

## 4. Set node configuration


## wired part

set arr {0.0.0 0.1.0}; # hierarchical addresses

for {set i 0} {$i < $num_wired} {incr i} {
    set w_($i) [$ns_ node [lindex $arr $i]] 
}



### base station part

$ns_ node-config -adhocRouting $val(rp) -llType $val(ll) \
     -macType $val(mac)  -ifqType $val(ifq) \
     -ifqLen $val(ifqlen) -antType $val(ant) \
     -propType $val(prop) -phyType $val(netif) \
     -channel  [new $val(chan)] -topoInstance $topo \
     -wiredRouting ON \
     -agentTrace ON -routerTrace OFF\
     -macTrace ON \
     -movementTrace OFF \
			 -energyModel $val(energymodel_11) \
			 -idlePower $val(idlepower_11) \
			 -rxPower $val(rxpower_11) \
			 -txPower $val(txpower_11) \
          		 -sleepPower $val(sleeppower_11) \
          		 -transitionPower $val(transitionpower_11) \
			 -transitionTime $val(transitiontime_11) \
			 -initialEnergy $val(initialenergy_11)


#          		 -transitionTime 0.005 \

set arr {1.0.0 1.0.1 1.0.2 1.0.3 1}

set bs [$ns_ node [lindex $arr 0]]
$bs random-motion 0

$bs set X_ 1.0
$bs set Y_ 2.0
$bs set Z_ 0.0

$ns_ node-config -wiredRouting OFF


for {set j 0} {$j < $num_wireless} {incr j} {
	set node_($j) [ $ns_ node [lindex $arr [expr $j+1]] ]
	$node_($j) base-station [AddrParams addr2id [$bs node-addr]]
}


puts "node creation complete"


## 6. Create flows and associate them with nodes


$ns_ duplex-link $w_(0) $w_(1) 5Mb 2ms DropTail
$ns_ duplex-link $w_(1) $bs 5Mb 2ms DropTail

$ns_ duplex-link-op $w_(0) $w_(1) orient down
$ns_ duplex-link-op $w_(1) $bs orient left-down

for {set i 0} {$i < [expr $num_wireless]  } { incr i} {
	$ns_ initial_node_pos $node_($i) 20
}

set rt 1

set tcp1 [new Agent/TCP]
$tcp1 set class_ 2
set sink1 [new Agent/TCPSink]
$ns_ attach-agent $node_(0) $tcp1
$ns_ attach-agent $w_(0) $sink1
$ns_ connect $tcp1 $sink1
set cbr_($rt) [new Application/Traffic/CBR]
$cbr_($rt) set packetSize_ $cbr_size
$cbr_($rt) set rate_ $cbr_rate
$cbr_($rt) set interval_ $cbr_interval
$cbr_($rt) attach-agent $tcp1

incr rt

set tcp2 [new Agent/TCP]
$tcp2 set class_ 2
set sink2 [new Agent/TCPSink]
$ns_ attach-agent $w_(1) $tcp2
$ns_ attach-agent $node_(2) $sink2
$ns_ connect $tcp2 $sink2
set cbr_($rt) [new Application/Traffic/CBR]
$cbr_($rt) set packetSize_ $cbr_size
$cbr_($rt) set rate_ $cbr_rate
$cbr_($rt) set interval_ $cbr_interval
$cbr_($rt) attach-agent $tcp2


set rt 1
for {set i 1} {$i <= [expr 2]} {incr i} {
	$ns_ at [expr $start_time] "$cbr_($rt) start"
	incr rt
}

puts "flow creation complete"



## 7. Set timings of different events
for {set i 0} {$i < [expr 3] } {incr i} {
    $ns_ at [expr $start_time+$time_duration] "$node_($i) reset";
}
$ns_ at [expr $start_time+$time_duration] "$bs reset";
$ns_ at [expr $start_time+$time_duration +$extra_time] "finish"
#$ns_ at [expr $start_time+$time_duration +20] "puts \"NS Exiting...\"; $ns_ halt"
$ns_ at [expr $start_time+$time_duration +$extra_time] "$ns_ nam-end-wireless [$ns_ now]; puts \"NS Exiting...\"; $ns_ halt"

$ns_ at [expr $start_time+$time_duration/2] "puts \"half of the simulation is finished\""
$ns_ at [expr $start_time+$time_duration] "puts \"end of simulation duration\""


## 8. Finish Procedure after simulation
proc finish {} {
	puts "finishing"
	global ns_ tracef namtrf topof nm
	$ns_ flush-trace
	close $tracef
	close $namtrf
	close $topof
    #exec nam $nm &
    exit 0
}

## 9. Run the simulation
puts "Starting Simulation..."
$ns_ run





