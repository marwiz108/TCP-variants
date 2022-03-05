import os
import sys

# constant
TRACE_FILE = ""
# seperate from parser and analysis / different experiment different script
#OPTION = "" 


def readfile(filename):
    f = open(filename, "r")
    trace_list = []
    for line in f:
        #print(line)
        line_list = line.split()
        trace_list.append(line_list)
    
    #print(trace_list)
    f.close()
    # 2D list
    # [[ 0 event 1 time 2 fromnode 3 tonode 4 pkttype 5 pktsize 6 flags 7 fid 8 srcaddr 9 desaddr 10 seq# 11 pktid]]
    return trace_list

def thoughput(trace, srcNode, sinkNode, fid):
    size_pkt_recv = 0
    pkt_count = 0

    start_time = 0
    end_time = 0

    for i in range(len(trace)):
        if trace[i][0] == 'r' and trace[i][3] == sinkNode and trace[i][7] == fid:
            size_pkt_recv = size_pkt_recv + float(trace[i][5])
            if pkt_count == 0:
                start_time = trace[i][1]
                pkt_count += 1
            else:
                end_time = trace[i][1]
                pkt_count += 1
        elif trace[i][3] == srcNode and trace[i][4] == 'ack' and trace[i][7] == fid:
            size_pkt_recv = size_pkt_recv + float(trace[i][5])
    
    time_usage = float(end_time) - float(start_time)

    size_pkt_recv = size_pkt_recv * 8
    size_pkt_recv = size_pkt_recv / ( 1024 * 1024 )
    thoughput_res = size_pkt_recv / time_usage
    
    return thoughput_res


def pktDrop(trace, fid):
    
    pkt_drop = 0
    pkt_id = []

    for i in range(len(trace)):

        if trace[i][4] == 'tcp' and trace[i][0] == 'd' and trace[i][7] == fid:
            pkt_drop += 1
        if trace[i][11] not in pkt_id:
            pkt_id.append( trace[i][11] )
    
    pkt_sent = len(pkt_id)
    drop_rate = pkt_drop / pkt_sent
    
    #print(pkt_drop, pkt_sent)
    
    return drop_rate

def EtoELatency(trace,srcNode,sinkNode,fid):
    rtts = {}
    pkt_id = []
    for i in range(len(trace)):
        
        if trace[i][0] == '+' and trace[i][2] == srcNode and trace[i][4] == 'tcp' and trace[i][7] == fid :
            if trace[i][10] not in rtts:
                rtts[trace[i][10]] = [float(trace[i][1]), 0]
        elif trace[i][0] == 'r' and trace[i][3] == srcNode and trace[i][4] == 'ack' and trace[i][7] == fid :
            rtts[trace[i][10]][1] = float(trace[i][1])
    
    sum_latency = 0
    num_rtt = 0
    invalid_rtt = 0

    for rtt in rtts:
        if rtts[rtt][1] != 0:
            delay = float(rtts[rtt][1]) - float(rtts[rtt][0])
            sum_latency = sum_latency + delay
        else:
            invalid_rtt += 1

    num_rtt = len(rtts.items()) - invalid_rtt

    latency = sum_latency / num_rtt

    return latency


def main():

    TRACE_FILE = sys.argv[1]
    trace = readfile(TRACE_FILE)

    drop_rate = pktDrop(trace, '2')
    thoughput_res = thoughput(trace, '0', '4', '2')
    latency = EtoELatency(trace,'0','4', '2')

    print("throughput for " + str(TRACE_FILE) + " is " + str(thoughput_res) + "\n")
    print("drop rate for " + str(TRACE_FILE) +  " is " + str(drop_rate) + "\n")
    print("average end to end latency for " + str(TRACE_FILE) +  " is " + str(latency) + "\n")

main()