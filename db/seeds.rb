articles = [
  "Getting Started with MacronCMS",
  "Designing Content Structures with Rails 8",
  "The wp_loop Architecture: Clean Content Iteration",
  "Hydrating React and Three.js in Modern Server-Rendered Views",
  "Tailwind CSS Layouts for Dynamic Content",
  "High-Performance Publishing with Hotwire and Turbo",
  "Migrating Legacy Content into MacronCMS with AI Agents",
  "Building Accessible Digital Experiences with Rails",
  "Optimizing Content Queries and Asset Pipelines",
  "The Future of Developer-First Content Management Systems"
]

articles.each do |title|
  Macron::Cms::Article.find_or_create_by!(name: title.parameterize) do |article|
    article.title = title
  end
end

puts "Seeded #{Macron::Cms::Article.count} Macron::Cms articles."
