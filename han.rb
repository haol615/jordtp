require 'socket'

require_relative 'defined'
require_relative 'pqueue'
#weightPath="";	 #path of weight file
timeInterval=0;	#time per second to update routing table
$state = false;
native = Socket.gethostname;  #native host name
puts "My hostname:"+native
path="/home/core/Downloads/s1"  #path of s1 file
$time = Time.new;
hostMap = Hash.new;
postMap = Hash.new;
nativeCost = CostPackage.new(native);
$dist = Hash.new;
$nextNode = Hash.new;
timeInterval, hostMap, nativeCost, portMap=initial(path, native);
portMap.each{|key, value| puts "#{key} : #{value}"}
linkPackageMap = Hash.new
linkPackageMap[native] = nativeCost
preHostname = "";
lsps = lsp_to_s(nativeCost, native)
$needForwarding = true
$testPort = 2051
#clientfunc(portMap, nativeCost.map(), hostMap, lsps,preHostname)
t3 = Thread.new{clock()}
t1 = Thread.new {serverfunc(portMap[native].to_i,linkPackageMap, hostMap, nativeCost)}
sleep(8)
t2 = Thread.new {
	clientfunc(portMap, hostMap, lsps, preHostname)
}



t4 = Thread.new{getUserCommand(portMap, nativeCost.map(), hostMap, nativeCost)}

=begin
t5 = Thread.new{
	loop{
	sleep(20)
	puts "reloading!"
	timeInterval, hostMap, nativeCost, portMap=initial(path, native)
	}
}
=end
#t6 = Thread.new{loop{sleep(1); puts $time}}
t4.join
t1.join
t2.join
t3.join
#t5.join
#t6.join





