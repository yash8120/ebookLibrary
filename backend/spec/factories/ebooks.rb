FactoryBot.define do
  factory :ebook do
    title { Faker::Book.title }
    author { Faker::Book.author }

    after(:build) do |ebook|
      ebook.file.attach(
        io: StringIO.new("%PDF-1.4 fake pdf content"),
        filename: "#{(ebook.title || "sample-book").parameterize}.pdf",
        content_type: "application/pdf"
      )
    end

    trait :with_cover do
      after(:build) do |ebook|
        ebook.cover.attach(
          io: StringIO.new("fake image bytes"),
          filename: "cover.png",
          content_type: "image/png"
        )
      end
    end

    trait :epub do
      after(:build) do |ebook|
        ebook.file.attach(
          io: StringIO.new("fake epub content"),
          filename: "#{(ebook.title || "sample-book").parameterize}.epub",
          content_type: "application/epub+zip"
        )
      end
    end

    trait :oversized do
      after(:build) do |ebook|
        ebook.file.attach(
          io: StringIO.new("x" * (Ebook::MAX_FILE_SIZE + 1)),
          filename: "huge.pdf",
          content_type: "application/pdf"
        )
      end
    end

    trait :unsupported_type do
      after(:build) do |ebook|
        ebook.file.attach(
          io: StringIO.new("not a book"),
          filename: "notes.txt",
          content_type: "text/plain"
        )
      end
    end
  end
end
