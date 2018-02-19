require "spec_helper"
require_relative "../lib/planner"
describe Planner do
  describe "Comparisons" do
    context "restricted meetings" do
      it "is no meetings during lunch" do
        room = Room.new('schoneberg')
        room.next_free_at = Time.parse('11:59')
        Scheduler.schedule([ room ], Meeting.new('Evil Meeting', 60))
        expect(room.next_free_at).to eq(Time.parse '14:00')
      end

      it "is no meetings after the day" do
        room = Room.new('schoneberg')
        room.next_free_at = Time.parse('16:40')
        Scheduler.schedule([ room ], Meeting.new('Evil Meeting', 60))
        expect(room.next_free_at).to eq(Time.parse '16:40')
      end
    end

    context "meetings" do
      let(:room_a) { Room.new('Prenzlauer Berg') }
      let(:room_b) { Room.new('Schonhauser Allee') }

      let(:m1) { Meeting.new('Monday Morning',  180) }
      let(:m2) { Meeting.new('Monday Mittag',  120) }

      before do
        @rooms = [ room_a, room_b]
        Scheduler.schedule(@rooms, m1)
        Scheduler.schedule(@rooms, m2)
      end

      it "are scheduled in respective rooms" do
        expect(room_a.meetings).to include(m1)
        expect(room_b.meetings).to include(m2)
      end

      it "rooms are free after meetings" do
        expect(room_a.next_free_at).to eq(Time.parse '12:00')
        expect(room_b.next_free_at).to eq(Time.parse '11:00')
      end

      it "are scheduled to the room that is earliest available" do
        m3 = Meeting.new('Monday Mittag',  120)
        Scheduler.schedule(@rooms, m3)
        expect(room_b.meetings).to include(m3)
        expect(room_b.next_free_at).to eq(Time.parse '15:00')
      end
    end
  end
end
