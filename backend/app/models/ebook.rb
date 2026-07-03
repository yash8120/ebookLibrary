# == Ebook
#
# Represents a single ebook in the user's digital library.
#
# Files are stored using Active Storage (local disk by default, see
# config/storage.yml). Two attachments are supported:
#   - `file`  : the actual ebook (PDF required, EPUB optional/preferred)
#   - `cover` : an optional cover image shown on the bookshelf
#
class Ebook < ApplicationRecord
  ALLOWED_FILE_TYPES = %w[application/pdf application/epub+zip].freeze
  ALLOWED_COVER_TYPES = %w[image/png image/jpeg image/jpg image/webp].freeze
  MAX_FILE_SIZE = 100.megabytes

  has_one_attached :file
  has_one_attached :cover

  before_validation :set_metadata_from_file, on: :create

  validates :title, presence: true
  validates :file, presence: { message: "must be attached" }

  validate :file_type_is_supported
  validate :file_size_within_limit

  scope :recent, -> { order(created_at: :desc) }

  # Simple case-insensitive search across title, author, and the
  # original uploaded filename.
  def self.search(query)
    return all if query.blank?

    like = "%#{sanitize_sql_like(query)}%"
    joins(file_attachment: :blob)
      .where(
        "ebooks.title LIKE :q OR ebooks.author LIKE :q OR active_storage_blobs.filename LIKE :q",
        q: like
      )
      .distinct
  end

  def file_type
    file.attached? ? file.content_type : nil
  end

  def file_size
    file.attached? ? file.byte_size : nil
  end

  def original_filename
    file.attached? ? file.filename.to_s : nil
  end

  private

  def set_metadata_from_file
    return unless file.attached?

    self.title = title.presence || File.basename(original_filename.to_s, ".*")
  end

  def file_type_is_supported
    return unless file.attached?

    unless ALLOWED_FILE_TYPES.include?(file.content_type)
      errors.add(:file, "must be a PDF or EPUB (got #{file.content_type})")
    end
  end

  def file_size_within_limit
    return unless file.attached?

    if file.byte_size > MAX_FILE_SIZE
      errors.add(:file, "is too large (max #{MAX_FILE_SIZE / 1.megabyte}MB)")
    end
  end
end
