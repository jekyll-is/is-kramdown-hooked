Gem::Specification.new do |s|
  s.name        = "is-kramdown-hooked"
  s.version     = "0.8.0"
  s.summary     = "Extensible Kramdown parser with inner hooks"
  s.description = "Flexible Jekyll plugin gem that extends Kramdown Markdown parser with customizable AST hooks, enabling enhanced Markdown processing and seamless integration within Jekyll sites."
  s.authors     = ["Ivan Shikhalev"]
  s.email       = ["shikhalev@gmail.com"]
  s.files       = Dir["lib/**/*", "README.md", "LICENSE"]
  s.homepage    = "https://github.com/jekyll-is/is-kramdown-hooked"
  s.license     = "GPL-3.0-or-later"

  s.required_ruby_version = "~> 3.4"

  s.add_dependency "kramdown", "~> 2.5"

  s.add_development_dependency "rspec", "~> 3.13"
  s.add_development_dependency "rake", "~> 13.3"
  s.add_development_dependency "simplecov", "~> 0.22.0"
end
