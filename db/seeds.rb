articles = [
  {
    title: "Getting Started with MacronCMS",
    meta_title: "Getting Started with MacronCMS | Rails 8 Content Engine",
    meta_description: "Discover how to install, configure, and build interactive content architectures with MacronCMS on Rails 8."
  },
  {
    title: "Designing Content Structures with Rails 8",
    meta_title: "Designing Content Structures with Rails 8 | MacronCMS Guide",
    meta_description: "A comprehensive guide to modeling content hierarchies, flexible attributes, and schema migrations in Rails 8."
  },
  {
    title: "The wp_loop Architecture: Clean Content Iteration",
    meta_title: "Understanding The wp_loop Architecture in Rails | MacronCMS",
    meta_description: "Explore the wp_loop-inspired data pattern for declarative, clean, and decoupled content iteration in Ruby on Rails."
  },
  {
    title: "Hydrating React and Three.js in Modern Server-Rendered Views",
    meta_title: "Hydrating React and Three.js in Rails Views | MacronCMS",
    meta_description: "Seamlessly integrate interactive React components and Three.js 3D scenes into server-rendered Rails templates."
  },
  {
    title: "Tailwind CSS Layouts for Dynamic Content",
    meta_title: "Tailwind CSS Layouts for Dynamic Content Publishing | MacronCMS",
    meta_description: "Master modern utility-first typography, fluid layouts, and responsive components for publishing with Tailwind CSS."
  },
  {
    title: "High-Performance Publishing with Hotwire and Turbo",
    meta_title: "High-Performance Publishing with Hotwire & Turbo | MacronCMS",
    meta_description: "Boost site speed and user experience by leveraging Turbo Drive, Turbo Frames, and Turbo Streams in your CMS."
  },
  {
    title: "Migrating Legacy Content into MacronCMS with AI Agents",
    meta_title: "Migrating Legacy Content with AI Agents | MacronCMS",
    meta_description: "How to use autonomous AI agents to transform, clean, and import unstructured legacy datasets into MacronCMS."
  },
  {
    title: "Building Accessible Digital Experiences with Rails",
    meta_title: "Building Accessible Web Experiences with Rails | MacronCMS",
    meta_description: "Best practices and strategies for building WCAG-compliant, accessible content layouts and UI controls in Rails."
  },
  {
    title: "Optimizing Content Queries and Asset Pipelines",
    meta_title: "Optimizing Content Queries and Asset Pipelines | MacronCMS",
    meta_description: "Techniques for eliminating N+1 queries, optimizing cache keys, and streamlining modern asset delivery pipelines."
  },
  {
    title: "The Future of Developer-First Content Management Systems",
    meta_title: "The Future of Developer-First CMS Platforms | MacronCMS",
    meta_description: "An editorial on modularity, headless workflows, AI integration, and the evolution of developer-first CMS platforms."
  }
]

articles.each_with_index do |data, index|
  article = Macron::Cms::Article.find_or_initialize_by(slug: data[:title].parameterize)
  article.title = data[:title]
  article.meta_title = data[:meta_title]
  article.meta_description = data[:meta_description]
  article.published_at ||= (Time.current - (articles.size - index).days)
  article.save!
end

puts "Seeded #{Macron::Cms::Article.count} Macron::Cms articles."

user_class_name = Macron::Cms.configuration.user_class
user_class = user_class_name.safe_constantize

if user_class
  admin_flag = Macron::Cms.configuration.admin_flag

  admin_user = user_class.find_or_initialize_by(email: "admin@example.com")
  admin_user.password = "password" if admin_user.respond_to?(:password=)
  admin_user.password_confirmation = "password" if admin_user.respond_to?(:password_confirmation=)
  admin_user.public_send(:"#{admin_flag}=", true) if admin_user.respond_to?(:"#{admin_flag}=")
  admin_user.save!

  regular_user = user_class.find_or_initialize_by(email: "user@example.com")
  regular_user.password = "password" if regular_user.respond_to?(:password=)
  regular_user.password_confirmation = "password" if regular_user.respond_to?(:password_confirmation=)
  regular_user.public_send(:"#{admin_flag}=", false) if regular_user.respond_to?(:"#{admin_flag}=")
  regular_user.save!

  puts "Seeded test users (admin: admin@example.com, regular: user@example.com)."
end
