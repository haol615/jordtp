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
	nextHopIP = if hostMap[nextHop] == nil then '127.0.0.1' else hostMap[nextHop][0] end

	# Open the file, for each line, send it through, close the file
	begin
		fileSize = File.size(fileName)
		currTime = $time
		socket = TCPSocket.open(nextHopIP, $testPort)
		File.open(fileName, 'rb') do |file|
			msg = "FTP,#{localhost},#{dst},#{filePath},#{fileName},#{fileSize}"
			socket.write(msg)
			sleep(1)
			while chunk = file.read(SIZE) do
				socket.write(chunk)
				count = count + 1
			end
		end
		socket.close
		time = $time - currTime
		puts "#{fileName} --> #{dst} in #{time} at #{fileSize / time}"
	rescue
		puts "FTP ERROR: #{fileName} --> #{dst} INTERRUPTED AFTER #{count * SIZE} bytes"
	end
end

def receiveFTP(received, portMap, hostMap, socketClient)
	dst = received[2]
	localhost = Socket.gethostname
	if dst == localhost then
		source = received[1]
		filePath = received[3]
		fileName = received[4]
		fileSize = received[5].to_i
		fullPath = "#{filePath}/#{fileName}"
		buf = []
		while true do
			fragment = socketClient.recv(SIZE)
			if fragment.size == 0 then
				break
			end
			buf << fragment
		end

		if buf.join().size == fileSize then
			File.open(fullPath, 'a+b') do |file|
				file.write(buf.join())
			end
			puts "FTP: #{source} --> #{fullPath}"
		else
			puts "FTP ERROR: #{source} --> #{fullPath}"
		end
	else
		nextHop = $nextNode[dst]
		nextHopIP = hostMap[nextHop][0]
		nextHopSocket = TCPSocket.open(nextHopIP, $testPort)
		str = received.join(',')
		nextHopSocket.write(str)
		while true do
			fragment = socketClient.recv(SIZE)
			if fragment.size == 0 then
				break
			end
			nextHopSocket.write(fragment)
		end
		nextHopSocket.close
	end
end
