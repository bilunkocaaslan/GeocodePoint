require 'geocoder'
require 'kmeans-clusterer'

class GeocoderController < ApplicationController

    def index 
        @no_of_basket = 5
        @no_of_point = 15
        @points = []
        @baskets = Array.new(@no_of_basket) { [] }
        @center_loc = Geocoder.search("Gaziemir, Izmir")
        @center_point = Geocoder::Calculations.geographic_center([[@center_loc[0].latitude, @center_loc[0].longitude]])
        @center_lat = @center_point[0]
        @center_lng = @center_point[1]
        puts "#{generate_point}"
    end

    def generate_point
         # for generating random test points in Gaziemir
        for i in 1..@no_of_point do
            lat, lng = Geocoder::Calculations.random_point_near([@center_lat, @center_lng], 5) # generates a random point within 5km of Gaziemir
            @points.append([lat, lng])
        end
        puts "#{@points.length()} random points generated"
        puts "#{cluster_point}"

    end

    def cluster_point
        kmeans = KMeansClusterer.run @no_of_basket, @points, labels: "labels", runs: 1
        @points.each_with_index do |point, i|
            idx = kmeans.predict([point]).first
            new_basket = @baskets[idx]
            if new_basket.length() > 0
                new_basket.each do |p|
                    distance = Geocoder::Calculations.distance_between(point, p, units: :km)
                    if distance <= 1
                        new_basket.append(point)
                        break
                    else
                        @baskets.append([point])
                    end
                    end
            else
                new_basket.append(point)
            end
        end
        puts "#{write_file}"

    end

    def write_file
        file = File.open("results.txt", "w")
        results = []
        @baskets.each_with_index do |basket,i|
            puts "BASKET_NUM#{i+1}"
            file.write("BASKET_NUM#{i+1}")
            basket.each_with_index do |location, j|
                begin 
                    address = Geocoder.search([location[0], location[1]]).first.address
                rescue 
                    address = ""
                    puts "Address could not find for this location #{location[0]}, #{location[1]}"
                end
                link = "https://www.google.com/maps/search/?api=1&query=#{location[0]},#{location[1]}"
                file.write("\n item#{j+1} #{[location[0],location[1]]}, #{address}, #{link} \n")
                results.append({basket_num: i+1, item_num: j+1, lat: location[0], lng: location[1]})
            end
        end
        puts "File created successfully."
        @json_result= results.to_json
        respond_to do |format|
            format.html # Render the HTML view
            format.json { render json: @json_result } # Render the JSON data
          end
    end

end
