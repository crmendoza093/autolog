# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Clean all data
puts "🗑️  Limpiando base de datos..."
Shop.destroy_all

# Create demo shop
puts "🏪 Creando taller demo..."
shop = Shop.create!(
  name: "demo",
  pin: "1234"
)

puts "✅ Seed completado!"
puts "   Shop: #{shop.name}"
puts "   PIN: #{shop.pin}"
puts ""
puts "Para acceder: http://localhost:3000/login"
puts "   Usuario: Taller Demo"
puts "   PIN: 1234"
