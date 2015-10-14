require 'cairo'
require 'tempfile'

module Placebo
  class Raster
    WINDOW_WIDTH = 1368
    WINDOW_HEIGHT = 600

    def initialize
      # x height y width
      @c_x, @c_y, @c_rx, @c_ry = 0.0, 0.0, WINDOW_WIDTH, WINDOW_HEIGHT # calculated dimensions
      @heights = [WINDOW_HEIGHT]
    end

    def render(layout)
      Cairo::ImageSurface.new(WINDOW_WIDTH, WINDOW_HEIGHT) do |surface|
        Cairo::Context.new(surface) do |context|
          @context = context
          context.set_source(1, 1, 1)
          context.paint
          render_box layout
        end
        browser surface
      end
    end

    def to_rgb(color)
      c = color.upcase  
      if c.empty?
        [1, 1, 1]
      elsif c[0] == '#' && c.length == 7
        r, g, b = c[1..2].to_i(16), c[3..4].to_i(16), c[5..6].to_i(16)
        [r.to_f / 255, g.to_f / 255, b.to_f / 255]
      elsif c[0] == '#' && c.length == 4
        r, g, b = c[1..3].split('').map { |q| q.to_i 16 }
        [r.to_f / 255, g.to_f / 255, b.to_f / 255]
      elsif Cairo::Color.const_defined? c
        d = Cairo::Color.const_get(c)
        [d.red, d.green, d.blue]
      else
        [1, 1, 1]
      end
    end

    def render_box(box)
      puts 'render'
      p [box.tag_name, box.class, box.is_a?(Layout::TextBox) ? box.text : '', box.properties, box.height, box.width]
      p ["x is #{@c_x} y is #{@c_y}"]
      puts "\n\n"
      case box
      when Layout::BlockBox
        old_y, old_x, old_ry, old_rx = @c_y, @c_x, @c_ry, @c_rx
        @d0 = box.dimensions.margin.top + box.dimensions.border.top + box.dimensions.padding.top
        @d1 = box.dimensions.margin.left + box.dimensions.border.left + box.dimensions.padding.left
        @d2 = box.height - @d0
        @d3 = box.width - @d1
        @c_y += @d0
        @c_x += @d1
        @c_ry -= @d2
        @c_rx -= @d3
        p "draw #{@c_y} #{@c_x}"
        rectangle = @context.rectangle @c_x, @c_y, WINDOW_WIDTH - 120 - @c_x * 2, box.height
        color = box.properties[:'background-color']

        color = color ? color : '#fff'
        @context.set_source_rgb *to_rgb(color)
        # puts color, to_rgb(color), box.height
        
        @context.fill
        @heights << box.height
        # @c_x = 0

        box.children.each &method(:render_box)

        @heights.pop
        @c_y = old_y + box.height
        @c_x = old_x
        @c_ry = old_ry
        @c_rx = old_rx
        # @c_x = 0

      when Layout::InlineBox
        @context.set_source_rgba 1, 1, 1, 0
        old_x, old_y = @c_x, @c_y
        @c_x += box.dimensions.margin.left + box.dimensions.border.left + box.dimensions.padding.left
        
        rectangle = @context.rectangle @c_x, @c_y, box.width - @c_x + old_x, @heights.last
        color = box.properties[:color]
        @context.set_source *to_rgb(color) if color
        @context.fill
        
        box.children.each &method(:render_box)
        # no children for now
        @c_x = old_x + box.width

      when Layout::TextBox
        font_size = box.properties[:'font-size'][0..-3].to_f
        @context.set_source_rgb 0, 0, 0
        @context.set_font_size font_size
        @context.move_to @c_x, @c_y + font_size
        @context.show_text box.text
      end
    end

    def browser(surface)
      result = Tempfile.new("result")
      surface.write_to_png(result.path)
      system("firefox", result.path)
    end
  end
end

