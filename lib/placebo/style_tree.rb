module Placebo
  # StyleTree: a styled dom tree
  # combines dom and rules
  # @dom: a pure dom
  class StyleTree
    def initialize(dom, rules)
      @dom = dom
      @rules = rules
      @root = build_style @dom.root
    end

    private

    def build_style(node)
      node
    end
  end
end
