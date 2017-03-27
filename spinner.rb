class Spinner
  def initialize(fps)
    @delay = 1.0/fps.to_f
    @pinwheel = %w{ | / - \\ }
    @iter = 0
  end

  def start
    @spinner = Thread.new do
      while @iter do
        print @pinwheel[(@iter+=1) % @pinwheel.length]
        sleep @delay
        print "\b"
      end
    end
  end

  def stop
    @iter = false
    @spinner.join
  end
end
