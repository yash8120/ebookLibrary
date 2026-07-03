# Seeds a few sample ebooks so the Flutter app has something to show
# on first run. Requires small sample PDFs in db/seed_files/.
#
# Run with: bin/rails db:seed

seed_dir = Rails.root.join("db", "seed_files")

samples = [
  { title: "The Old Man and the Library", author: "A. Writer", file: "sample1.pdf" },
  { title: "Notes on Ruby", author: "R. Dev", file: "sample2.pdf" },
  { title: "Flutter for Beginners", author: "F. Coder", file: "sample3.pdf" }
]

samples.each do |sample|
  path = seed_dir.join(sample[:file])
  next unless File.exist?(path)

  ebook = Ebook.find_or_initialize_by(title: sample[:title])
  ebook.author = sample[:author]
  ebook.file.attach(io: File.open(path), filename: sample[:file], content_type: "application/pdf")
  ebook.save!
end

puts "Seeded #{Ebook.count} ebooks."
