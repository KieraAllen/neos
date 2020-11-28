require 'faraday'
require 'figaro'
require 'pry'
require 'json'
# Load ENV vars via Figaro
Figaro.application = Figaro::Application.new(environment: 'production', path: File.expand_path('../config/application.yml', __FILE__))
Figaro.load

class NearEarthObjects
  def initialize(date)
    @date = date
    @asteroids_data = parse_asteroids_data
  end

  def connect_api
    Faraday.new(
      url: 'https://api.nasa.gov',
      params: { start_date: @date, api_key: ENV['nasa_api_key']}
    )
  end

  def parse_asteroids_data
    asteroids_list_data = connect_api.get('/neo/rest/v1/feed')

    JSON.parse(asteroids_list_data.body, symbolize_names: true)[:near_earth_objects][:"#{@date}"]
  end

  def format_asteroid_data
    @asteroids_data.map do |asteroid|
      {
        name: asteroid[:name],
        diameter: "#{diameter(asteroid)} ft",
        miss_distance: "#{miss_distance(asteroid)} miles"
      }
    end
  end

  def diameter(asteroid)
    asteroid[:estimated_diameter][:feet][:estimated_diameter_max].to_i
  end

  def miss_distance(asteroid)
    asteroid[:close_approach_data][0][:miss_distance][:miles].to_i
  end

  def find_neos_info
    {
      asteroid_list: format_asteroid_data,
      biggest_asteroid: largest_asteroid,
      total_number_of_asteroids: @asteroids_data.count
    }
  end

  def largest_asteroid
    @asteroids_data.max do |asteroid_a, asteroid_b|
      diameter(asteroid_a) <=> diameter(asteroid_b)
    end
  end
end
