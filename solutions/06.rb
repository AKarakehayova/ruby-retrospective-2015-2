module TurtleGraphics
  class Turtle
    def initialize(height, width)
      @height = height
      @width = width
      @current = [0, 0]
      @orientation = :right
      @canvas = Array.new(height) { Array.new(width, 0) }
    end

    def draw(to_draw = nil, &block)
      @canvas[@current[1]][@current[0]] += 1
      instance_eval(&block)
      if to_draw
        to_draw.paint(@canvas)
      else
        @canvas
      end
    end

    def move
      moves = { right: [0, 1], left: [0, -1], up: [-1, 0], down: [1, 0] }
      @current[0] = (@current[0] + moves[@orientation][0]) % @height
      @current[1] = (@current[1] + moves[@orientation][1]) % @width
      @canvas[@current[0]][@current[1]] += 1
    end

    def turn_left
      case @orientation
      when :up then @orientation = :left
      when :down then @orientation = :right
      when :left then @orientation = :down
      when :right then @orientation = :up
      end
    end

    def turn_right
      case @orientation
      when :up then @orientation = :right
      when :down then @orientation = :left
      when :left then @orientation = :up
      when :right then @orientation = :down
      end
    end

    def spawn_at(row, column)
      @canvas[@current[0]][@current[1]] -= 1
      @current = [row, column]
      @canvas[@current[0]][@current[1]] += 1
    end

    def look(orientation)
      @orientation = orientation
    end
  end

  module Canvas
    def self.max_steps(canvas)
      canvas.map(&:max).max
    end

    class ASCII
      attr_reader :length
      def initialize(symbols)
        @symbols = symbols
        @length = symbols.size - 1
      end

      def paint(canvas)
        max_steps = Canvas.max_steps(canvas)
        canvas.map do |row|
          row.map do |cell|
            @symbols[(@length * cell.to_f / max_steps).ceil]
          end.join('')
        end.join("\n")
      end
    end

    class HTML
      def initialize(size)
        @pixels_size = size
        @html = <<-HTML.gsub(/^\s{8}/, '')
        <!DOCTYPE html>
        <html>
        <head>
          <title>Turtle graphics</title>
          <style>
            table {
              border-spacing: 0;
            }
            tr {
              padding: 0;
            }
            td {
              width: #{@pixels_size}px;
              height: #{@pixels_size}px;
              background-color: black;
              padding: 0;
            }
          </style>
        </head>
        <body>
          <table>
          %s
          </table>
        </body>
        </html>
        HTML
      end
      def paint(canvas)
        max_steps = Canvas.max_steps(canvas)
        table_rows = canvas.map do |row|
          table_data = row.map do |cell|
            '<td style="opacity: ' +
            format('%.2f', cell.to_f / max_steps) +
            '"></td>'
          end
          '<tr>' + table_data.join + '</tr>'
        end
        @html % table_rows.join
      end
    end
  end
end
