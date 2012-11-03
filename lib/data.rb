require 'json'

class DataGrabber
    def get(file)
        JSON.parse(File.read("public/json/#{file}.json"))
    end

    def extract(file, keys)
        data = get(file)
        data.select {|key| keys.include? key}
    end
end
