set ns [new Simulator]

# Retrieve simulation parameters from shell command line
# 1. The TCP Variant
set tcp_variant [lindex $argv 0]

# 2. The CBR flow
set cbr_flow [lindex $argv 1]
# Format the flow rate value
append $cbr_flow Mb


# Setup the output file name
set trace_file_name exp1_
# TCP, TCP/...
if {[lindex[split $tcp_variant /] 1] != ""} {
    append trace_file_name [lindex[split $tcp_variant /] 1]
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
#        N1(TCP, FTP)    N4(TCP Sink)
#         \              /
# 10Mb,15ms\  10Mb,15ms / 10Mb,15ms
#           N2(CBR) --- N3(UDP Sink)
# 10Mb,15ms/             \ 10Mb,15ms
#         /               \
#        N5                N6 
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
$ns duplex-link $N1 $N2 10Mb 15ms DropTail 
$ns duplex-link $N5 $N2 10Mb 15ms DropTail 
$ns duplex-link $N2 $N3 10Mb 15ms DropTail 
$ns duplex-link $N4 $N3 10Mb 15ms DropTail 
$ns duplex-link $N6 $N3 10Mb 15ms DropTail


# UDP-CBR Connection
# Setup a UDP connection for CBR flow at N2
set udp [new Agent/UDP]
$ns attach-agent $N2 $udp

# Setup CBR over UDP at N2
set cbr_stream [new Application/Traffic/CBR]
$cbr_stream set rate_ $cbr_flow
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
$ns attach-agent $tcp $ftp_stream
# $ftp attach-agent $tcp

# Setup TCP Sink at N4
set tcp_sink [new Agent/TCPSink]
$ns attach-agent $N4 $tcp_sink


# Make connections
# UDP - From N2 to N3
$ns connect $udp $cbr_sink
$udp set fid_1
# TCP - From N1 to N4
$ns connect $tcp $tcp_sink
$tcp set fid_2


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
