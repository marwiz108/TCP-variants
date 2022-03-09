import sys, csv


def parameter_calculation(trace_records):
    # Flow ID 2 [TCP 1]
    received_packet_size_1, sent_packets_1, dropped_packets_1 = 0, 0, 0
    # Flow ID 3 [TCP 2]
    received_packet_size_2, sent_packets_2, dropped_packets_2 = 0, 0, 0
    # Field to keep track of number of packets received to record the start and end time for throughput
    packet_count_1, packet_count_2 = 0, 0

    # Fields to calculate round trip time
    packet_time_1, packet_time_2 = {}, {}

    # Track of the time of first and last packets for throughput calculation
    start_time_tcp_1, start_time_tcp_2, end_time = 0.0, 0.0, 0.0

    # Fields for calculation of latency
    total_delay_1, total_delay_2 = 0.0, 0.0

    for record in trace_records:
        event, time, from_node, to_node, packet_type, packet_size, flags, flow_id, src_addr, dest_addr, seq_num, packet_id = record.split()

        # Calculate number of packets received for Throughput parameter calculation
        if (event == 'r' and packet_type == 'ack'):
            if (to_node == '0' and flow_id == '2'):
                # Received packet is the first one
                if (packet_count_1 == 0):
                    start_time_tcp_1 = float(time)

                packet_count_1 += 1
                received_packet_size_1 += float(packet_size)
                delay = float(time) - packet_time_1[seq_num]
                total_delay_1 += delay

            if (to_node == '4' and flow_id == '3'):
                # Received packet is the first one
                if (packet_count_2 == 0):
                    start_time_tcp_2 = float(time)

                packet_count_2 += 1
                received_packet_size_2 += float(packet_size)
                delay = float(time) - packet_time_2[seq_num]
                total_delay_2 += delay

        # Calculate number of packets dropped for Drop Rate parameter calculation
        if (event == 'd' and packet_type == 'tcp'):
            # Packet dropped for first TCP connection
            if (flow_id == '2'):
                dropped_packets_1 += 1

            # Packet dropped for second TCP connection
            if (flow_id == '3'):
                dropped_packets_2 += 1

        # Calculate number of packets sent for Drop Rate and Latency parameter calculation
        # Save sending time of each seq_num in a dictionary to measure RTT of ack packet
        if (event == '-' and packet_type == 'tcp'):
            # From Node 1 (fid_ 2)
            if (from_node == '0' and flow_id == '2'):
                sent_packets_1 += 1
                # Update time of packet seq_num
                packet_time_1[seq_num] = float(time)

            # From Node 5 (fid_ 3)
            if (from_node == '4' and flow_id == '3'):
                sent_packets_2 += 1
                # Update time of packet seq_num
                packet_time_2[seq_num] = float(time)

    # Parameter Calculation
    # Throughput (in Mbps) - x8 (Bytes to bits)
    throughput_1 = ((received_packet_size_1 * 8) / (end_time - start_time_tcp_1)) / (1024 * 1024)
    throughput_2 = ((received_packet_size_2 * 8) / (end_time - start_time_tcp_2)) / (1024 * 1024)

    # Drop rate (0 ... 1)
    drop_rate_1 = float(dropped_packets_1) / sent_packets_1
    drop_rate_2 = float(dropped_packets_2) / sent_packets_2

    # Latency (in seconds)
    latency_1 = total_delay_1 / packet_count_1
    latency_2 = total_delay_2 / packet_count_2

    return throughput_1, drop_rate_1, latency_1, throughput_2, drop_rate_2, latency_2

# Method to read the input trace file
def readfile(filename):
    # open the file with reading mode
    f = open(filename, "r")
    trace_records = []

    # store each line in trace file
    for line in f:
        # append to trace records
        trace_records.append(line)
    
    # close the file
    f.close()
    # return trace records
    return trace_records

# Method to get CSV columns from trace file name for Exp 2
def get_meta_trace(TRACE_FILE):
    # exp2 Vegas Vegas 9Mb 4.0 1.0.tr
    meta_data = TRACE_FILE.split('/')[-1].split('_')
    tcp_variant1, tcp_variant2 = meta_data[1], meta_data[2]
    cbr_flow = meta_data[3][: -2]
    tcp1_st = meta_data[4]
    tcp2_st = meta_data[5][: -3]

    return tcp_variant1, tcp_variant2, cbr_flow, tcp1_st, tcp2_st

# main function
# program usage: python3 exp# trace_filename output_filename
def main():
    # command option for exp1 exp2 and exp3
    OPTION = sys.argv[1]
    TRACE_FILE = sys.argv[2] # trace file read in
    RES_FILE = sys.argv[3] # csv file out

    # read file 
    trace_records = readfile(TRACE_FILE)

    if OPTION == "exp2":
        throughput_1, drop_rate_1, latency_1, throughput_2, drop_rate_2, latency_2 = parameter_calculation(trace_records)

        # write the data into csv file
        with open(RES_FILE, 'a+', newline='') as file:
            writer = csv.writer(file)
            tcp_variant1, tcp_variant2, cbr_flow, tcp1_st, tcp2_st = get_meta_trace(TRACE_FILE)
            writer.writerow([tcp_variant1, tcp1_st, throughput_1, drop_rate_1, latency_1, tcp_variant2, tcp2_st, throughput_2, drop_rate_2, latency_2, cbr_flow])
    
    else:
        print("wrong option for parser")

main()