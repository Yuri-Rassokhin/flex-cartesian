require 'sinatra'
require 'sinatra-websocket'
require 'json'

# Используем thin, так как он асинхронный и хорошо держит сокеты
set :server, 'thin'

get '/' do
  if !request.websocket?
    erb :index
  else
    request.websocket do |ws|
      ws.onopen do
        # Приветствие при подключении
        ws.send({ type: 'term', data: "FlexCartesian OS v0.1\r\nReady.\r\n> " }.to_json)
      end

      ws.onmessage do |msg|
        # Парсим входящее сообщение от клиента
        data = JSON.parse(msg)
        command = data['command'].to_s.strip

        # Эхо команды в терминал
        ws.send({ type: 'term', data: "#{command}\r\n" }.to_json)

        # Простая эмуляция выполнения твоего Ruby-скрипта
        if command == 'run heatmap'
          ws.send({ type: 'term', data: "Generating multi-dimensional blueprint...\r\n" }.to_json)
          
          # Эмулируем задержку вычислений
          Thread.new do
            sleep 1.5
            ws.send({ type: 'term', data: "Done. Opening visualization.\r\n> " }.to_json)
            
            # Отправляем команду на открытие окна с результатами
            html_content = <<~HTML
              <div style="padding: 20px; color: white; text-align: center;">
                <h3>Heatmap Insights</h3>
                <p>Здесь будет отрендеренный SVG или Plotly график</p>
                <div style="width: 100%; height: 200px; background: linear-gradient(45deg, #1e00ff, #ff0055);">3D Surface Mock</div>
              </div>
            HTML

            ws.send({ 
              type: 'window', 
              title: 'Blueprint: Tokens vs Temp', 
              html: html_content 
            }.to_json)
          end
        elsif !command.empty?
          ws.send({ type: 'term', data: "Command not found. Try 'run heatmap'.\r\n> " }.to_json)
        else
          ws.send({ type: 'term', data: "> " }.to_json)
        end
      end
    end
  end
end
