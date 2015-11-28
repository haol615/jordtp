class Pqueue
	@queue;
	@hashMap;
	
	def initialize()
		@queue = Array.new;
		@hashMap = Hash.new;
	end

	def push(key, value)
		@hashMap[key] = value;
		if(@queue.empty?) then
			@queue.push(key);
		else
			i = findIndex(value);
			@queue.insert(i, key);
		end
	end
	
	def isEmpty()
		return @queue.empty?
	end




	def print()
		@queue.each{|value| puts "#{value} :   #{@hashMap[value]}"};
		#@hashMap.each{|key, value| puts "#{key} : #{value}"};
	end

	def pop()
		node = @queue[0];
		@queue.delete_at(0);
		value = @hashMap[node];
		@hashMap.delete(node);
		return node, value;
	end

	def findIndex(value)
		if @hashMap[@queue[@queue.length - 1]].to_i <= value then
			return @queue.length;
		else if @hashMap[@queue[0]].to_i >= value then
				return 0;
			end
		end
		left = 0;
		right = @queue.length - 1;
		while(left < right)
			mid = left + (right - left ) / 2;
			if(@hashMap[@queue[mid]].to_i == value) then
				return mid;
			end
			if(@hashMap[@queue[mid]].to_i < value) then
				left = mid + 1;
			else 
				right = mid - 1;
			end
		end

		if(@hashMap[@queue[left]].to_i > value) then
			
			return left;
		else
			
			return left + 1;
		end
	end


end

=begin
p = Pqueue.new();
p.push("n1",1);
puts "*********"
p.print();
p.push("n2",2);
puts "*********"
p.print();
p.push("n3",4);
puts "*********"
p.print();
p.push("n4",3);
puts "*********"
p.print();

p.push("n5",8);
puts "*********"
p.print();

p.push("n6",2);
puts "*********"
p.print();

p.pop();
puts "*********"
p.print();

p.pop();
puts "*********"
p.print();

=end