require 'csv'

class LondonTube

  DISTRICT = 'District'
  HAM_AND_CITY = 'Hammersmith and City'

  def initialize
    @data = []
    @stations = []
  end

  def run!
    num = welcome!

    CSV.foreach('london_tube_lines.csv', headers: true) do |row|
      @data << row.to_h
    end

    @data.each do |route|
      stops = 0
      # current route
      current_tube_line    = route['Tube Line']
      current_from_station = route['From Station']
      current_to_station   = route['To Station']

      # keep going until we hit East Ham
      until stops >= num || final_destination?(current_from_station)
        stops += 1
        # reset next route
        next_route = nil
        # check if current "from" or "to" stations are on the District line
        unless current_tube_line == HAM_AND_CITY
          if current_tube_line == DISTRICT
            # find next stop if current station is already on District
            next_route = find_next_route(DISTRICT, current_to_station)
          else
            # otherwise, check if current station is on District
            next_route = find_next_route(DISTRICT, current_from_station)
          end
        end
        # find next stop if current station is already on Hammersmith and City
        if current_tube_line == HAM_AND_CITY
          next_route = find_next_route(HAM_AND_CITY, current_to_station)
        end
        # otherwise, check if current station is on Hammersmith and City
        next_route ||= find_next_route(HAM_AND_CITY, current_from_station)
        # still no dice, look in the same line
        next_route ||= find_next_route(current_tube_line, current_to_station)
        # lastly, look everywhere else
        next_route ||= find_route_in_other_lines(current_tube_line, current_to_station)

        if next_route
          current_tube_line    = next_route['Tube Line']
          current_from_station = next_route['From Station']
          current_to_station   = next_route['To Station']
        end
      end

      @stations << route['From Station'] if stops >= num
    end

    puts @stations.uniq!.sort
    puts @stations.size
  end

  def find_route(tube_line, from_station, to_station)
    @data.detect { |routes|
      routes['Tube Line'] == tube_line &&
      routes['From Station'] == from_station &&
      routes['To Station'] == to_station
    }
  end

  def find_next_route(tube_line, station)
    @data.detect { |routes| routes['Tube Line'] == tube_line && routes['From Station'] == station }
  end

  def find_route_in_other_lines(tube_line, station)
    @data.detect { |routes| routes['Tube Line'] != tube_line && routes['From Station'] == station }
  end

  def final_destination?(from_station)
    station = find_route(DISTRICT, from_station, 'East Ham')
    station ||= find_route(HAM_AND_CITY, from_station, 'East Ham')
    !station.nil?
  end

  def welcome!
    print 'How many stops from East Ham? '
    gets.chomp.to_i
  end

end

LondonTube.new.run!
