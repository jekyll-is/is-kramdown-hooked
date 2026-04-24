# spec/iskram_spec.rb
require_relative "spec_helper"

RSpec.describe Kramdown::Parser::ISKram do

  # Очищаем хуки перед каждым тестом, чтобы избежать взаимного влияния
  before(:each) do
    # Сбрасываем накопленные хуки между тестами
    described_class.instance_variable_set(:@hooks, [])
  end

  after(:all) do
    # Финальная очистка после всего набора тестов
    described_class.instance_variable_set(:@hooks, [])
  end

  # ==========================================================================
  # Базовые тесты на регистрацию и срабатывание
  # ==========================================================================

  describe "hook registration" do
    it "triggers a registered hook" do
      flag = false

      described_class.register_post_parse_hook do |parser|
        flag = true
      end

      Kramdown::Document.new("# Test", input: "ISKram")

      expect(flag).to be true
    end

    it "triggers multiple registered hooks" do
      counter = 0

      3.times do
        described_class.register_post_parse_hook do |parser|
          counter += 1
        end
      end

      Kramdown::Document.new("# Test", input: "ISKram")

      expect(counter).to eq(3)
    end

    it "executes hooks in registration order" do
      order = []

      described_class.register_post_parse_hook do |parser|
        order << :first
      end

      described_class.register_post_parse_hook do |parser|
        order << :second
      end

      described_class.register_post_parse_hook do |parser|
        order << :third
      end

      Kramdown::Document.new("# Test", input: "ISKram")

      expect(order).to eq(%i[first second third])
    end
  end

  # ==========================================================================
  # Тесты на передачу и содержимое parser
  # ==========================================================================

  describe "parser object passed to hook" do
    it "passes a Kramdown::Parser::ISKram instance" do
      received_parser = nil

      described_class.register_post_parse_hook do |parser|
        received_parser = parser
      end

      Kramdown::Document.new("# Test", input: "ISKram")

      expect(received_parser).to be_a(Kramdown::Parser::ISKram)
    end

    it "passes a parser with accessible root AST" do
      root = nil

      described_class.register_post_parse_hook do |parser|
        root = parser.root
      end

      Kramdown::Document.new("# Header", input: "ISKram")

      expect(root).to be_a(Kramdown::Element)
      expect(root.type).to eq(:root)
      expect(root.children).not_to be_empty
    end

    it "passes a parser that has already parsed content" do
      header_text = nil

      described_class.register_post_parse_hook do |parser|
        # Ищем заголовок в AST
        header = parser.root.children.find { |child| child.type == :header }
        header_text = header.options[:raw_text] if header
      end

      Kramdown::Document.new("# My Header", input: "ISKram")

      expect(header_text).to eq("My Header")
    end
  end

  # ==========================================================================
  # Тесты на модификацию AST
  # ==========================================================================

  describe "AST modification" do
    it "allows modifying AST in hook" do
      described_class.register_post_parse_hook do |parser|
        # Добавляем класс ко всем заголовкам
        parser.root.children.each do |child|
          if child.type == :header
            child.attr["class"] = "modified"
          end
        end
      end

      doc = Kramdown::Document.new("# Test", input: "ISKram")
      html = doc.to_html

      expect(html).to include('class="modified"')
    end

    it "allows adding new elements to AST" do
      described_class.register_post_parse_hook do |parser|
        # Создаём параграф правильно — с текстовым дочерним элементом
        new_para = Kramdown::Element.new(:p)
        new_para.children << Kramdown::Element.new(:text, "Added by hook")
        parser.root.children << new_para
      end

      doc = Kramdown::Document.new("# Test", input: "ISKram")
      html = doc.to_html

      expect(html).to include("Added by hook")
    end

    it "allows removing elements from AST" do
      described_class.register_post_parse_hook do |parser|
        # Удаляем все параграфы
        parser.root.children.reject! { |child| child.type == :p }
      end

      doc = Kramdown::Document.new("# Test\n\nSome paragraph", input: "ISKram")
      html = doc.to_html

      expect(html).not_to include("Some paragraph")
      expect(html).to include("Test") # заголовок остался
    end
  end

  # ==========================================================================
  # Тесты на изоляцию и повторное использование
  # ==========================================================================

  describe "hook isolation and reuse" do
    it "triggers hooks on every parse call" do
      counter = 0

      described_class.register_post_parse_hook do |parser|
        counter += 1
      end

      Kramdown::Document.new("# First", input: "ISKram")
      Kramdown::Document.new("# Second", input: "ISKram")
      Kramdown::Document.new("# Third", input: "ISKram")

      expect(counter).to eq(3)
    end

    it "does not share hooks between different parser classes" do
      # Создаём подкласс
      subclass = Class.new(Kramdown::Parser::ISKram)
      subclass.instance_variable_set(:@hooks, [])

      parent_called = false
      child_called = false

      described_class.register_post_parse_hook do |parser|
        parent_called = true
      end

      subclass.register_post_parse_hook do |parser|
        child_called = true
      end

      Kramdown::Document.new("# Test", input: "ISKram")

      expect(parent_called).to be true
      expect(child_called).to be false
    end
  end

  # ==========================================================================
  # Тесты на наследование от Kramdown::Parser::Kramdown
  # ==========================================================================

  describe "inheritance" do
    it "inherits from Kramdown::Parser::Kramdown" do
      expect(described_class).to be < Kramdown::Parser::Kramdown
    end

    it "correctly parses standard Kramdown syntax" do
      doc = Kramdown::Document.new(<<~MD, input: "ISKram")
        # Header

        Paragraph with **bold** and *italic*.

        > Blockquote
      MD

      html = doc.to_html

      expect(html).to include('<h1 id="header">Header</h1>')
      expect(html).to include("<strong>bold</strong>")
      expect(html).to include("<em>italic</em>")
      expect(html).to include("<blockquote>")
      expect(html).to include("</blockquote>")
    end
  end

  # ==========================================================================
  # Тесты на обработку ошибок в хуках
  # ==========================================================================

  describe "error handling" do
    it "raises error from hook without suppression" do
      described_class.register_post_parse_hook do |parser|
        raise "Hook error"
      end

      expect {
        Kramdown::Document.new("# Test", input: "ISKram")
      }.to raise_error("Hook error")
    end

    it "stops execution on first error" do
      order = []

      described_class.register_post_parse_hook do |parser|
        order << :first
      end

      described_class.register_post_parse_hook do |parser|
        raise "Second hook error"
      end

      described_class.register_post_parse_hook do |parser|
        order << :third
      end

      expect {
        Kramdown::Document.new("# Test", input: "ISKram")
      }.to raise_error("Second hook error")

      expect(order).to eq([:first])
    end
  end

  # ==========================================================================
  # Тесты на пустые и граничные случаи
  # ==========================================================================

  describe "edge cases" do
    it "works with empty document" do
      triggered = false

      described_class.register_post_parse_hook do |parser|
        triggered = true
        # Пустой документ содержит :blank элементы, но не content-элементы
        content_elements = parser.root.children.reject { |c| c.type == :blank }
        expect(content_elements).to be_empty
      end

      Kramdown::Document.new("", input: "ISKram")

      expect(triggered).to be true
    end

    it "works with document containing only whitespace" do
      triggered = false

      described_class.register_post_parse_hook do |parser|
        triggered = true
      end

      Kramdown::Document.new("   \n\n  ", input: "ISKram")

      expect(triggered).to be true
    end

    it "works without any registered hooks" do
      # Хуки очищены в before(:each)
      doc = Kramdown::Document.new("# Test", input: "ISKram")
      html = doc.to_html

      expect(html).to include('<h1 id="test">Test</h1>')
    end

    it "allows hook to access parser options" do
      option_value = nil

      described_class.register_post_parse_hook do |parser|
        option_value = parser.options[:input]
      end

      Kramdown::Document.new("# Test", input: "ISKram")

      expect(option_value).to eq("ISKram")
    end
  end

  # ==========================================================================
  # Интеграционные тесты: типичные сценарии использования
  # ==========================================================================

  describe "integration scenarios" do
    it "can implement automatic table of contents" do
      headers = []

      described_class.register_post_parse_hook do |parser|
        # Рекурсивный сбор заголовков из всего дерева
        traverse = ->(element) do
          element.children.each do |child|
            if child.type == :header
              headers << {
                level: child.options[:level],
                text: child.options[:raw_text],
              }
            end
            traverse.call(child)
          end
        end
        traverse.call(parser.root)
      end

      Kramdown::Document.new(<<~MD, input: "ISKram")
        # First

        ## Second

        ### Third
      MD

      expect(headers).to eq([
        { level: 1, text: "First" },
        { level: 2, text: "Second" },
        { level: 3, text: "Third" },
      ])
    end

    it "can implement image processing marker" do
      images = []

      described_class.register_post_parse_hook do |parser|
        parser.root.children.each do |child|
          next unless child.type == :p

          child.children.each do |inline|
            if inline.type == :img
              images << {
                src: inline.attr["src"],
                alt: inline.attr["alt"],
              }
            end
          end
        end
      end

      Kramdown::Document.new("![Alt text](path/to/image.jpg)", input: "ISKram")

      expect(images).to eq([
        { src: "path/to/image.jpg", alt: "Alt text" },
      ])
    end

    it "can modify image attributes via hook" do
      described_class.register_post_parse_hook do |parser|
        parser.root.children.each do |child|
          next unless child.type == :p

          child.children.each do |inline|
            if inline.type == :img
              inline.attr["class"] = "responsive"
              inline.attr["loading"] = "lazy"
            end
          end
        end
      end

      doc = Kramdown::Document.new("![Alt](image.jpg)", input: "ISKram")
      html = doc.to_html

      expect(html).to include('class="responsive"')
      expect(html).to include('loading="lazy"')
    end

    it "handles IAL after inline image" do
      ial_captured = nil
      img_attrs = nil

      described_class.register_post_parse_hook do |parser|
        parser.root.children.each do |child|
          next unless child.type == :p

          child.children.each do |inline|
            if inline.type == :img
              img_attrs = inline.attr.dup
            end
            if inline.type == :ial
              ial_captured = inline.attr.dup
            end
          end
        end
      end

      Kramdown::Document.new('![Alt text](path/to/image.jpg){: .test-class #myid width="800" }', input: "ISKram")

      puts "IMG attrs: #{img_attrs.inspect}"
      puts "IAL captured: #{ial_captured.inspect}"
    end
  end
end
