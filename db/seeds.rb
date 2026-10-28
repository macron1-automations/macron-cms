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
