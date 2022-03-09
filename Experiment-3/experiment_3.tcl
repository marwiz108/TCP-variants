set ns [new Simulator]

set tcp_variant [lindex $argv 0]

set queue [lindex $argv 1]

# Setup output file
set trace_file_name exp3_
append trace_file_name $tcp_variant _ $queue.tr

# Console message
puts "$trace_file_name, TCP Variant: $tcp_variant, Queueing algorithm: $queue"

# Create/open trace trace file
set nf [open trace_data/$trace_file_name w]
$ns trace-all $nf

proc finish {} {
    global ns nf
    $ns flush-trace
    # close trace file
    close $nf
    exit 0
}

#
# Create a simple six node topology:
#
#        N1(TCP, FTP)    N4(TCP Sink)
#         \              /
# 10Mb,12ms\  10Mb,12ms / 10Mb,12ms
#           N2(CBR) --- N3(UDP Sink)
# 10Mb,12ms/            \ 10Mb,12ms
#         /              \
#        N5               N6 
#

# Setup nodes
set N1 [$ns node]
set N2 [$ns node]
set N3 [$ns node]
set N4 [$ns node]
set N5 [$ns node]
set N6 [$ns node]

# Create network links with specified queueing discipline
$ns duplex-link $N1 $N2 10Mb 10ms $queue
$ns duplex-link $N5 $N2 10Mb 10ms $queue
$ns duplex-link $N2 $N3 10Mb 10ms $queue
$ns duplex-link $N4 $N3 10Mb 10ms $queue
$ns duplex-link $N6 $N3 10Mb 10ms $queue

# Set queue limit
$ns queue-limit $N1 $N2 50
$ns queue-limit $N5 $N2 50
$ns queue-limit $N2 $N3 50
$ns queue-limit $N4 $N3 50
$ns queue-limit $N6 $N3 50

# UDP-CBR Connection
# Setup UDP connection at N2
set udp [new Agent/UDP]
$ns attach-agent $N2 $udp
# Setup CBR over UDP at N2
set cbr_stream [new Application/Traffic/CBR]
$cbr_stream set rate_ 8mb
$cbr_stream set type_ CBR
$cbr_stream set random_ false
$cbr_stream attach-agent $udp
# Setup CBR Sink at N3
set cbr_sink [new Agent/Null]
$ns attach-agent $N3 $cbr_sink

# TCP-FTP Connection
# Setup TCP connection at N1
set tcp [new Agent/TCP/$tcp_variant]
$tcp set window_ 100
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
$ns at 0.0 "$ftp_stream start"
$ns at 7.0 "$cbr_stream start"
$ns at 30.0 "$ftp_stream stop"
$ns at 30.0 "$cbr_stream stop"

# Run simulation
$ns at 30.1 "finish"
$ns run
