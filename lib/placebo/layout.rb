module Placebo
  module Layout

    class EdgeSizes < Struct.new(:left, :right, :top, :bottom)
      def inspect
        # "[&Sizes le #{left} ri #{right} to #{top} bo #{bottom}]"
        "#{left} #{right} #{top} #{bottom}"
      end
      alias_method :to_s, :inspect
    end

    EDGE_DEFAULT = EdgeSizes.new 0.0, 0.0, 0.0, 0.0

    class DimensionsBox
      attr_reader :content, :padding, :border, :margin

      def initialize(content=nil, padding=EDGE_DEFAULT, border=EDGE_DEFAULT, margin=EDGE_DEFAULT)
        @content = content
        @padding = padding.is_a?(EdgeSizes) ? padding : EdgeSizes.new(*padding)
        @border = border.is_a?(EdgeSizes) ? border : EdgeSizes.new(*border)
        @margin = if margin.is_a?(EdgeSizes) 
            margin 
        else 
          EdgeSizes.new(*margin) 
        end
      end

      def self.from_properties(properties)
        dimensions = ['padding', 'border', 'margin']
        new nil, *(dimensions.map { |dimension| from_dimension(dimension, properties) })
      end

      def inspect
        "[&padding #{@padding} border #{@border} margin #{@margin}]"
      end

      private

      def self.from_dimension(dimension, properties)
        sizes = properties[dimension.to_sym]
        if sizes
          edge_sizes = [sizes[0..-3].to_f] * 4
        else
          edge_sizes = ['left', 'right', 'top', 'bottom'].map do |edge|
            properties.fetch(:"#{dimension}-#{edge}", '0.0px')[0..-3].to_f
          end
        end
        EdgeSizes.new *edge_sizes
      end
    end

    DEFAULT = DimensionsBox.new 

    class LayoutBox
      include Fugazi
      defaults dimensions: DEFAULT, children: [], properties: {}
      keywords tag_name: 'unknown'

      def inspect
        "[&#{self.class.name.split('::').last} #{tag_name} #{dimensions.inspect} #{properties.inspect}\n]" +
        children.map(&:inspect).join(' ')
      end
    end

    class BlockBox < LayoutBox
      def height
        (@children.map(&:height).max || 0)+
          dimensions.margin.top + dimensions.margin.bottom + 
          dimensions.padding.top + dimensions.padding.bottom + 
          dimensions.border.top + dimensions.border.bottom
      end

      def width
        # @children.reduce(0) { |w, child| w + child.width} + 
        dimensions.margin.left + dimensions.margin.right + 
        dimensions.padding.left + dimensions.padding.right +
        dimensions.border.left + dimensions.border.right
      end
    end

    class InlineBox < LayoutBox
      def height
        20
      end

      def width
        @children.reduce(0) { |w, child| w + child.width} + 
        dimensions.margin.left + dimensions.margin.right + 
        dimensions.padding.left + dimensions.padding.right +
        dimensions.border.left + dimensions.border.right
      end
    end

    class TextBox < LayoutBox
      attr_reader :text

      def initialize(text, properties)
        @text = text
        super DimensionsBox.new(nil, [0.0, 0.0, 0.0, 20.0]), [], properties
      end

      def height
        (@properties[:'font-size'][0..-3].to_f / 0.85).ceil
      end

      def width
        @text.length * 4
      end

      def inspect
        "[&TextBox #{@text} #{@dimensions} #{@properties}]"
      end
    end

    def self.build(style_tree)
      # build a layout recursively for a tree
      build_node style_tree.root
    end

    def self.build_node(style_node)
      if style_node.respond_to?(:tag_name) && style_node.tag_name == 'div'
        2
      end
      case style_node
      when ElementNode
        children = style_node.children.map(&method(:build_node)).compact
        p style_node.properties if style_node.tag_name == 'div'
        p 'l', style_node.tag_name
        # sleep 2
        display_property = style_node.properties.fetch(:display, 'inline')
        unless display_property == 'none'
          dimensions = DimensionsBox.from_properties style_node.properties
          const_get("#{display_property.capitalize}Box").new dimensions, children, style_node.properties, tag_name: style_node.tag_name
        end
      when TextNode
        text = style_node.content.gsub("\n", '').strip
        TextBox.new(text, style_node.properties) unless text.empty?
      end
    end
  end
end
