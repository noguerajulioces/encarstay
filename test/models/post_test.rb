require "test_helper"

class PostTest < ActiveSupport::TestCase
  test "generates a slug from the Spanish title on create" do
    post = Post.create!(title_es: "Qué hacer en verano")
    assert_equal "que-hacer-en-verano", post.slug
  end

  test "sets published_at when published" do
    post = Post.create!(title_es: "Publicado", published: true)
    assert post.published_at.present?
  end

  test "does not set published_at for a draft" do
    post = Post.create!(title_es: "Borrador nuevo", published: false)
    assert_nil post.published_at
  end

  test "requires a Spanish title" do
    post = Post.new(title_es: "")
    assert_not post.valid?
    assert_includes post.errors.attribute_names, :title_es
  end

  test "slug must be unique" do
    Post.create!(title_es: "Repetido")
    dup = Post.new(title_es: "Repetido")
    assert_not dup.valid?
    assert_includes dup.errors.attribute_names, :slug
  end

  test "published scope excludes drafts" do
    assert_includes Post.published, posts(:verano)
    assert_not_includes Post.published, posts(:borrador)
  end

  test "body returns the current-locale rich text and falls back to Spanish" do
    post = Post.create!(title_es: "Con cuerpo")
    post.body_es = "<div>Contenido español</div>"
    post.body_en = "<div>English content</div>"
    post.save!

    I18n.with_locale(:es) { assert_equal "Contenido español", post.body.to_plain_text.strip }
    I18n.with_locale(:en) { assert_equal "English content", post.body.to_plain_text.strip }
    # Portuguese body is empty, so it falls back to Spanish.
    I18n.with_locale(:pt) { assert_equal "Contenido español", post.body.to_plain_text.strip }
  end

  test "translatable title falls back to Spanish" do
    post = Post.create!(title_es: "Solo español")
    I18n.with_locale(:pt) { assert_equal "Solo español", post.title }
  end
end
