require 'time'
class Room
  attr_accessor :name, :next_free_at, :scheduled_meetings

  def initialize(name)
    @name = name
    # When is the room available next
    @next_free_at = Scheduler.schedulable_time[:starts_at]
    @scheduled_meetings = []
  end

  # Chronologically arranged meetings scheduled in the room
  # @return [Array<Meeting>]
  def meetings
    @scheduled_meetings.map{ |m| m[:meeting] }
  end

  # If it is possible fit in a meeting before the day ends
  # @return [Boolean]
  def can_hold_a_meeting?(duration)
    end_time = @next_free_at + duration
    end_time < Scheduler.schedulable_time[:ends_at]
  end

  # @param [Meeting] meeting
  # @return [Hash]
  # Add a meeting to the room
  def add(meeting)
    # If a meeting falls during lunch, increase next_free_at and reschedule it after lunch
    if Scheduler.falls_during_restricted_time?(@next_free_at, @next_free_at + meeting.duration)
      @next_free_at = Scheduler.restricted_timeframe[:ends_at]
      add(meeting)
      return
    end

    new_meeting = { meeting: meeting, starts_at: @next_free_at, ends_at: @next_free_at + meeting.duration }
    @scheduled_meetings << new_meeting
    @next_free_at = new_meeting[:ends_at]
    new_meeting
  end
end
