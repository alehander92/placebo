module Placebo
  def self.parse_html(source, relative='.')
    html = Oga.parse_html source
    css = []
    html.children = html.children.select { |child| !child.is_a?(Oga::XML::Text) }
    if html.children[0].name == 'html'
      html.children[0].children = html.children[0].children.select { |child| !child.is_a?(Oga::XML::Text) }
      links = html.children[0].children[0].children.select { |child| child.respond_to?(:name) && child.name == 'link' }
      css = links.reduce([]) do |z, link|
        a = link.attributes.find { |a| a.name == 'href' }
        type = link.attributes.find { |a| a.name = 'type' }
        p 'ye', type
        if type.value == 'stylesheet'
          p relative + '/' + a.value
          z + parse_css(read_source(relative + '/' + a.value))
        else
          z
        end
      end
    end
    [html, css]
  end
end
