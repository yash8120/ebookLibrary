module Api
  class EbooksController < ApplicationController
    before_action :set_ebook, only: [:show, :destroy, :download]

    # GET /api/ebooks
    def index
      ebooks = Ebook.recent
      render json: ebooks.map { |e| ebook_json(e) }, status: :ok
    end

    # GET /api/ebooks/search?q=keyword
    def search
      query = params[:q]
      ebooks = Ebook.search(query).recent
      render json: ebooks.map { |e| ebook_json(e) }, status: :ok
    end

    # GET /api/ebooks/:id
    def show
      render json: ebook_json(@ebook, detailed: true), status: :ok
    end

    # POST /api/ebooks
    # multipart/form-data params: title, author, file, cover (optional)
    def create
      ebook = Ebook.new(ebook_params)

      if ebook.save
        render json: ebook_json(ebook, detailed: true), status: :created
      else
        render json: { errors: ebook.errors.full_messages }, status: :unprocessable_entity
      end
    end

    # DELETE /api/ebooks/:id
    def destroy
      @ebook.destroy
      head :no_content
    rescue StandardError => e
      render json: { errors: [e.message] }, status: :unprocessable_entity
    end

    # GET /api/ebooks/:id/download
    def download
      unless @ebook.file.attached?
        return render json: { errors: ["File not found"] }, status: :not_found
      end

      send_data @ebook.file.download,
                filename: @ebook.original_filename,
                type: @ebook.file_type,
                disposition: "attachment"
    end

    private

    def set_ebook
      @ebook = Ebook.find(params[:id])
    rescue ActiveRecord::RecordNotFound
      render json: { errors: ["Ebook not found"] }, status: :not_found
    end

    def ebook_params
      params.permit(:title, :author, :file, :cover)
    end

    def ebook_json(ebook, detailed: false)
      json = {
        id: ebook.id,
        title: ebook.title,
        author: ebook.author,
        file_type: ebook.file_type,
        file_size: ebook.file_size,
        uploaded_at: ebook.created_at,
        cover_url: cover_url_for(ebook),
        download_url: ebook.file.attached? ? download_api_ebook_url(ebook) : nil
      }
      json[:original_filename] = ebook.original_filename if detailed
      json
    end

    def cover_url_for(ebook)
      return nil unless ebook.cover.attached?

      Rails.application.routes.url_helpers.rails_blob_url(ebook.cover, only_path: false)
    end
  end
end
