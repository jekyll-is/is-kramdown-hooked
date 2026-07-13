
require 'kramdown'

class Kramdown::Parser::ISKram < Kramdown::Parser::Kramdown

  class << self

    def register_post_parse_hook &hook
      @hooks ||= []
      @hooks << hook
    end

    def trigger_post_parse_hooks parser
      @hooks.each do |hook|
        hook.call parser
      end
    end

    def register_ast_element_hook *elements, &hook
      @element_hooks ||= []
      @element_hooks << { elements: elements, hook: hook }
    end

    def trigger_ast_elements_hooks parser
      return if @element_hooks.nil? || @element_hooks.empty?
      traverse = lambda do |elem|
        elem.children.each_with_index do |child, index|
          handled = false
          @element_hooks.each do |hook|
            if hook[:elements].include?(child.type)
              hooked = hook[:hook].call elem, child, index
              handled ||= hooked
            end
          end
          traverse.call child unless handled
        end
      end
      traverse.call parser.root
    end

  end

  def parse
    super
    trigger_post_parse_hooks
    trigger_ast_elements_hooks
  end

  private

  def trigger_post_parse_hooks
    self.class.trigger_post_parse_hooks self
  end

  def trigger_ast_elements_hooks
    self.class.trigger_ast_elements_hooks self
  end

end
