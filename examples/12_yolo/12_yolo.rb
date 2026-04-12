require 'faraday'
require 'faraday/multipart'
require 'json'

client = Faraday.new(url: 'http://localhost:8000') do |f|
  f.request :multipart
  f.request :url_encoded
  f.adapter Faraday.default_adapter
end
payload = { file: Faraday::Multipart::FilePart.new('./bus.jpg', 'image/jpeg') }
response = client.post('/vision', payload)

if response.status == 200
  result = JSON.parse(response.body)
  
#  puts "Найдено объектов: #{result['detections'].size}"
#  result['detections'].each do |det|
#    puts "- #{det['class_name']} (#{(det['confidence'] * 100).round}%) | Координаты: #{det['bbox']}"
#  end
else
  puts "Ошибка API: HTTP #{response.status}"
  puts response.body
end
