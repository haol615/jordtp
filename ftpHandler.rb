require 'socket'
require 'benchmark'

SIZE = 512

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
				while chunk = file.read(SIZE) do
					msg = "FTP,#{localhost},#{dst},#{filePath},#{fileName},#{chunk}"
					socket.write(msg)
					count = count + 1
				end
			end
			socket.close
		end
		puts "#{fileName} --> #{dst} in #{time} at #{fileSize / time}"
	rescue
		puts "FTP ERROR: #{fileName} --> #{dst} INTERRUPTED AFTER #{count * SIZE} bytes"
	end
end

def receiveFTP(received, portMap, hostMap)
	dst = received[2]
	localhost = Socket.gethostname
	if dst == localhost then
		puts "destination"
		source = received[1]
		filePath = received[3]
		fileName = received[4]
		currentChunk = received[5].to_i
		totalChunk = received[6].to_i
		payload = received[7]
		fullPath = "#{filePath}/#{fileName}"
		puts fullPath
		File.open(fullPath, 'a+b') do |file|
			file.write(payload)
		end
		if currentChunk == totalChunk then
			puts "FTP: #{source} --> #{fullPath}"
		end
	else
		str = received.join(',')
		nextHop = $nextNode[dst]
		nextHopIP = hostMap[nextHop][0]
		clientfunc2(nextHopIP, $testPort, str)
	end
end
