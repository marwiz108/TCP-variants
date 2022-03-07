set ns [new Simulator]

# Retrieve simulation parameters from shell command line
# 1. The pair of TCP Variants
set tcp_variant1 [lindex $argv 0]
set tcp_variant2 [lindex $argv 1]

# 2. The CBR flow
set cbr_flow [lindex $argv 2]Mb

# 3. The TCP Start time
set tcp_start_time [lindex $argv 3]


# Setup the output file name
set trace_file_name exp2_
# TCP/... TCP/...
append trace_file_name [lindex [split $tcp_variant1 /] 1] _ [lindex [split $tcp_variant2 /] 1]
append trace_file_name _$cbr_flow.tr

# Console log message
puts "$trace_file_name, TCP Variant 1: $tcp_variant1, TCP Variant 2: $tcp_variant2, CBR Flow: $cbr_flow"


# Open simulation trace file
set nf [open trace_data/$trace_file_name w]
$ns trace-all $nf

# 'finish' procedure definition
proc finish {} {
    global ns nf
    $ns flush-trace
    # Close the trace file
    close $nf
    exit 0
}


#
# Create a simple six node topology:
#
#        N1(TCP1, FTP1)  N4(TCP Sink1)
#         \              /
# 10Mb,12ms\  10Mb,12ms / 10Mb,12ms
#           N2(CBR) --- N3(UDP Sink)
# 10Mb,12ms/            \ 10Mb,12ms
#         /              \
#        N5(TCP2, FTP2)  N6(TCP Sink2)
#

# Setting up 6 nodes as part of the network blueprint
# TCP Source 1
set N1 [$ns node]
# TCP Source 2
set N5 [$ns node]
# CBR Source - Bottleneck Cap: 10Mbps
set N2 [$ns node]
# UDP Sink - Null
set N3 [$ns node]
# TCP Sink 1
set N4 [$ns node]
# TCP Sink 2
set N6 [$ns node]


# Create network links. Default queueing mechanism (Droptail)
$ns duplex-link $N1 $N2 10Mb 12ms DropTail 
$ns duplex-link $N5 $N2 10Mb 12ms DropTail 
$ns duplex-link $N2 $N3 10Mb 12ms DropTail 
$ns duplex-link $N4 $N3 10Mb 12ms DropTail 
$ns duplex-link $N6 $N3 10Mb 12ms DropTail 

# Set queue limit between nodes N2 and N3
$ns queue-limit $N2 $N3 50 


# UDP-CBR Connection
# Setup a UDP connection for CBR flow at N2
set udp [new Agent/UDP]
$ns attach-agent $N2 $udp

# Setup CBR over UDP at N2
set cbr_stream [new Application/Traffic/CBR]
$cbr_stream set rate_ $cbr_flow
$cbr_stream set type_ CBR
$cbr_stream set random_ false
$cbr_stream attach-agent $udp

# Setup Sink at N3
set cbr_sink [new Agent/Null]
$ns attach-agent $N3 $cbr_sink


# TCP-FTP Connection 1
# Setup the first TCP connection from N1 to N4
set tcp_var1 [new Agent/$tcp_variant1]
$ns attach-agent $N1 $tcp_var1
$tcp_var1 set window_ 100

# Setup FTP application at N4 for data stream
set ftp_stream_var1 [new Application/FTP]
$ftp_stream_var1 attach-agent $tcp_var1

# Setup TCP Sink at N4
set tcp_sink_var1 [new Agent/TCPSink]
$ns attach-agent $N4 $tcp_sink_var1


# TCP-FTP Connection 2
# Setup the second TCP connection from N5 to N6
set tcp_var2 [new Agent/$tcp_variant2]
$ns attach-agent $N5 $tcp_var2
$tcp_var2 set window_ 100

# Setup FTP application at N5 for data stream
set ftp_stream_var2 [new Application/FTP]
$ftp_stream_var2 attach-agent $tcp_var2

# Setup TCP Sink at N6
set tcp_sink_var2 [new Agent/TCPSink]
$ns attach-agent $N6 $tcp_sink_var2


# Make connections
# UDP - From N2 to N3
$ns connect $udp $cbr_sink
$udp set fid_ 1
# TCP 1 - From N1 to N4
$ns connect $tcp_var1 $tcp_sink_var1
$tcp_var1 set fid_ 2
# TCP 2 - From N5 to N6
$ns connect $tcp_var2 $tcp_sink_var2
$tcp_var2 set fid_ 3


# Event schedule for TCP and UDP connections
# Starting CBR at 2.0s
$ns at 2.0 "$cbr_stream start"
# Starting TCP variant pairs before and when CBR starts (stabalization check)
$ns at $tcp_start_time "$ftp_stream_var1 start"
$ns at $tcp_start_time "$ftp_stream_var2 start"

$ns at 10.0 "$cbr_stream stop"
$ns at 10.0 "$ftp_stream_var1 stop"
$ns at 10.0 "$ftp_stream_var2 stop"

# Run simulation
$ns at 10.1 "finish"
$ns run


# References
# https://www.tcl.tk/man/tcl8.4/TclCmd/
