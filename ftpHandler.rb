require 'socket'
require 'benchmark'

SIZE = 1024

def sendFtp(command, portMap, hostMap)
	dst = command[1]
	fileName = command[2]
	filePath = command[3]
	count = 0;
	localhost = Socket.gethostname

	if !$nextNode.has_key?(dst) then
		puts "HOST UNREACHABLE"
		return
	end

	if !File.exist?(fileName) then
		puts "FILE DOESN'T EXIST"
		return
	end

	nextHop = $nextNode[dst]
	nextHopIP = hostMap[nextHop][0]

	# Open the file, for each line, send it through, close the file
	begin
		fileSize = File.size(fileName)
		time = Benchmark.realtime do
			socket = TCPSocket.open(nextHopIP, $testPort)
			File.open(fileName, 'rb') do |file|
				msg = "FTP,#{localhost},#{dst},#{filePath},#{fileName},#{fileSize}"
				socket.write(msg)
				while chunk = file.read(SIZE) do
					puts '.'
					socket.write(chunk)
					count = count + 1
				end
			end
			puts 'done sending'
			socket.close
		end
		puts "#{fileName} --> #{dst} in #{time} at #{fileSize / time}"
	rescue
		puts "FTP ERROR: #{fileName} --> #{dst} INTERRUPTED AFTER #{count * SIZE} bytes"
	end
end

def receiveFTP(received, portMap, hostMap, socketClient)
	dst = received[2]
	localhost = Socket.gethostname
	if dst == localhost then
		puts 'destination'
		source = received[1]
		filePath = received[3]
		fileName = received[4]
		fileSize = received[5].to_i
		fullPath = "#{filePath}/#{fileName}"
		buf = []
		while(fragment = socketClient.recv(SIZE)) do
			buf << fragment
		end
		puts 'done receiving'
		if buf.size == fileSize then
			puts 'writing to file'
			File.open(fullPath, 'a+b') do |file|
				file.write(buf)
			end
			puts "FTP: #{source} --> #{fullPath}"
		else
			puts 'error'
			puts "FTP ERROR: #{source} --> #{fullPath}"
		end
	else
		puts 'bridge'
		nextHop = $nextNode[dst]
		nextHopIP = hostMap[nextHop][0]
		nextHopSocket = TCPSocket.open(nextHopIP, $testPort)
		str = received.join(',')
		nextHopSocket.write(str)
		while(fragment = socketClient.recv(SIZE)) do
			puts '.'
			nextHopSocket.write(fragment)
		end
		nextHopSocket.close
	end
end
