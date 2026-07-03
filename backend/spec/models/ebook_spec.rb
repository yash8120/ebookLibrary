require "rails_helper"

RSpec.describe Ebook, type: :model do
  describe "validations" do
    it "is valid with a title and an attached PDF" do
      ebook = build(:ebook)
      expect(ebook).to be_valid
    end

    it "is invalid without a file attached" do
      ebook = build(:ebook)
      ebook.file.detach
      expect(ebook).not_to be_valid
      expect(ebook.errors[:file]).to include("must be attached")
    end

    it "rejects unsupported file types" do
      ebook = build(:ebook, :unsupported_type)
      expect(ebook).not_to be_valid
      expect(ebook.errors[:file].join).to match(/PDF or EPUB/)
    end

    it "accepts EPUB files" do
      ebook = build(:ebook, :epub)
      expect(ebook).to be_valid
    end

    it "rejects files larger than the configured limit" do
      ebook = build(:ebook, :oversized)
      expect(ebook).not_to be_valid
      expect(ebook.errors[:file].join).to match(/too large/)
    end

    it "defaults the title to the filename when title is blank" do
      ebook = build(:ebook, title: nil)
      ebook.valid?
      expect(ebook.title).to be_present
    end
  end

  describe ".search" do
    it "finds ebooks by title" do
      match = create(:ebook, title: "Ruby Under a Microscope")
      create(:ebook, title: "Cooking with Flutter")

      expect(Ebook.search("microscope")).to contain_exactly(match)
    end

    it "finds ebooks by author" do
      match = create(:ebook, author: "Jane Doe")
      create(:ebook, author: "John Smith")

      expect(Ebook.search("jane")).to contain_exactly(match)
    end

    it "returns all ebooks when the query is blank" do
      create_list(:ebook, 3)
      expect(Ebook.search(nil).count).to eq(3)
    end

    it "returns none when nothing matches" do
      create(:ebook, title: "Something")
      expect(Ebook.search("nonexistent-keyword")).to be_empty
    end
  end
end
