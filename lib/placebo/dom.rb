module Placebo
  class Node
  end

  # ElementNode: a html element
  # example: div, span
  # @children: the children nodes
  class ElementNode < Node
    attr_reader :children, :tag_name, :attrs

    def initialize(tag_name, attrs = {}, children = [])
      @tag_name = tag_name
      @attrs = attrs
      @children = children
    end
  end

  # TextNode: a text element
  # example: <span>lala</span>: lala
  # @content: the content
  class TextNode < Node
    attr_reader :content

    def initialize(content)
      @content = content
    end
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
