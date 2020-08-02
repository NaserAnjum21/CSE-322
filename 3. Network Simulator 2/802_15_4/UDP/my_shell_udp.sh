#cd /
#cd Documents
#cd NS
#cd My Folder
#cd itcp
#cd 802_11

#INPUT: output file AND number of iterations
output_file_format="udp";
us="_"
all="all"
iteration_float=5.0
start=5
end=5

num_nodes=20
num_flow=10
packet_per_sec=100
speed=5
coverage=1


iteration=$(printf %.0f $iteration_float);

echo -n > "$output_file_format$us$all.out"

r=$start

while [ $r -le $end ]
do
echo "total iteration: $iteration"
###############################START A ROUND
l=0;thr=0.0;del=0.0;s_packet=0.0;r_packet=0.0;d_packet=0.0;del_ratio=0.0;
dr_ratio=0.0;time=0.0;t_energy=0.0;energy_bit=0.0;energy_byte=0.0;energy_packet=0.0;total_retransmit=0.0;

i=0
while [ $i -lt $iteration ]
do
#################START AN ITERATION
echo "                             EXECUTING $(($i+1)) th ITERATION"

n=$(($num_nodes*($i+1)))
f=$(($num_flow*($i+1)))
pps=$(($packet_per_sec*($i+1)))
sp=$(($coverage*($i+1)))

ns udp_802_15_4_wireless_static.tcl $n $f $pps $sp
echo "SIMULATION COMPLETE. BUILDING STAT......"
#awk -f rule_th_del_enr_tcp.awk 802_11_grid_tcp_with_energy_random_traffic.tr > math_model1.out
awk -f my_awk_udp.awk trace_udp_wireless_static.tr > "$output_file_format$us$i.out"
echo -ne "For $i th iteration--- \n " >> "$output_file_format$us$all.out"
echo -ne "Node= $n, Flow= $f, PPS= $pps, Coverage=$sp \n " >> "$output_file_format$us$all.out"
while read val
do
#	l=$(($l+$inc))
	l=$(($l+1))

	output_file="$output_file_format$us$all.out"
	
#	echo -ne "Throughput:          $thr " > $output_file

	if [ "$l" == "1" ]; then
		thr=$(echo "scale=5; $thr+$val/$iteration_float" | bc)
		echo -ne "throughput: $val \n" >> $output_file
	elif [ "$l" == "2" ]; then
		del=$(echo "scale=5; $del+$val/$iteration_float" | bc)
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
		echo -ne "delivery ratio: $val \n" >> $output_file
	elif [ "$l" == "7" ]; then
		dr_ratio=$(echo "scale=5; $dr_ratio+$val/$iteration_float" | bc)
		echo -ne "drop ratio: $val \n" >> $output_file
	elif [ "$l" == "8" ]; then
		time=$(echo "scale=5; $time+$val/$iteration_float" | bc)
		echo -ne "time: $val \n" >> $output_file
	elif [ "$l" == "9" ]; then
		t_energy=$(echo "scale=5; $t_energy+$val/$iteration_float" | bc)
		echo -ne "total_energy: $val \n" >> $output_file
	elif [ "$l" == "10" ]; then
		energy_bit=$(echo "scale=5; $energy_bit+$val/$iteration_float" | bc)
		echo -ne "energy_per_bit: $val \n" >> $output_file
	elif [ "$l" == "11" ]; then
		energy_byte=$(echo "scale=5; $energy_byte+$val/$iteration_float" | bc)
		echo -ne "energy_per_byte: $val \n" >> $output_file
	elif [ "$l" == "12" ]; then
		energy_packet=$(echo "scale=5; $energy_packet+$val/$iteration_float" | bc)
		echo -ne "energy_per_packet: $val \n" >> $output_file
	elif [ "$l" == "13" ]; then
		total_retransmit=$(echo "scale=5; $total_retransmit+$val/$iteration_float" | bc)
		echo -ne "total_retrnsmit: $val \n\n\n" >> $output_file
	fi


	echo "$val"
done < "$output_file_format$us$i.out"

i=$(($i+1))
l=0
#################END AN ITERATION
done

output_file="$output_file_format$us$r.out"

echo -ne "Throughput:          $thr \n" > $output_file
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
echo "total_retransmit:         $total_retransmit \n" >> $output_file

r=$(($r+1))
#######################################END A ROUND
done