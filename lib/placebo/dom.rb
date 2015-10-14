module Placebo
  INHERITABLE = Set.new([
    :azimuth, :'border-collapse', :'border-spacing', :'caption-side', :color,
    :cursor, :direction, :elevation, :'empty-cells', :'font-family',
    :'font-size', :'font-style', :'font-variant', :'font-weight', :font,
    :'letter-spacing', :'line-height', :'list-style-image', :'list-style-position', :'list-style-type',
    :'list-style', :orphans, :'pitch-range', :pitch, :quotes,
    :richness, :'speak-header', :'speak-numeral', :'speak-punctuation', :speak,
    :'speak-rate', :stress, :'text-align', :'text-indent', :'text-transform',
    :'visibility', :'voice-family', :volume, :'white-space', :widows,
    :'word-spacing', :share])

  class PropertyMap
    attr_reader :values, :parent

    def initialize(hash, parent = nil)
      @values = hash
      @parent = parent
    end

    def [](property)
      if INHERITABLE.include? property
        current = self
        while current
          return current.values[property] if current.values.key? property
          current = current.parent
        end
      else
        @values[property]
      end
    end

    def []=(property, value)
      @values[property] = value
    end

    def fetch(property, other)
      value = self[property]
      value ? value : other
    end

    def inspect
      current = parent
      s = @values
      while current
        s = s.merge(current.values) { |property, ex, _| ex }
        current = current.parent
      end

      "[&PropertyMap#{s}]"
    end

    alias_method :to_s, :inspect
  end

  class Node
    def load(property)
      @properties[property]
    end
  end

  # ElementNode: a html element
  # example: div, span
  # @children: the children nodes
  class ElementNode < Node
    attr_reader :children, :tag_name, :attributes, :rules, :properties

    def initialize(oga_node, rule, children, properties)
      @tag_name = oga_node.name
      @attributes = Hash[oga_node.attributes.map { |a| [a.name, a.value] }]
      @children = children
      @rule = rule
      @properties = properties
    end

    def inspect
      pretty
    end

    def pretty(depth = 0)
      "#{'  ' * depth}[&ElementNode #{@tag_name} #{@properties} #{@attibutes}]\n" + children.map { |c| c.pretty(depth + 1) }.join("\n")
    end

    alias_method :to_s, :inspect
  end

  # TextNode: a text element
  # example: <span>lala</span>: lala
  # @content: the content
  class TextNode < Node
    attr_reader :content, :properties

    def initialize(content, properties)
      @content = content.gsub("\n", '')
      if @content[0] == ' '
        @content = ' ' + @content.lstrip
      end
      if @content[-1] == ' '
        @content = @content.rstrip + ' '
      end
      @properties = properties
    end

    def inspect
      pretty
    end

    def pretty(depth = 0)
      "#{'  ' * depth}[&TextNode \"#{@content.gsub("\n", '\n')}\" #{@properties}]"
    end

    alias_method :to_s, :inspect
  end

  # E: a dom tree
  # example: E.new(html)
  # @root: the root element
  class E
    attr_reader :root

    def initialize(root)
      @root = root
    end
  end
end
