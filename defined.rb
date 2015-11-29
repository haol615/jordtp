require_relative 'pqueue'
require_relative 'ftpHandler'
require 'socket'
require 'time'
####################################################################
# class CostPackage
####################################################################

class CostPackage  #class of link state package
	attr_accessor :sequenceNumber, :costMap,:status   #enable changing to sequenceNumber and costMap
	@source;
	@status;
	@sequenceNumber;
	@costMap=Hash.new();
	def initialize(source)
		@source=source
		@sequenceNumber = 0
		@status = false
	end
	
	def getMap(map)   #function to copy map into class 
		@costMap = map
	end

	def seeMap()    #function to see the elements of map
		keys = @costMap.keys;
		for i in 0..keys.length-1
		
		puts keys[i]+ ":"+ @costMap[keys[i]];
		end

	end
	def map()
		return @costMap
	end


end

####################################################################
# initial function
####################################################################

def initial(path, native)
	weightPath = "";
	timeInterval = 0;
	nodesPath = "";
	nativeCost = CostPackage.new(native);
File.open(path+"/config", "r") do |f|   #read config to get weight file path and time interval
	f.each_line do |line|
		input = line.split("=")
		if input[0] == "weightFile" then weightPath = input[1]
		end
		if input[0] == "updateInterval" then timeInterval = input[1]
		end
		if input[0] == "nodes" then nodesPath = input[1]
		end
		#puts input[0]
	end
end

#puts weightPath
#puts weightPath.length
#puts timeInterval


hostMap = Hash.new();   #the map used to store the hash of host name and ip address

#the map looks like     hostname:(hostname ip address, native ip address)

weightPath = weightPath[1,weightPath.length - 2]

   
costMap = Hash.new();  #will be stored into nativeCost 


#puts path
#puts weightPath
File.open(path+weightPath, "r") do |f|
	f.each_line do |line|
		input = line.split(",")
		if input[0] == native then
			hostMap[input[2]] = Array[input[3], input[1]];
			costMap[input[2]] = input[4];
		end		
		if input[2] == native then
			hostMap[input[0]] = Array[input[1], input[3]];
			costMap[input[0]] = input[4];
		end
	end
end
nativeCost.getMap(costMap);

nodesPath = nodesPath[1,weightPath.length - 2]
postMap = Hash.new();

File.open(path+nodesPath, "r") do |f|
	f.each_line do |line|
		input = line.split("=")
		postMap[input[0]] = input[1];
	end
end

#puts hostMap.keys

#output = hostMap["n2"]
#puts output[0]
#puts output[1]

#nativeCost.seeMap();
hostMap.each{|key, value| puts "#{key} : #{value[0]}, #{value[1]}"}
return timeInterval, hostMap, nativeCost, postMap
end

####################################################################
# timeout checking for flooding.
####################################################################

def checkTimeout_Flooding()
	sleep(2);
	puts "time out!";


end

####################################################################
# Function of server
####################################################################

def serverfunc(portMap, linkPackageMap, hostMap, nativeCost)
	puts "server func running..."
	server = TCPServer.open($testPort)
	localhost = Socket.gethostname
	loop{
		#puts "loop entered"
		if nativeCost.instance_variable_get(:@status) == false then
		timeOut = Thread.new{
			sleep(7)
			puts "timeOut";
			$dist, $nextNode = dij(linkPackageMap, nativeCost.instance_variable_get(:@source))
			$dist.each{|key, value| puts "key : #{key}   value : #{value}"}
			$nextNode.each{|key, value| puts "key : #{key}   value : #{value}"}
			nativeCost.status = true;
		}
		end

		Thread.start(server.accept) do |client|

			line = client.recv(2048)
			puts line
			received = line.split(",")
			case received[0]
				when "FLOODING"
					puts "flooding function is chosen"
					flooding(nativeCost, timeOut, received, linkPackageMap, localhost, portMap, hostMap)
				when "SNDMSG"
					func2()
				when "PING"
					ping_server(received, portMap, hostMap)
				when "PING_ACK"
					ping_ack_server(received, portMap, hostMap)
				when "TRACEROUTE"
					func4()
				when "FTP"
					receiveFTP(received, portMap, hostMap, client)
				when "CLOCKSYNC"
					func6()
				when "ADVERTISE"
					func7()
				else
					func8()
			end
			client.close
		end
	}
end
####################################################################
# Function of client
####################################################################
def clientfunc(portMap, hostMap, lsps, preHostname)
	
	puts "client func running..."
	#localhost = Socket.gethostname 
	#lsps = lsp_to_s(nativeCost, localhost)
	#puts lsps
	for i in 0..hostMap.length-1
		
		hostname = hostMap.keys[i]
		if(hostname != preHostname) then
			destIP = hostMap[hostname][0]
			#puts "#{destIP}"
			#port = portMap[hostname].to_i;
			#puts "#{lsps} to #{hostname}"
			s = TCPSocket.open(destIP, $testPort)
			s.write(lsps)
			#line = s.gets
			#puts line               # reserved to receive acknowledgement
			s.close
		end
		
	end
end

####################################################################
# Function of clientfuncPassMessage 
####################################################################
def clientfunc2(destIP, port, str)
	s = TCPSocket.open(destIP, port)
	s.write(str) 
	s.close
end

####################################################################
# Function of getUserCommand
####################################################################
def getUserCommand(portMap, costMap, hostMap, nativeCost)
	loop{
	input = gets;
	input = input.chomp
	command = input.split(" ");
	case command[0]
	when "hello"
		clientfunc(portMap, costMap, hostMap, nativeCost)
	when "FORCEUPDATE"
		forceUpdate(true, nil,command, hostMap, portMap,nativeCost);
	when "CHECKSTABLE"
		checkStatus(nativeCost);
	when "DUMPTABLE"
		getRoutingtable(hostMap, nativeCost.instance_variable_get(:@source), command[1]);
	when "PING"
		ping_client(command, portMap, hostMap)
	when "FTP"
		sendFtp(command, portMap, hostMap)
	end

	}

end
####################################################################
# Function of clock.
####################################################################
def clock()
	loop{
	sleep(0.1);
	$time = $time + 0.1;
	}
end
####################################################################
# Function of reload files
####################################################################
def reload(path, native)
	loop{
	sleep(20)
	puts "reloafding!"
	return  initial(path, native);
	}
end


####################################################################
# Function of dij...
####################################################################

#start dj
def dij(linkPackageMap, native)
puts "start dij"
dist = Hash.new();
prevNode = Hash.new();
traversed = Array.new;
allNodes = linkPackageMap.keys;
#for i in 0..allNodes.length - 1
#	dist[allNodes[i]] = -1;
#	prevNode[allNodes[i]] = nil;
#end
dist[native] = 0;
prevNode[native] = native;
#q = PriorityQueue.new
#q[native] = 0;

q = Pqueue.new();
q.push(native, 0);


until q.isEmpty()
	u, distance = q.pop();
	traversed.push(u);
	#puts u;
	#puts distance;
	uNeighborMap = linkPackageMap[u].map();
	#puts uNeighborMap.keys;
	uNeighbors = uNeighborMap.keys
	for i in 0..uNeighbors.length - 1
		#puts uNeighbors[i]
		if !traversed.include?(uNeighbors[i]) then
			newDistance = dist[u].to_i + uNeighborMap[uNeighbors[i]].to_i;
			if dist[uNeighbors[i]] == nil then
				dist[uNeighbors[i]] = newDistance
				prevNode[uNeighbors[i]] = u;
			else 
				if newDistance < dist[uNeighbors[i]] then
				dist[uNeighbors[i]] = newDistance
				prevNode[uNeighbors[i]] = u;
				end
			end
			q.push(uNeighbors[i], dist[uNeighbors[i]].to_i);
			#q[uNeighbors[i]] = dist[uNeighbors[i]].to_i;
		end
			
	end

end



nodes = prevNode.keys;
#puts nodes;
nativeNeighbor = linkPackageMap[native].map();
#nativeNeighbor.each{|key, value| puts "key : #{key}   value : #{value}"}
for i in 0 .. nodes.length - 1
	if prevNode[nodes[i]] == native then
		prevNode[nodes[i]] = nodes[i];
	else
		while(!nativeNeighbor.include?(prevNode[nodes[i]]) )
			prevNode[nodes[i]] = prevNode[prevNode[nodes[i]]];
		end	
	end
end

return dist, prevNode;
end

####################################################################
# Function of get Routing table
####################################################################
def getRoutingtable(hostMap, native, fileName)
	nodes = $dist.keys;
	puts nodes
	if fileName == nil then
		fileName = "routingTable.csv"
	end
	File.open(fileName, "w") do |f|
		for i in 0..nodes.length - 1
			value = nodes[i];
				if value == native then
					nativeIp = Socket.getaddrinfo("localhost",nil)[0][3]
					f.puts "#{nativeIp},#{nativeIp},#{native},0"
				else
					ipAddr = hostMap[value];
					f.puts "#{ipAddr[1]},#{ipAddr[0]},#{$nextNode[value]},#{$dist[value]}";
				end	
		end
	end
end

def checkStatus(nativeCost)
	puts nativeCost.instance_variable_get(:@status)
	if nativeCost.instance_variable_get(:@status) == false then
		puts "This node is not stable"
	else
		puts "This node is stable"
	end
end


def forceUpdate(start, server, param, hostMap, portMap,nativeCost)
	#param = message.split(",");
	nodes = hostMap.keys;
	source = "";
	if start == false then
		source = param[2]
		sequence = param[1];
		if(sequence <= nativeCost.instance_variable_get(:@sequenceNumber)) then
			return 
		else
			nativeCost.sequenceNumber = sequence;
		end
	else
		nativeCost.sequenceNumber = nativeCost.instance_variable_get(:@sequenceNumber) + 1;
	end
	
	if nodes.include?(source) then
		nodes.delete(source)
	end
	message = "FORCEUPDATE," + nativeCost.instance_variable_get(:@sequenceNumber).to_s;
	message += ",";
	message += nativeCost.instance_variable_get(:@source);
	puts message
	for i in 0..nodes.length-1
	
		hostname = nodes[i]
		destIP = hostMap[hostname][0]
		port = portMap[hostname].to_i;
		s = TCPSocket.open(destIP, 1115)
		
		s.write(message)
		line = s.gets                # receive acknowledgement
		s.close
	end

end

def lsp_to_s(nativeCost, localhost)
	lsps = "FLOODING"
	lsps += ",#{nativeCost.instance_variable_get(:@source)},#{nativeCost.instance_variable_get(:@sequenceNumber)}"
	costMap = nativeCost.instance_variable_get(:@costMap)
	lsps += ",#{localhost}"
	lsps += ",#{nativeCost.instance_variable_get(:@source)},0"
	for i in 0..costMap.length-1
		key = nativeCost.instance_variable_get(:@costMap) .keys[i] 
		lsps += "," + key
		value = nativeCost.instance_variable_get(:@costMap)[key]
		value = value[0, value.length - 1]
		lsps += "," + value
	end
	return lsps
end

def flooding(nativeCost, timeOut, received, linkPackageMap, localhost, portMap, hostMap)
	puts "flooding function running..."
	if nativeCost.instance_variable_get(:@status) == false then
		Thread.kill(timeOut);
	end

	#puts "client accepted"
	#client.puts "accepted by #{localhost}"	

	newCostPackage = CostPackage.new(received[1])
	newCostPackage.sequenceNumber = received[2]
	preHostname = received[3]
	costMap = Hash.new()
	for i in 4..received.length-1
		if i % 2 == 0 then
			costMap[received[i]] = received[i + 1]
		end
	end
	newCostPackage.getMap(costMap)
	#newCostPackage.sequenceNumber = 1
	#puts newCostPackage.sequenceNumber
	#newCostPackage.seeMap()
	if linkPackageMap.has_key?(received[1]) == false then
		linkPackageMap[received[1]] = newCostPackage
		received[3] = localhost
		clientfunc(portMap, hostMap, received.join(','), preHostname)
	elsif linkPackageMap[received[1]].sequenceNumber < newCostPackage.sequenceNumber then
		linkPackageMap[received[1]] = newCostPackage
		received[3] = localhost
		clientfunc(portMap, hostMap, received.join(','), preHostname)
	end
	numOfKeys = linkPackageMap.length
	puts "Now my linkPackageMap has #{numOfKeys} value"
end

def ping_client(command, portMap, hostMap)
	dst = command[1]
	numOfPings = command[2].to_i
	delay = command[3]
	source = Socket.gethostname
	if $nextNode.has_key?(dst) == false then
		puts "PING ERROR: HOST UNREACHABLE"
		return
	end
	nextHop = $nextNode[dst]
	puts "nextHop is #{nextHop}"
	nextHopIP = hostMap[nextHop][0]
	for i in 0..numOfPings-1
		str = "PING,#{source},#{dst},#{i},#{$time}"
		puts "The string to be sent is #{str}"
		clientfunc2(nextHopIP, $testPort, str)
		sleep(delay.to_i)
	end
end

def ping_server(received, portMap, hostMap)
	localhost = Socket.gethostname
	puts "localhost is #{localhost}"
	if received[2] == localhost then
		puts "#{received} received"
		str = "PING_ACK,#{received[2]},#{received[1]},#{received[3]},#{received[4]}"
		nextHop = $nextNode[received[1]]
		nextHopIP = hostMap[nextHop][0]
		clientfunc2(nextHopIP, $testPort, str)
	else
		str = received.join(',')
		nextHop = $nextNode[received[2]]
		nextHopIP = hostMap[nextHop][0]
		clientfunc2(nextHopIP, $testPort, str)
	end
end
	
def ping_ack_server(received, portMap, hostMap)
	localhost = Socket.gethostname
	puts "localhost is #{localhost}"
	if received[2] == localhost then
		puts "#{received} received"
		oldTime = Time.parse(received[4])
		rrt = $time - oldTime
		puts "#{received[3]} #{received[1]} #{rrt}"
	else
		str = received.join(',')
		nextHop = $nextNode[received[2]]
		nextHopIP = hostMap[nextHop][0]
		clientfunc2(nextHopIP, $testPort, str)
	end
end
