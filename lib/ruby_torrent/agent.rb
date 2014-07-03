require 'agent'

c = channel!(Integer)

go!(c) do |c|
  i = 0
  loop {
    c << i+= 1
  }
end

p c.receive[0] # => 1
p c.receive[0] # => 2
p c.receive[0] # => 2

c.close