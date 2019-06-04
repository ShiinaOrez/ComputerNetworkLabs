# jiqing 2007-6-5
# this script is to compare the loss rates of http and rtp.

set ns [new Simulator]

#open a nam trace file
set nf [open out.nam w]
$ns namtrace-all $nf

#open a trace file
set tf [open out.tr w]
$ns trace-all $tf

#finish procedure
proc finish {} {
 global ns nf tf
 $ns flush-trace
 close $nf
 close $tf
 exec nam out.nam &
 exit 0
}

#create nodes
set node(http) [$ns node]
set node(rtp) [$ns node]
set node(recv) [$ns node]

#create links
$ns duplex-link $node(http) $node(recv) 0.9Mb 10ms DropTail
$ns duplex-link $node(rtp) $node(recv) 0.9Mb 10ms DropTail

#set queue size
$ns queue-limit $node(http) $node(recv) 10
$ns queue-limit $node(rtp) $node(recv) 10

#relayout nodes
$ns duplex-link-op $node(http) $node(recv) orient right-down
$ns duplex-link-op $node(rtp) $node(recv) orient right-up

#set colors
$ns color 1 blue
$ns color 2 red

#set a tcp connection
set tcp [new Agent/TCP]
$ns attach-agent $node(http) $tcp
set sink [new Agent/TCPSink]
$ns attach-agent $node(recv) $sink
$ns connect $tcp $sink
$tcp set fid_ 1

#set a cbr above tcp connection
set cbr(http) [new Application/Traffic/CBR]
$cbr(http) attach-agent $tcp
$cbr(http) set type_ CBR
$cbr(http) set packet_size_ 1000
$cbr(http) set rate_ 1mb
$cbr(http) set random_ false

#set a rtp connection
set rtp [new Agent/UDP]
$ns attach-agent $node(rtp) $rtp
set null [new Agent/Null]
$ns attach-agent $node(recv) $null
$ns connect $rtp $null
$rtp set fid_ 2

#set a cbr above tcp connection
set cbr(rtp) [new Application/Traffic/CBR]
$cbr(rtp) attach-agent $rtp
$cbr(rtp) set type_ CBR
$cbr(rtp) set packet_size_ 1000
$cbr(rtp) set rate_ 1mb
$cbr(rtp) set random_ false

#schedule
$ns at 0.1 "$cbr(http) start"
$ns at 0.1 "$cbr(rtp) start"
$ns at 4.0 "$cbr(http) stop"
$ns at 4.0 "$cbr(rtp) stop"
$ns at 4.1 "finish"

$ns run
