class Scheduler
  class << self
    def schedulable_time
      { starts_at: Time.parse("09:00"), ends_at: Time.parse("17:00") }
    end

    def restricted_timeframe
      # @note Could be extended to an array in future for added flexibility
      { starts_at: Time.parse('12:00'), ends_at: Time.parse('13:00') }
    end

    # @param [Time] starts
    # @param [Time] ends
    # @return [Boolean]

    # @note ActiveSupport has a better method Range#operlaps?(time_range) that can replace this method
    def falls_during_restricted_time?(starts, ends)
      restricted_time_range = (Scheduler.restricted_timeframe[:starts_at] + 1)..(Scheduler.restricted_timeframe[:ends_at] - 1)
      # If the start or end time of the meeting is during lunch
      # e.g between 12:01 to 12:59
      falls_in_range = restricted_time_range === starts || restricted_time_range === ends
      # Meetings that are supposed to start at say, 12:40 and last 2 hours
      extends_within_range =  (starts < restricted_time_range.first && ends > restricted_time_range.last)

      return true if falls_in_range || extends_within_range
    end

    def schedule(rooms, new_meeting)
      # Find all rooms that can hold a meeting of this duration
      available_rooms = rooms.select{|room| room.can_hold_a_meeting?(new_meeting.duration)}
      puts "No room can hold  #{new_meeting.title}" && return if available_rooms.empty?

      # Find the best-fit room depending on which is free at earliest possible time
      earliest_available_rooms = available_rooms.sort { |room_a, room_b| room_a.next_free_at <=> room_b.next_free_at }
      selected_room = earliest_available_rooms.first
      selected_room.add(new_meeting)
    end
  end
end
