set ns [new Simulator]

# Retrieve simulation parameters from shell command line
# 1. The CBR flow
set cbr_flow [lindex $argv 0]mb

# 2. The TCP variant pair start times
set tcp1_start_time [lindex $argv 1]
set tcp2_start_time [lindex $argv 2]

# Setup the output file name
set trace_file_name exp2_
# TCP/... TCP/...
append trace_file_name "Vegas" _ "Vegas"
append trace_file_name _$cbr_flow
append trace_file_name _$tcp1_start_time
append trace_file_name _$tcp2_start_time.tr

# Console log message
puts "$trace_file_name || Running Sim for TCP 1: Vegas | TCP 2: Vegas | CBR: $cbr_flow | TCP 1 ST: $tcp1_start_time | TCP 2 ST: $tcp2_start_time"

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
set N1 [$ns node]
set N2 [$ns node]
set N3 [$ns node]
set N4 [$ns node]
set N5 [$ns node]
set N6 [$ns node]

# Create network links. Default queueing mechanism (Droptail)
$ns duplex-link $N1 $N2 10Mb 12ms DropTail
$ns duplex-link $N2 $N3 10Mb 12ms DropTail
$ns duplex-link $N3 $N4 10Mb 12ms DropTail
$ns duplex-link $N2 $N5 10Mb 12ms DropTail
$ns duplex-link $N3 $N6 10Mb 12ms DropTail

# Set queue limit between nodes N2 and N3
$ns queue-limit $N2 $N3 50

# UDP-CBR Connection
# Setup a UDP connection for CBR flow at N2
set udp [new Agent/UDP]
$ns attach-agent $N2 $udp

# Setup Sink at N3
set null [new Agent/Null]
$ns attach-agent $N3 $null

# Setup CBR over UDP at N2
set cbr [new Application/Traffic/CBR]
$cbr set type_ CBR
$cbr set packet_size_ 1000
$cbr set random_ false
$cbr set rate_ $cbr_flow
$cbr attach-agent $udp

# Connection: UDP - From N2 to N3
$ns connect $udp $null
$udp set fid_ 1

# TCP-FTP Connection 1
# Setup the first TCP connection from N1 to N4
set tcp_var1 [new Agent/TCP/Vegas]
$tcp_var1 set window_ 100
$ns attach-agent $N1 $tcp_var1

# Setup FTP application at N1 for data stream
set ftp_stream1 [new Application/FTP]
$ftp_stream1 set type_ FTP
$ftp_stream1 attach-agent $tcp_var1

# Setup TCP Sink at N4
set tcp_sink1 [new Agent/TCPSink]
$ns attach-agent $N4 $tcp_sink1

# Connection: TCP 1 - From N1 to N4
$ns connect $tcp_var1 $tcp_sink1
$tcp_var1 set fid_ 2

# TCP-FTP Connection 2
# Setup the second TCP connection from N5 to N6
set tcp_var2 [new Agent/TCP/Vegas]
$tcp_var2 set window_ 100
$ns attach-agent $N5 $tcp_var2

# Setup FTP application at N5 for data stream
set ftp_stream2 [new Application/FTP]
$ftp_stream2 set type_ FTP
$ftp_stream2 attach-agent $tcp_var2

# Setup TCP Sink at N6
set tcp_sink2 [new Agent/TCPSink]
$ns attach-agent $N6 $tcp_sink2

# TCP 2 - From N5 to N6
$ns connect $tcp_var2 $tcp_sink2
$tcp_var2 set fid_ 3

# Event schedule for TCP and UDP connections
# Starting CBR at 0.0s
$ns at 0.1 "$cbr start"
# Starting TCP variant pairs after CBR starts (stabalization check)
$ns at $tcp1_start_time "$ftp_stream1 start"
$ns at $tcp2_start_time "$ftp_stream2 start"

$ns at 10.0 "$cbr stop"
$ns at 10.0 "$ftp_stream1 stop"
$ns at 10.0 "$ftp_stream2 stop"

# Run simulation
$ns at 10.0 "finish"
$ns run
