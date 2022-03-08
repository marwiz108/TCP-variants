#!/usr/bin/env python3

#import os
from curses import meta
import sys
import csv
# constant

################################################################################################################
# function to read the input trace file as a 2D list format as follow
# [[ 0 event 1 time 2 fromnode 3 tonode 4 pkttype 5 pktsize 6 flags 7 fid 8 srcaddr 9 desaddr 10 seq# 11 pktid]]
################################################################################################################
def readfile(filename):
    # open the file with reading mode
    f = open(filename, "r")
    trace_list = []

    # store each line in trace file
    for line in f:
        #print(line)
        # split the line with space, and each line is a list
        line_list = line.split()
        # append to line list
        trace_list.append(line_list)
    
    #print(trace_list)
    # close the file
    f.close()
    # return 2D list
    return trace_list

################################################################################################################
# function to calculate the thoughput
# 1. Sum the size of receive event toNode at sinkNode with the asked flow id (one flow in exp1 and two in exp2)
# 2. Convert from bytes to bits (multiply the size by 8)
# 3. Divide the size in bits by the network path latency
# 4. Convert the result to megabits (divided the result from step 3 with 1024*1024 )
#################################################################################################################
def thoughput(trace, srcNode, sinkNode, fid):

    size_pkt_recv = 0
    pkt_count = 0 # used to record the start time

    start_time = 0
    end_time = 0

    # loop through the trace list
    for i in range(len(trace)):
        # if there is any rece event at sinkNode with asked flow id add the packet size up
        if trace[i][0] == 'r' and trace[i][3] == sinkNode and trace[i][7] == fid:
            size_pkt_recv = size_pkt_recv + float(trace[i][5])
            # if this is the first packet rece record the time as start time
            if pkt_count == 0:
                start_time = trace[i][1]
                pkt_count += 1
            # update the end time after the first recv
            ##############################################################
            # (should we record last time with ack instead of 'r' event?)
            else:
                end_time = trace[i][1]
                pkt_count += 1
        # also size up the total size with ack message to source node with asked flow id
        # every ack message is 40 bytes
        # added an event in case repeated multiple times
        elif trace[i][0] == 'r' and trace[i][3] == srcNode and trace[i][4] == 'ack' and trace[i][7] == fid:
            size_pkt_recv = size_pkt_recv + float(trace[i][5])
    
    # calculate the total time usage
    time_usage = float(end_time) - float(start_time)

    # convert units from byte to bits and Mb and finally divided by path latency
    size_pkt_recv = size_pkt_recv * 8
    size_pkt_recv = size_pkt_recv / ( 1024 * 1024 )
    
    # No time usage: No packet sent
    if (time_usage != 0):
        thoughput_res = size_pkt_recv / time_usage
    else:
        thoughput_res = 0
    
    # return the final result
    return thoughput_res

#####################################################################################################
# function to calculate the drop rate
# 1. counting drop event of the package with tcp protocol 
# 2. counting the sent event of the package from source node
# 3. drop rate = num of drop packet/ num of packet sent
######################################################################################################
def pktDrop(trace,srcNode,fid):
    pkt_drop = 0
    pkt_sent = 0

    # loop through the list
    for i in range(len(trace)):
        # counter for packet drop
        if trace[i][4] == 'tcp' and trace[i][0] == 'd' and trace[i][7] == fid:
            pkt_drop += 1
        # counter for packet sent from source node
        if trace[i][4] == 'tcp' and trace[i][0] == '-' and trace[i][2] == srcNode and trace[i][7] == fid:
            pkt_sent += 1
    
    # No packet sent: No packet sent
    if (pkt_sent != 0):
        drop_rate = float(pkt_drop) / float(pkt_sent)
    else:
        drop_rate = 0
    
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

    # No rtt: No packet sent
    if (num_rtt != 0):
        latency = sum_latency / num_rtt
    else:
        latency = 0

    return latency

def get_meta_trace(TRACE_FILE):
    # exp2 Vegas Vegas 9Mb 4.0 1.0.tr
    meta_data = TRACE_FILE.split('/')[-1].split('_')
    tcp_variant1, tcp_variant2 = meta_data[1], meta_data[2]
    cbr_flow = meta_data[3][: -2]
    tcp1_st = meta_data[4]
    tcp2_st = meta_data[5][: -3]

    return tcp_variant1, tcp_variant2, cbr_flow, tcp1_st, tcp2_st


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
    trace = readfile(TRACE_FILE)

    # if the trace files are result for experiment 1
    if OPTION == "exp1":
        # drop_rate (trace_list, source node, flow id)
        drop_rate = pktDrop(trace,'0','2')
        # thoughput(trace_list, source node, sink node, flow id)
        thoughput_res = thoughput(trace, '0', '3', '2')
        # EtoELatency(trace, srcNode, fid)
        latency = EtoELatency(trace,'0', '2')

        # write the data into csv file
        with open(RES_FILE, 'a+', newline='') as file:
            writer = csv.writer(file)
            tcp_variant, cbr_flow = get_meta_trace(TRACE_FILE)
            writer.writerow([tcp_variant, cbr_flow, thoughput_res, drop_rate, latency])

    elif OPTION == "exp2":
        # first TCP (source node = 0, flow id = 2)
        # second TCP (source node = 4, flow id = 3)
        drop_rate1 = pktDrop(trace,'0','2')
        drop_rate2 = pktDrop(trace,'4','3')

        thoughput_res1 = thoughput(trace, '0', '3', '2')
        thoughput_res2 = thoughput(trace, '4', '5', '3')

        latency1 = EtoELatency(trace,'0', '2')
        latency2 = EtoELatency(trace,'4', '3')

        # write the data into csv file
        with open(RES_FILE, 'a+', newline='') as file:
            writer = csv.writer(file)
            tcp_variant1, tcp_variant2, cbr_flow, tcp1_st, tcp2_st = get_meta_trace(TRACE_FILE)
            writer.writerow([tcp_variant1, tcp1_st, thoughput_res1, drop_rate1, latency1, tcp_variant2, tcp2_st, thoughput_res2, drop_rate2, latency2, cbr_flow])

    elif OPTION == "exp3":
        # for exp3 we only care about latency and throughput verse time
        rtts = {}
        tp_sec = {} # key = sec value = throughput at the time
        # overall end to end latency
        EtoELatency(trace,'0', '2')

        for i in range(len(trace)):
            # event == recv
            if trace[i][0] == 'r':
                # flow id
                if trace[i][7] == '2':
                    # ack recv at source node
                    if trace[i][4] == 'ack' and trace[i][3] == '0':
                        tp_sec[trace[i][1]] += trace[i][5]
                    # tcp rece at sink node
                    elif trace[i][4] == 'tcp' and trace[i][3] == '3':
                        tp_sec[trace[i][1]] += trace[i][5]
                
            # calculating... per 1 second?
            final_dic = {}
            for sec in tp_sec:
                # count the time (time interval)
                count = 1
                if sec <= count:
                    thoughput_at_sec = tp_sec[sec] * 8 / (1024*1024) / 1.0
                    final_dic[count] += thoughput_at_sec
                else:
                    count += 1

            with open(RES_FILE, 'a+', newline='') as file:
                for sec in final_dic:
                    writer = csv.writer(file)
                    writer.writerow([sec, final_dic[sec]])
    else:
        print("wrong option for parser")

main()