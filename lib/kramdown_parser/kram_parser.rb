
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

  end

  def parse
    super
    trigger_post_parse_hooks
  end

  private

  def trigger_post_parse_hooks
    self.class.trigger_post_parse_hooks self
  end

end
