#!/usr/bin/env python3

import os, sys, csv


""" Helper function to read input trace file as a 2D list format as follows:
[[ 0: event, 1: time, 2: from_node, 3: to_node, 4: packet_type, 5: packet_size, 6: flags, 7: flow_id, 8: src_addr, 9: dest_addr, 10: seq_num, 11: packet_id], ....]
"""
def read_file(filename):
    # Open the file with reading mode
    trace_file = open(filename, "r")
    trace_list = []

    # Store each line in trace file
    for line in trace_file:
        # split the lines with space delimiter, and each line is a list (trace data in above format)
        line_list = line.split()
        # append to line list
        trace_list.append(line_list)
    
    # Close file
    trace_file.close()

    # Return list of trace records (2-dimensional)
    return trace_list

""" Helper function to calculate the thoughput
1. Calculate the size of receive event toNode at sinkNode with the asked flow id (one flow in exp1 and two in exp2)
2. Convert from bytes to bits (multiply the size by 8)
3. Divide the size in bits by the network path latency
4. Convert the result to megabits (divided the result from step 3 with 1024 * 1024)
"""
def thoughput(trace_records, src_node, sink_node, flow_id):
    size_pkt_recv = 0
    pkt_count = 0 
    
    # record the start time of first packet
    start_time = 0
    end_time = 0

    # loop through the trace records
    for i in range(len(trace_records)):
        # PACKETS RECEIVED (ACKs) back to TCP Source node (N1)
        # size up the total size with ack message to source node with asked flow id
        # every ack message is 40 bytes
        if (trace_records[i][0] == 'r' and trace_records[i][4] == 'ack' and trace_records[i][3] == src_node and trace_records[i][7] == flow_id):
            size_pkt_recv = size_pkt_recv + float(trace_records[i][5])
            
            # if this is the first packet received, record the time as start time
            if pkt_count == 0:
                start_time = trace_records[i][1]
            
            # record the end time of the last packet
            # (should we record last time with ack instead of 'r' event?)
            else:
                end_time = trace_records[i][1]

            pkt_count += 1
    
    # calculate the total time usage
    time_usage = float(end_time) - float(start_time)

    # convert units from byte to bits and Mb and finally divided by path latency
    size_pkt_recv = size_pkt_recv * 8
    size_pkt_recv = size_pkt_recv / (1024 * 1024)
    thoughput_res = size_pkt_recv / time_usage
    
    # return the final result
    return thoughput_res

""" Helper function to calculate the drop rate
1. Counting drop event of the package with tcp protocol 
2. Counting the sent event of the package from source node
3. drop rate = num of drop packet / num of packet sent
"""
def packet_drop_rate(trace,srcNode):
    pkt_drop = 0
    pkt_sent = 0

    # loop through the list
    for i in range(len(trace)):

        # counter for packet drop
        if trace[i][4] == 'tcp' and trace[i][0] == 'd':
            pkt_drop += 1
        # counter for packet sent from source node
        if trace[i][4] == 'tcp' and trace[i][0] == '-' and trace[i][2] == srcNode:
            pkt_sent += 1
    
    # calculating the drop rate
    drop_rate = float(pkt_drop) / float(pkt_sent)
    
    #print(pkt_drop, pkt_sent)
    
    # return the final result
    return float(drop_rate)

#########################################################################################################
# function to calculate the end to end latency
# 1. loop through the trace list to store the begin time and end time for each pkt with dic
# 2. sum up the time usage
# 3. divide the time by number of rtts to get the average latency
##########################################################################################################
def EtoELatency(trace,srcNode,fid):
    
    # set a dictionary for round trip delay
    rtts = {}

    # loop through the trace list
    for i in range(len(trace)):
        # record the enqueue time as value[0] and the pkt sequence number as the key with a dic data structure
        if trace[i][0] == '+' and trace[i][2] == srcNode and trace[i][4] == 'tcp' and trace[i][7] == fid :
            if trace[i][10] not in rtts:
                #{key = seq#, value = [enqueue time, recv time]}
                rtts[trace[i][10]] = [float(trace[i][1]), 0]
        # record the time when 'r' event happened at source node with 'ack' protocol as end time
        elif trace[i][0] == 'r' and trace[i][3] == srcNode and trace[i][4] == 'ack' and trace[i][7] == fid :
            rtts[trace[i][10]][1] = float(trace[i][1])
    
    sum_latency = 0
    num_rtt = 0
    invalid_rtt = 0 # there might be invalid rtt if the packet is dropped ?

    # loop through the dic to get total time usage also count the number of invalid rtts
    for rtt in rtts:
        if rtts[rtt][1] != 0:
            delay = float(rtts[rtt][1]) - float(rtts[rtt][0])
            sum_latency = sum_latency + delay
        else:
            invalid_rtt += 1

    num_rtt = len(rtts) - invalid_rtt

    latency = sum_latency / num_rtt

    return latency

###########################################################################################################
# main function
# program usage: python3 exp# trace_filename output_filename
def main():
    # command option for exp1 exp2 and exp3
    OPTION = sys.argv[1]
    TRACE_FILE = sys.argv[2] # trace file read in
    RES_FILE = sys.argv[3] # csv file out

    #print("parsing file " + str(TRACE_FILE) + "\n" )
    # read file 
    trace = read_file(TRACE_FILE)

    # if the trace files are result for experiment 1
    if OPTION == "exp1":
        
        # drop_rate (trace_list, source node)
        drop_rate = packet_drop_rate(trace,'0')
        # thoughput(trace_list, source node, sink node, flow id)
        thoughput_res = thoughput(trace, '0', '3', '2')
        # EtoELatency(trace, srcNode, fid)
        latency = EtoELatency(trace,'0', '2')

        # write the data into csv file
        with open(RES_FILE, 'a+', newline='') as file:
            writer = csv.writer(file)
            writer.writerow([TRACE_FILE,thoughput_res,drop_rate,latency])

    elif OPTION == "exp2":
        print("exp2")
    elif OPTION == "exp3":
        print("exp3")
    else:
        print("wrong option for parser")
        
    #print("throughput for " + str(TRACE_FILE) + " is " + str(thoughput_res) + "\n")
    #print("drop rate for " + str(TRACE_FILE) +  " is " + str(drop_rate) + "\n")
    #print("average end to end latency for " + str(TRACE_FILE) +  " is " + str(latency) + "\n")

main()