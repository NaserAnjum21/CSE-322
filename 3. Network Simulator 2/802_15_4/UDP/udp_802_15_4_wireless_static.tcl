## 1. Setting the values of parameters 

 # a. Set network size
set x_dim 200
set y_dim 200

 # b. Number of nodes
set total_nodes [lindex $argv 0] ;#20,40,60,80,100
set num_row [expr $total_nodes/10] ;#number of row
set num_col [expr $total_nodes/$num_row ] ;#number of column

 # c. Other attributes of flow
set time_duration 20 ;
set start_time 2 ;
set parallel_start_gap 1.0
set cross_start_gap 1.0

set num_parallel_flow 0
set num_cross_flow 0
set num_random_flow [lindex $argv 1]

 # d. Energy parameters
set val(energymodel_15_4)    EnergyModel     ;
set val(initialenergy_15_4)  1000            ;# Initial energy in Joules

set val(idlepower_15_4) 56.4e-3		;#LEAP	(active power in spec)
set val(rxpower_15_4) 59.1e-3			;#LEAP
set val(txpower_15_4) 52.2e-3			;#LEAP
set val(sleeppower_15_4) 0.6e-3		;#LEAP
set val(transitionpower_15_4) 35.708e-3		;#LEAP: 
set val(transitiontime_15_4) 2.4e-3		;#LEAP

 # e. Protocols and models for different layers
set val(chan) Channel/WirelessChannel ;# channel type
set val(prop) Propagation/TwoRayGround ;# radio-propagation model
#set val(prop) Propagation/FreeSpace ;# radio-propagation model
set val(netif) Phy/WirelessPhy/802_15_4 ;# network interface type
#set val(mac) Mac/802_11 ;# MAC type
set val(mac) Mac/802_15_4 ;# MAC type
set val(ifq) Queue/DropTail/PriQueue ;# interface queue type
set val(ll) LL ;# link layer type
set val(ant) Antenna/OmniAntenna ;# antenna model
set val(ifqlen) 50 ;# max packet in ifq
set val(rp) AODV ;# routing protocol

set dist(5m)  7.69113e-06
set dist(9m)  2.37381e-06
set dist(10m) 1.92278e-06
set dist(11m) 1.58908e-06
set dist(12m) 1.33527e-06
set dist(13m) 1.13774e-06
set dist(14m) 9.81011e-07
set dist(15m) 8.54570e-07
set dist(16m) 7.51087e-07
set dist(20m) 4.80696e-07
set dist(25m) 3.07645e-07
set dist(30m) 2.13643e-07
set dist(35m) 1.56962e-07
set dist(40m) 1.20174e-07

#set dist(40m) 1.56962e-10
#set dist(45m) 1.56962e-11
#set dist(50m) 1.20174e-13

set coverage [lindex $argv 3]
set d [expr 5*$coverage]
append dx $d m
puts $dx

Phy/WirelessPhy set CSThresh_ $dist($dx)
Phy/WirelessPhy set RXThresh_ $dist($dx)

 # f. Others
set packets_per_second [lindex $argv 2]
set cbr_size 64
set cbr_rate 11.0Mb
set cbr_interval [expr 1.0/$packets_per_second];# ?????? 1 for 1 packets per second and 0.1 for 10 packets per second

set extra_time 10

Mac/802_15_4 set syncFlag_ 1
Mac/802_15_4 set dutyCycle_ cbr_interval


## 2. Initialize ns
set ns_ [new Simulator]

## 3. Open required files
set nm udp_wireless_static.nam
set tr trace_udp_wireless_static.tr
set topo_file topo_udp_wireless_static.txt

set tracef [open $tr w]
$ns_ trace-all $tracef
#$ns_ use-newtrace ;# use the new wireless trace file format

set namtrf [open $nm w]
$ns_ namtrace-all-wireless $namtrf $x_dim $y_dim

set topof [open $topo_file w]

set topo [new Topography]
$topo load_flatgrid $x_dim $y_dim

create-god [expr $num_row * $num_col ]

## 4. Set node configuration
$ns_ node-config -adhocRouting $val(rp) -llType $val(ll) \
     -macType $val(mac)  -ifqType $val(ifq) \
     -ifqLen $val(ifqlen) -antType $val(ant) \
     -propType $val(prop) -phyType $val(netif) \
     -channel  [new $val(chan)] -topoInstance $topo \
     -agentTrace ON -routerTrace OFF\
     -macTrace ON \
     -movementTrace OFF \
			 -energyModel $val(energymodel_15_4) \
			 -idlePower $val(idlepower_15_4) \
			 -rxPower $val(rxpower_15_4) \
			 -txPower $val(txpower_15_4) \
          		 -sleepPower $val(sleeppower_15_4) \
          		 -transitionPower $val(transitionpower_15_4) \
			 -transitionTime $val(transitiontime_15_4) \
			 -initialEnergy $val(initialenergy_15_4)


#          		 -transitionTime 0.005 \

## 5. Create nodes with positioning
puts "start node creation"
for {set i 0} {$i < [expr $num_row*$num_col]} {incr i} {
	set node_($i) [$ns_ node]
	#$node_($i) random-motion 0
}

set grid 2

set x_start [expr $x_dim/($num_col*2)];
set y_start [expr $y_dim/($num_row*2)];
set i 0;
while {$i < $num_row } {
#in same column
    for {set j 0} {$j < $num_col } {incr j} {
#in same row
	set m [expr $i*$num_col+$j];
#	$node_($m) set X_ [expr $i*240];
#	$node_($m) set Y_ [expr $k*240+20.0];
#CHNG
	if {$grid == 1} {
		set x_pos [expr $x_start+$j*($x_dim/$num_col)];#grid settings
		set y_pos [expr $y_start+$i*($y_dim/$num_row)];#grid settings
	} else {
		set x_pos [expr int($x_dim*rand())] ;#random settings
		set y_pos [expr int($y_dim*rand())] ;#random settings
	}
	$node_($m) set X_ $x_pos;
	$node_($m) set Y_ $y_pos;
	$node_($m) set Z_ 0.0
#	puts "$m"
	puts -nonewline $topof "$m x: [$node_($m) set X_] y: [$node_($m) set Y_] \n"
    }
    incr i;
}; 

if {$grid == 1} {
	puts "GRID topology"
} else {
	puts "RANDOM topology"
}
puts "node creation complete"

for {set i 0} {$i < [expr $num_row*$num_col]  } { incr i} {
	$ns_ initial_node_pos $node_($i) 4
}


## 6. Create flows and associate them with nodes

if {$num_parallel_flow > $num_row} {
	set num_parallel_flow $num_row
}

#CHNG
if {$num_cross_flow > $num_col} {
	set num_cross_flow $num_col
}

for {set i 1} {$i <= [expr $num_parallel_flow + $num_cross_flow + $num_random_flow]} {incr i} {
#    set udp_($i) [new Agent/UDP]
#    set null_($i) [new Agent/Null]

	set udp_($i) [new Agent/UDP]
	$udp_($i) set class_ $i
	set null_($i) [new Agent/Null]
	$udp_($i) set fid_ $i
	if { [expr $i%2] == 0} {
		$ns_ color $i Blue
	} else {
		$ns_ color $i Red
	}
}

set k 1


#######################################################################RANDOM FLOW
set r $k
set rt $r
set num_node [expr $num_row*$num_col]
for {set i 1} {$i < [expr $num_random_flow+1]} {incr i} {
	set udp_node [expr int($num_node*rand())] ;# src node
	set null_node $udp_node
	while {$null_node==$udp_node} {
		set null_node [expr int($num_node*rand())] ;# dest node
	}
	$ns_ attach-agent $node_($udp_node) $udp_($rt)
  	$ns_ attach-agent $node_($null_node) $null_($rt)
	puts -nonewline $topof "RANDOM:  Src: $udp_node Dest: $null_node\n"
	incr rt
} 

set rt $r
for {set i 1} {$i < [expr $num_random_flow+1]} {incr i} {
	$ns_ connect $udp_($rt) $null_($rt)
	incr rt
}
set rt $r
for {set i 1} {$i < [expr $num_random_flow+1]} {incr i} {
	set cbr_($rt) [new Application/Traffic/CBR]
	$cbr_($rt) set packetSize_ $cbr_size
	$cbr_($rt) set rate_ $cbr_rate
	$cbr_($rt) set interval_ $cbr_interval
	$cbr_($rt) attach-agent $udp_($rt)
	incr rt
} 

set rt $r
for {set i 1} {$i < [expr $num_random_flow+1]} {incr i} {
	$ns_ at [expr $start_time] "$cbr_($rt) start"
	incr rt
}

puts "flow creation complete"


## 7. Set timings of different events
for {set i 0} {$i < [expr $num_row*$num_col] } {incr i} {
    $ns_ at [expr $start_time+$time_duration] "$node_($i) reset";
}
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





