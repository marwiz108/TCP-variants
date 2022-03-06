set ns [new Simulator]

# Retrieve simulation parameters from shell command line
# 1. The pair of TCP Variants
set tcp_variant_pair [lindex $argv 0]
set tcp_variant1 [lindex [split $tcp_variant_pair " "] 0]
set tcp_variant2 [lindex [split $tcp_variant_pair " "] 1]

# 2. The CBR flow
set cbr_flow [lindex $argv 1]Mb


# Setup the output file name
set trace_file_name exp1_
# TCP, TCP/...
if {[lindex [split $tcp_variant /] 1] != ""} {
    append trace_file_name [lindex [split $tcp_variant /] 1]
} else {
    append trace_file_name Tahoe
}
append trace_file_name _$cbr_flow.tr


# Console log message
puts "$trace_file_name, TCP Variant: $tcp_variant, CBR Flow: $cbr_flow"


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
# TCP Source
set N1 [$ns node]
set N5 [$ns node]
# CBR Source - Bottleneck Cap: 10Mbps
set N2 [$ns node]
# UDP Sink - Null
set N3 [$ns node]
# TCP Sink
set N4 [$ns node]
set N6 [$ns node]


# Create network links. Default queueing mechanism (Droptail)
$ns duplex-link $N1 $N2 10Mb 12ms DropTail 
$ns duplex-link $N5 $N2 10Mb 12ms DropTail 
$ns duplex-link $N2 $N3 10Mb 12ms DropTail 
$ns duplex-link $N4 $N3 10Mb 12ms DropTail 
$ns duplex-link $N6 $N3 10Mb 12ms DropTail 

# Set queue limit between nodes N2 and N3
$ns queue-limit $N2 $N3 10


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


# TCP-FTP Connection
# Setup TCP connection from N1 to N4
set tcp [new Agent/$tcp_variant]
$ns attach-agent $N1 $tcp

# Setup FTP application at N4 for data stream
set ftp_stream [new Application/FTP]
$ftp_stream attach-agent $tcp

# Setup TCP Sink at N4
set tcp_sink [new Agent/TCPSink]
$ns attach-agent $N4 $tcp_sink


# Make connections
# UDP - From N2 to N3
$ns connect $udp $cbr_sink
$udp set fid_ 1
# TCP - From N1 to N4
$ns connect $tcp $tcp_sink
$tcp set fid_ 2


# Event schedule for TCP and UDP connections
$ns at 0.0 "$cbr_stream start"
$ns at 0.0 "$ftp_stream start"
$ns at 10.0 "$ftp_stream stop"
$ns at 10.0 "$cbr_stream stop"

# Run simulation
$ns at 10.0 "finish"
$ns run


# References
# https://www.tcl.tk/man/tcl8.4/TclCmd/
