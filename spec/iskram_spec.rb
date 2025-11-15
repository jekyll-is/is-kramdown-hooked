require_relative 'spec_helper'

RSpec.describe Kramdown::Parser::ISKram do

  it 'hook triggered' do

    flag = nil

    Kramdown::Parser::ISKram.register_post_parse_hook do |parser|
      flag = true
    end

    source = "# Header\n\nParagraph"
    document = Kramdown::Document::new source, input: 'ISKram'

    expect(flag).to eq(true)

  end

end
