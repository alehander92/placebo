module Placebo
  # StyleTree: a styled dom tree
  # combines dom and rules
  # @dom: a pure dom
  class StyleTree
    attr_reader :root

    BUILTIN_RULES = Placebo.parse_css <<-CSS
      html, body { display: block; font-size: 16px; }
      head, script { display: none; }
      div, section, header, footer { display: block; }
    CSS

    def initialize(dom, rules)
      @dom = dom
      @rules = BUILTIN_RULES + rules
      @root = build_style @dom.children[0], nil
    end

    def inspect
      pretty
    end

    def pretty(depth = 0)
      nl = "\n"
      ('  ' * depth) + "[&StyleTree\n  #{@dom}\n  #{@root.inspect}\n  #{@rules.map(&:inspect).join(nl)}]"
    end

  alias_method :to_s, :inspect
    private

    def build_style(node, parent)
      case node
      when Oga::XML::Element
        properties = style_properties(rules_for(node), parent)
        children = node.children.map { |child| build_style child, properties }
        ElementNode.new node, @rules.find { |rule| match_selector node, rule.selector }, children, properties
      when Oga::XML::Text
        TextNode.new node.text, parent
      end
    end

    def match_selector(node, selector)
      if !selector.tag_names.empty? &&
        selector.tag_names.none? { |name| node.name == name }
        false
      elsif !selector.ids.empty? &&
        selector.ids.none? { |rule_id| id(node) == rule_id }
        false
      elsif !selector.classes.empty? && (selector.classes & classes(node)).empty?
        false
      else
        true
      end
    end

    def rules_for(node) # rules_for('<img>x</img>')
      @rules.select do |rule|
        match_selector node, rule.selector 
      end.reverse
    end

    def style_properties(a, parent)
      a0 = PropertyMap.new({}, parent) 
      a.each do |rule|
        rule.properties.each do |p|
          a0[p[:name].to_sym] = p[:value]
        end
      end
      a0
    end

    def id(node)
      i = node.attributes.find { |attr| attr.name == 'id' }
      i ? i.value : nil
    end

    def classes(node)
      node.attributes.
           select { |attr| attr.name == 'class' }.
           map(&:value)
    end
  end
end
