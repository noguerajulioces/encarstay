namespace :images do
  desc "Generate the named property-photo variants that predate preprocessing"
  task preprocess: :environment do
    variants = %i[ card_small card preview gallery ]
    photos = Photo.joins(image_attachment: :blob)
    total = photos.count

    photos.find_each.with_index(1) do |photo, index|
      variants.each { |variant| photo.image.variant(variant).processed }
      puts "Processed #{index}/#{total}: #{photo.image.filename}"
    end
  end
end
