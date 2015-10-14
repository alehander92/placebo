module Placebo
  class Rule < Struct.new(:selector, :properties)
    def self.parse(rule)
      new Selector.parse(rule[:selector]),
          parse_children(rule[:children])
    end

    def self.parse_children(children)
      children.select do |child|
        child[:node] == :property 
      end.map do |property|
        Property.new property[:name], property[:value][0] == "'" ? property[:value][1..-2] : property[:value]
      end
    end

    def inspect
      pretty
    end

    def pretty(depth = 0)
      "[&Rule #{'  ' * depth}[&Rule #{selector.inspect}]\n  #{properties.map { |p| p.pretty(depth + 1) }.join(%q(\n))}"
    end

    alias_method :to_s, :inspect
  end

  class Selector < Struct.new(:tag_names, :ids, :classes)
    def self.parse(selector)
      ids, classes, tag_names = [], [], []
      delim = false
      selector[:tokens].each do |token|
        if token[:node] == :ident && delim
          classes << token[:value]
        elsif token[:node] == :ident && token[:value] != ''
          tag_names << token[:value]
        elsif token[:node] == :hash
          ids << token[:value]
        end
        delim = token[:node] == :delim
      end
      new tag_names, ids, classes
    end

    def inspect
      pretty
    end

    def pretty(depth = 0)
      ('  ' * depth) + "[&Selector #{tag_names} #{ids} #{classes}]"
    end

    alias_method :to_s, :inspect  
  end

  class Property < Struct.new(:name, :value)

    def inspect
      pretty
    end

    def pretty(depth = 0)
      ('  ' * depth) + "[&Property #{name}: #{value}]"
    end

    alias_method :to_s, :inspect
  end
  
  def self.parse_css(source)
    css_tree = Crass.parse source
    rules = css_tree.select { |n| n[:node] == :style_rule }.map { |r| Rule.parse r }
    rules.sort { |a, b| specificality(b) <=> specificality(a) }
  end

  def self.specificality(rule)
    [rule.selector.ids.length, rule.selector.classes.length, rule.selector.tag_names.length]
  end
end
