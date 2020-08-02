#cd /
#cd Documents
#cd NS
#cd My Folder
#cd itcp
#cd 802_11

#INPUT: output file AND number of iterations
output_file_format="tcp";
variation="node"
us="_"
all="all"
iteration_float=20.0
start=5
end=5

num_nodes=20
num_flow=10
packet_per_sec=100
speed=5
coverage=1

avg="avg"
tracef="trace_tcp_wireless_mobile.tr"
tclf="tcp_802_11_wireless_mobile.tcl"
awkf="my_awk_tcp.awk"
graphfile="Graph1.out"
gdir="Graphs/"


iteration=$(printf %.0f $iteration_float);

echo -n "" > "$output_file_format$us$all.out"
echo -n "" > "$tracef"

for a in {0..3}
do
    graphfile="$gdir$a.out"
    echo -n "" > "$graphfile"
done



r=$start

while [ $r -le $end ]
do
echo "total iteration: $iteration"
###############################START A ROUND
l=0;thr=0.0;thrpn=0.0;del=0.0;s_packet=0.0;r_packet=0.0;d_packet=0.0;del_ratio=0.0;
dr_ratio=0.0;time=0.0;t_energy=0.0;energy_bit=0.0;energy_byte=0.0;energy_packet=0.0;total_retransmit=0.0;

thr_=0.0;del_=0.0;del_ratio_=0.0;dr_ratio_=0.0;t_energy_=0.0;energy_packet_=0.0;thrpn_=0.0;

i=0
j=0
while [ $i -lt $iteration ]
do
#################START AN ITERATION
echo "                             EXECUTING $(($i+1)) th ITERATION"

if [ $i -ge 0 -a $i -lt 5 ]; then
	n=$(($num_nodes*($i+1)))
else
	n=$num_nodes
fi

if [ $i -ge 5 -a $i -lt 10 ]; then
	f=$(($num_flow*($i-4)))
	variation="flow"
else
	f=$num_flow
fi

if [ $i -ge 10 -a $i -lt 15 ]; then
	pps=$(($packet_per_sec*($i-9)))
	variation="pps"
else
	pps=$packet_per_sec
fi

if [ $i -ge 15 -a $i -lt 20 ]; then
	sp=$(($speed*($i-14)))
	variation="speed"
else
	sp=$speed
fi


vall=1

echo > "$tracef"
#echo "Trace File Size "
#stat --printf="%s" $tracef

ns $tclf $n $f $pps $sp
echo "SIMULATION COMPLETE. BUILDING STAT......"
#awk -f rule_th_del_enr_tcp.awk 802_11_grid_tcp_with_energy_random_traffic.tr > math_model1.out

awk -f "$awkf" "$tracef" > "$output_file_format$us$variation$us$i.out"
echo -ne "\n\nFor $i th iteration--- \n " >> "$output_file_format$us$all.out"
echo -ne "Node= $n, Flow= $f, PPS= $pps, Speed=$sp \n " >> "$output_file_format$us$all.out"
while read val
do
#	l=$(($l+$inc))
	l=$(($l+1))

	output_file="$output_file_format$us$all.out"
	
#	echo -ne "Throughput:          $thr " > $output_file

	if [ "$l" == "1" ]; then
		vall=$(echo "scale=5; $val/$n" | bc)
		thr=$(echo "scale=5; $thr+$val/$iteration_float" | bc)
		thr_=$(echo "scale=5; $val" | bc)

		thrpn=$(echo "scale=5; $thrpn+$vall/$iteration_float" | bc)
		thrpn_=$(echo "scale=5; $vall" | bc)

		echo -ne "throughput: $val \n" >> $output_file
		echo -ne "per node throughput: $vall \n" >> $output_file
	elif [ "$l" == "2" ]; then
		del=$(echo "scale=5; $del+$val/$iteration_float" | bc)
		del_=$(echo "scale=5; $val" | bc)
		echo -ne "delay: $val \n" >> $output_file
	elif [ "$l" == "3" ]; then
		s_packet=$(echo "scale=5; $s_packet+$val/$iteration_float" | bc)
		echo -ne "send packet: $val \n" >> $output_file
	elif [ "$l" == "4" ]; then
		r_packet=$(echo "scale=5; $r_packet+$val/$iteration_float" | bc)
		echo -ne "received packet: $val \n" >> $output_file
	elif [ "$l" == "5" ]; then
		d_packet=$(echo "scale=5; $d_packet+$val/$iteration_float" | bc)
		echo -ne "drop packet: $val \n" >> $output_file
	elif [ "$l" == "6" ]; then
		del_ratio=$(echo "scale=5; $del_ratio+$val/$iteration_float" | bc)
		del_ratio_=$(echo "scale=5; $val" | bc)
		echo -ne "delivery ratio: $val \n" >> $output_file
	elif [ "$l" == "7" ]; then
		dr_ratio=$(echo "scale=5; $dr_ratio+$val/$iteration_float" | bc)
		dr_ratio_=$(echo "scale=5; $val" | bc)
		echo -ne "drop ratio: $val \n" >> $output_file
	elif [ "$l" == "8" ]; then
		time=$(echo "scale=5; $time+$val/$iteration_float" | bc)
		echo -ne "time: $val \n" >> $output_file
	elif [ "$l" == "9" ]; then
		t_energy=$(echo "scale=5; $t_energy+$val/$iteration_float" | bc)
		t_energy_=$(echo "scale=5; $val" | bc)
		echo -ne "total_energy: $val \n" >> $output_file
	elif [ "$l" == "10" ]; then
		energy_bit=$(echo "scale=5; $energy_bit+$val/$iteration_float" | bc)
		echo -ne "energy_per_bit: $val \n" >> $output_file
	elif [ "$l" == "11" ]; then
		energy_byte=$(echo "scale=5; $energy_byte+$val/$iteration_float" | bc)
		echo -ne "energy_per_byte: $val \n" >> $output_file
	elif [ "$l" == "12" ]; then
		energy_packet=$(echo "scale=5; $energy_packet+$val/$iteration_float" | bc)
		energy_packet_=$(echo "scale=5; $val" | bc)
		echo -ne "energy_per_packet: $val \n" >> $output_file
	elif [ "$l" == "13" ]; then
		total_retransmit=$(echo "scale=5; $total_retransmit+$val/$iteration_float" | bc)
		echo -ne "total_retrnsmit: $val \n" >> $output_file
	fi


	echo "$val"
done < "$output_file_format$us$variation$us$i.out"

idx=$(($i/5))

i=$(($i+1))
j=$(($j+1))

graphfile="$gdir$idx.out"

if [ $i -ge 1 -a $i -le 5 ]; then
	echo "$n $thr_ $del_ $del_ratio_ $dr_ratio_ $t_energy_ $energy_byte_ $thrpn_" >> $graphfile
fi

if [ $i -ge 6 -a $i -le 10 ]; then
	echo "$f $thr_ $del_ $del_ratio_ $dr_ratio_ $t_energy_ $energy_byte_ $thrpn_" >> $graphfile
fi

if [ $i -ge 11 -a $i -le 15 ]; then
	echo "$pps $thr_ $del_ $del_ratio_ $dr_ratio_ $t_energy_ $energy_byte_ $thrpn_" >> $graphfile
fi

if [ $i -ge 16 -a $i -le 20 ]; then
	echo "$sp $thr_ $del_ $del_ratio_ $dr_ratio_ $t_energy_ $energy_byte_ $thrpn_" >> $graphfile
fi


l=0

thr_=0.0;del_=0.0;del_ratio_=0.0;dr_ratio_=0.0;t_energy_=0.0;energy_packet_=0.0;thrpn_=0.0;

#################END AN ITERATION
done

output_file="$output_file_format$us$avg.out"

echo -ne "Throughput:          $thr \n" > $output_file
echo -ne "Per node Throughput:   $thrpn\n" >> $output_file
echo -ne "AverageDelay:         $del \n" >> $output_file
echo -ne "Sent Packets:         $s_packet \n" >> $output_file
echo -ne "Received Packets:         $r_packet \n" >> $output_file
echo -ne "Dropped Packets:         $d_packet \n" >> $output_file
echo -ne "PacketDeliveryRatio:      $del_ratio \n" >> $output_file
echo -ne "PacketDropRatio:      $dr_ratio \n" >> $output_file
echo -ne "Total time:  $time \n" >> $output_file
echo -ne "Total energy consumption:        $t_energy \n" >> $output_file
echo -ne "Average Energy per bit:         $energy_bit \n" >> $output_file
echo -ne "Average Energy per byte:         $energy_byte \n" >> $output_file
echo -ne "Average energy per packet:         $energy_packet \n" >> $output_file
echo -ne "Total_retransmit:         $total_retransmit \n" >> $output_file

r=$(($r+1))
#######################################END A ROUND
done

#graph making

var[0]="Node"
var[1]="Flow"
var[2]="Packers Per sec"
var[3]="Speed (m/s)"

metric[0]="Throughput"
metric[1]="End to End Delay"
metric[2]="Delivery Ratio"
metric[3]="Drop Ratio"
metric[4]="Total Energy"
metric[5]="Energy Per Packet"
metric[6]="Per Node Thr"

i=0
j=0
t=1

while [ $i -lt 4 ]
do
	k=$(($i+0))
	j=0
	graph="$gdir$k.out"
	picdir="Graphs/Pics/"
	while [ $j -lt 6 ]
	do
		temp=$(($j+2))
		pic_file="$picdir$t.png"
		gnuplot -persist -e "set title '802.11 mod : ${metric[j]} vs ${var[i]}'; set xlabel '${var[i]}'; set ylabel '${metric[j]}';  set terminal png size 800,600; set output '$pic_file'; plot '$graph' using 1:$temp with lines;"
		j=$(($j+1))
		t=$(($t+1))
	done
	i=$(($i+1))
done


