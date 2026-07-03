require "rails_helper"

RSpec.describe "Api::Ebooks", type: :request do
  describe "GET /api/ebooks" do
    it "returns all ebooks, most recent first" do
      older = create(:ebook, created_at: 2.days.ago)
      newer = create(:ebook, created_at: 1.hour.ago)

      get "/api/ebooks"

      expect(response).to have_http_status(:ok)
      ids = JSON.parse(response.body).map { |e| e["id"] }
      expect(ids).to eq([newer.id, older.id])
    end

    it "returns an empty array when the library has no ebooks" do
      get "/api/ebooks"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)).to eq([])
    end
  end

  describe "GET /api/ebooks/:id" do
    it "returns the ebook details" do
      ebook = create(:ebook, title: "Deep Work")

      get "/api/ebooks/#{ebook.id}"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["title"]).to eq("Deep Work")
    end

    it "returns 404 for a missing ebook" do
      get "/api/ebooks/999999"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "POST /api/ebooks" do
    it "creates an ebook when given a valid PDF" do
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/sample.pdf"), "application/pdf")

      post "/api/ebooks", params: { title: "New Book", author: "A. Author", file: file }

      expect(response).to have_http_status(:created)
      body = JSON.parse(response.body)
      expect(body["title"]).to eq("New Book")
      expect(Ebook.count).to eq(1)
    end

    it "rejects an upload with no file" do
      post "/api/ebooks", params: { title: "No File" }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(JSON.parse(response.body)["errors"]).to include(match(/file/i))
    end

    it "rejects an unsupported file type" do
      file = fixture_file_upload(Rails.root.join("spec/fixtures/files/notes.txt"), "text/plain")

      post "/api/ebooks", params: { title: "Bad Type", file: file }

      expect(response).to have_http_status(:unprocessable_entity)
    end
  end

  describe "GET /api/ebooks/search" do
    it "filters ebooks by the query" do
      create(:ebook, title: "Ruby Basics")
      create(:ebook, title: "Advanced Flutter")

      get "/api/ebooks/search", params: { q: "ruby" }

      expect(response).to have_http_status(:ok)
      titles = JSON.parse(response.body).map { |e| e["title"] }
      expect(titles).to eq(["Ruby Basics"])
    end

    it "returns everything when q is missing" do
      create_list(:ebook, 2)

      get "/api/ebooks/search"

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body).size).to eq(2)
    end
  end

  describe "GET /api/ebooks/:id/download" do
    it "streams the file with the correct content type" do
      ebook = create(:ebook)

      get "/api/ebooks/#{ebook.id}/download"

      expect(response).to have_http_status(:ok)
      expect(response.content_type).to eq("application/pdf")
    end

    it "returns 404 when the ebook does not exist" do
      get "/api/ebooks/999999/download"

      expect(response).to have_http_status(:not_found)
    end
  end

  describe "DELETE /api/ebooks/:id" do
    it "deletes the ebook and its attached file" do
      ebook = create(:ebook)

      delete "/api/ebooks/#{ebook.id}"

      expect(response).to have_http_status(:no_content)
      expect(Ebook.exists?(ebook.id)).to be(false)
    end

    it "returns 404 when deleting a non-existent ebook" do
      delete "/api/ebooks/999999"

      expect(response).to have_http_status(:not_found)
    end
  end
end
