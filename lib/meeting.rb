class Meeting
  attr_accessor :title, :duration
  def initialize(title, duration)
    @title = title
    # Use the duration integer as minutes..equivalent to duration.minutes
    @duration = duration.to_i * 60
  end
end
